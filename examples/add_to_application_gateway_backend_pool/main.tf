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
    name = "${azurerm_virtual_network.this.name}-backend-pool"
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "${azurerm_virtual_network.this.name}-backend-http"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }
  frontend_ip_configuration {
    name                 = "${azurerm_virtual_network.this.name}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.this.id
  }
  frontend_port {
    name = "${azurerm_virtual_network.this.name}-frontend-port"
    port = 80
  }
  gateway_ip_configuration {
    name      = "example"
    subnet_id = azurerm_subnet.this.id
  }
  http_listener {
    frontend_ip_configuration_name = "${azurerm_virtual_network.this.name}-frontend-ip"
    frontend_port_name             = "${azurerm_virtual_network.this.name}-frontend-port"
    name                           = "${azurerm_virtual_network.this.name}-listener-http"
    protocol                       = "Http"
  }
  request_routing_rule {
    http_listener_name         = "${azurerm_virtual_network.this.name}-listener-http"
    name                       = "${azurerm_virtual_network.this.name}-rule"
    rule_type                  = "Basic"
    backend_address_pool_name  = "${azurerm_virtual_network.this.name}-backend-http"
    backend_http_settings_name = "${azurerm_virtual_network.this.name}-backend-http"
    priority                   = 25
  }
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
}

# Creating a network interface with a unique name, telemetry settings, and in the specified resource group and location
module "test" {
  source              = "../../"
  location            = azurerm_resource_group.this.location
  name                = module.naming.managed_disk.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = true

  ip_configurations = {
    "ipconfig1" = {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.this.id
      private_ip_address_allocation = "Dynamic"
    }
  }

  application_gateway_backend_address_pool_association = {
    "example" = {
      application_gateway_backend_address_pool_id = one(azurerm_application_gateway.this.backend_address_pool).id
      ip_configuration_name                       = "internal"
    }
  }
}
