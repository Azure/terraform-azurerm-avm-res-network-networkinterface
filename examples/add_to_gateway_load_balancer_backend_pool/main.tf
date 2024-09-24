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
  sku                 = "Gateway"

  frontend_ip_configuration {
    name = "example"
    subnet_id = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = "example"  
  loadbalancer_id = azurerm_lb.this.id

  tunnel_interface {
    identifier = 901
    type = "External"
    protocol = "VXLAN"
    port = 10801
  }
}

resource "azurerm_lb_probe" "this" {
  name            = "example"
  loadbalancer_id = azurerm_lb.this.id
  protocol = "Http"
  port = 80
  request_path = "/"
  interval_in_seconds = 5
  probe_threshold = 2
}

resource "azurerm_lb_rule" "this" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "example"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "example"
  probe_id = azurerm_lb_probe.this.id
}

# Creating a network interface with a unique name, telemetry settings, and in the specified resource group and location
module "test" {
  source              = "../../"
  location            = azurerm_resource_group.this.location
  name                = module.naming.managed_disk.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = true

  ip_configurations = {
    "example" = {
      name                                               = "internal"
      subnet_id                                          = azurerm_subnet.this.id
      private_ip_address_allocation                      = "Dynamic"
      public_ip_address_id                               = azurerm_public_ip.this.id
      gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.this.frontend_ip_configuration[0].id
    }
  }
}
