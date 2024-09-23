terraform {
  required_version = "~> 1.5"
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

  enable_telemetry = var.enable_telemetry # see variables.tf

  ip_configurations = {
    "ipconfig1" = {
      name                                               = "internal"
      primary                                            = true
      subnet_id                                          = azurerm_subnet.this.id
      private_ip_address_allocation                      = "Dynamic"
      gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.this.frontend_ip_configuration.id
      private_ip_address_version                         = "IPv4"
      public_ip_address_id                               = azurerm_public_ip.this.id
    }
    "ipconfig2" = {
      name                                               = "internal"
      subnet_id                                          = azurerm_subnet.this.id
      private_ip_address_allocation                      = "Dynamic"
      private_ip_address_version                         = "IPv4"
    }
  }

  tags = {
    environment = "example"
  }
}
