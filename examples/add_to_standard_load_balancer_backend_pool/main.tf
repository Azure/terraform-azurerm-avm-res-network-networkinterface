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

resource "azurerm_lb" "this" {
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  count = 2

  loadbalancer_id = azurerm_lb.this.id
  name            = "example-${count.index}"
}

# Creating a network interface with a unique name, telemetry settings, and in the specified resource group and location
module "test" {
  source              = "../../"
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_interface.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = true

  ip_configurations = {
    "ipconfig1" = {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.this.id
      private_ip_address_allocation = "Dynamic"
      primary                       = "true"
    }
    "ipconfig2" = {
      name                          = "external"
      subnet_id                     = azurerm_subnet.this.id
      private_ip_address_allocation = "Dynamic"
    }
  }

  load_balancer_backend_address_pool_association = {
    "association1" = {
      load_balancer_backend_address_pool_id = azurerm_lb_backend_address_pool.this[0].id
      ip_configuration_name                 = "internal"
    }
    "association2" = {
      load_balancer_backend_address_pool_id = azurerm_lb_backend_address_pool.this[1].id
      ip_configuration_name                 = "external"
    }
  }
}
