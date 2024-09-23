locals {
  example = {
    standard_load_balancer = {
      name = "example-standard-lb"
      sku  = "Standard"
    }
    gateway_load_balancer = {
      name = "example-gateway-lb"
      sku  = "Gateway"
    }
    application_gateway = {
      name = "example-application-gateway"
    }
    network_interface = {
      name = "example-nic"
    }
  }
  load_balancers = {
    for key, value in local.example :
    key => value if strcontains(key, "load_balancer")
  }
}

terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "this" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "example"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_network_security_group" "this" {
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_public_ip" "this" {
  for_each = local.example

  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${each.key}-pip"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_application_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = local.example["application_gateway"].name
  resource_group_name = azurerm_resource_group.this.name

  backend_address_pool {
    name = "${local.example["application_gateway"].name}-backend-pool"
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "${local.example["application_gateway"].name}-backend-http"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }
  frontend_ip_configuration {
    name                 = "${local.example["application_gateway"].name}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.this["application_gateway"].id
  }
  frontend_port {
    name = "${local.example["application_gateway"].name}-frontend-port"
    port = 80
  }
  gateway_ip_configuration {
    name      = "example"
    subnet_id = azurerm_subnet.this.id
  }
  http_listener {
    frontend_ip_configuration_name = "${local.example["application_gateway"].name}-frontend-ip"
    frontend_port_name             = "${local.example["application_gateway"].name}-frontend-port"
    name                           = "${local.example["application_gateway"].name}-listener-http"
    protocol                       = "Http"
  }
  request_routing_rule {
    http_listener_name         = "${local.example["application_gateway"].name}-listener-http"
    name                       = "${local.example["application_gateway"].name}-rule"
    rule_type                  = "Basic"
    backend_address_pool_name  = "${local.example["application_gateway"].name}-backend-http"
    backend_http_settings_name = "${local.example["application_gateway"].name}-backend-http"
    priority                   = 25
  }
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
}

resource "azurerm_application_security_group" "this" {
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_lb" "this" {
  for_each = local.load_balancers

  location            = azurerm_resource_group.this.location
  name                = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  sku                 = each.value.sku

  frontend_ip_configuration {
    name                 = "${each.key}-frontendip"
    public_ip_address_id = azurerm_public_ip.this[each.key].id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = local.load_balancers

  loadbalancer_id = azurerm_lb.this[each.key].id
  name            = "${each.key}-backend"
}

# Creating a network interface with a unique name, telemetry settings, and in the specified resource group and location
module "test" {
  source                         = "../../"
  location                       = azurerm_resource_group.this.location
  name                           = module.naming.managed_disk.name_unique
  resource_group_name            = azurerm_resource_group.this.name
  auxiliary_mode                 = "AcceleratedConnections"
  auxiliary_sku                  = "A8"
  dns_servers                    = ["10.0.0.5", "10.0.0.6", "10.0.0.7"]
  edge_zone                      = "Los Angeles"
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  internal_dns_name_label        = "example.local"

  enable_telemetry = true

  ip_configurations = {
    "ipconfig1" = {
      name                                               = "external"
      primary                                            = true
      subnet_id                                          = azurerm_subnet.this.id
      private_ip_address_allocation                      = "Dynamic"
      gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.this["gateway_load_balancer"].frontend_ip_configuration[0].id
      private_ip_address_version                         = "IPv4"
      public_ip_address_id                               = azurerm_public_ip.this["network_interface"].id
    }
    "ipconfig2" = {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.this.id
      private_ip_address_allocation = "Dynamic"
      private_ip_address_version    = "IPv4"
    }
  }

  tags = {
    environment = "example"
  }
}
