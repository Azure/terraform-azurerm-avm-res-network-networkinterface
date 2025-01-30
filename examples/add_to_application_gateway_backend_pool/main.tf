terraform {
  required_version = ">= 1.9, < 2.0"
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
  count = 2

  address_prefixes     = ["10.0.${count.index + 1}.0/24"]
  name                 = "example_${count.index + 1}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_public_ip" "this" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_application_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name

  backend_address_pool {
    name = "${azurerm_virtual_network.this.name}-backend-pool-1"
  }
  backend_address_pool {
    name = "${azurerm_virtual_network.this.name}-backend-pool-2"
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "${azurerm_virtual_network.this.name}-backend-http-80"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "${azurerm_virtual_network.this.name}-backend-http-8080"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 20
  }
  frontend_ip_configuration {
    name                 = "${azurerm_virtual_network.this.name}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.this.id
  }
  frontend_port {
    name = "${azurerm_virtual_network.this.name}-frontend-port-80"
    port = 80
  }
  frontend_port {
    name = "${azurerm_virtual_network.this.name}-frontend-port-8080"
    port = 8080
  }
  gateway_ip_configuration {
    name      = "example"
    subnet_id = azurerm_subnet.this[0].id
  }
  http_listener {
    frontend_ip_configuration_name = "${azurerm_virtual_network.this.name}-frontend-ip"
    frontend_port_name             = "${azurerm_virtual_network.this.name}-frontend-port-80"
    name                           = "${azurerm_virtual_network.this.name}-listener-80"
    protocol                       = "Http"
  }
  http_listener {
    frontend_ip_configuration_name = "${azurerm_virtual_network.this.name}-frontend-ip"
    frontend_port_name             = "${azurerm_virtual_network.this.name}-frontend-port-8080"
    name                           = "${azurerm_virtual_network.this.name}-listener-8080"
    protocol                       = "Http"
  }
  request_routing_rule {
    http_listener_name         = "${azurerm_virtual_network.this.name}-listener-80"
    name                       = "${azurerm_virtual_network.this.name}-rule-1"
    rule_type                  = "Basic"
    backend_address_pool_name  = "${azurerm_virtual_network.this.name}-backend-pool-1"
    backend_http_settings_name = "${azurerm_virtual_network.this.name}-backend-http-80"
    priority                   = 15
  }
  request_routing_rule {
    http_listener_name         = "${azurerm_virtual_network.this.name}-listener-8080"
    name                       = "${azurerm_virtual_network.this.name}-rule-2"
    rule_type                  = "Basic"
    backend_address_pool_name  = "${azurerm_virtual_network.this.name}-backend-pool-2"
    backend_http_settings_name = "${azurerm_virtual_network.this.name}-backend-http-8080"
    priority                   = 25
  }
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
}

# Creating a network interface with a unique name, telemetry settings, and in the specified resource group and location
module "nic" {
  source              = "../../"
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_interface.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = true

  ip_configurations = {
    "example" = {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.this[1].id
      private_ip_address_allocation = "Dynamic"
    }
  }

  application_gateway_backend_address_pool_association = {
    application_gateway_backend_address_pool_id = lookup({ for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id }, "example-backend-pool-2", null)
    ip_configuration_name                       = "internal"
  }
}
