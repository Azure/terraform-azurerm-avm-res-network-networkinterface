<!-- BEGIN_TF_DOCS -->
# Configure all settings of a network interface

This example shows how to create and configure a network interface with all its settings using Terraform for Azure.

```hcl
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
  location = "westus"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = "example"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16", "2001:db8:abcd::/56"]
}

resource "azurerm_subnet" "this" {
  count = 2

  address_prefixes     = ["10.0.${count.index + 1}.0/24", "2001:db8:abcd:001${count.index + 2}::/64"]
  name                 = "example-${count.index + 1}"
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
    subnet_id = azurerm_subnet.this[0].id
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
    backend_address_pool_name  = "${local.example["application_gateway"].name}-backend-pool"
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
  name                = each.value.sku
  resource_group_name = azurerm_resource_group.this.name
  sku                 = each.value.sku

  frontend_ip_configuration {
    name                          = "${each.key}-frontendip"
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    subnet_id                     = azurerm_subnet.this[1].id
  }
}

resource "azurerm_lb_backend_address_pool" "standard" {
  loadbalancer_id = azurerm_lb.this["standard_load_balancer"].id
  name            = "example-standard-backend"
}

resource "azurerm_lb_backend_address_pool" "gateway" {
  loadbalancer_id = azurerm_lb.this["gateway_load_balancer"].id
  name            = "example-gateway-backend"

  tunnel_interface {
    identifier = 901
    port       = 10801
    protocol   = "VXLAN"
    type       = "External"
  }
}

resource "azurerm_lb_probe" "this" {
  loadbalancer_id     = azurerm_lb.this["gateway_load_balancer"].id
  name                = "example"
  port                = 80
  interval_in_seconds = 5
  probe_threshold     = 2
  protocol            = "Http"
  request_path        = "/"
}

resource "azurerm_lb_rule" "this" {
  backend_port                   = 0
  frontend_ip_configuration_name = azurerm_lb.this["gateway_load_balancer"].frontend_ip_configuration[0].name
  frontend_port                  = 0
  loadbalancer_id                = azurerm_lb.this["gateway_load_balancer"].id
  name                           = "example"
  protocol                       = "All"
  probe_id                       = azurerm_lb_probe.this.id
}

resource "azurerm_lb_nat_rule" "rdp" {
  backend_port                   = 3389
  frontend_ip_configuration_name = azurerm_lb.this["standard_load_balancer"].frontend_ip_configuration[0].name
  loadbalancer_id                = azurerm_lb.this["standard_load_balancer"].id
  name                           = "RDPAccess"
  protocol                       = "Tcp"
  resource_group_name            = azurerm_resource_group.this.name
  frontend_port                  = 3389
}

# Creating a network interface with a unique name, telemetry settings, and in the specified resource group and location
module "nic" {
  source = "../../"

  ip_configurations = {
    "ipconfig1" = {
      name                                               = "external"
      primary                                            = true
      subnet_id                                          = azurerm_subnet.this[1].id
      private_ip_address_allocation                      = "Dynamic"
      gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.this["gateway_load_balancer"].frontend_ip_configuration[0].id
      private_ip_address_version                         = "IPv4"
      public_ip_address_id                               = azurerm_public_ip.this["network_interface"].id
    }
  }
  location                       = azurerm_resource_group.this.location
  name                           = module.naming.network_interface.name_unique
  resource_group_name            = azurerm_resource_group.this.name
  accelerated_networking_enabled = true
  application_gateway_backend_address_pool_association = {
    application_gateway_backend_address_pool_id = lookup({ for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id }, "${local.example["application_gateway"].name}-backend-pool", null)
    ip_configuration_name                       = "external"
  }
  application_security_group_ids = azurerm_application_security_group.this[*].id
  dns_servers                    = ["10.0.1.5", "10.0.1.6", "10.0.1.7"]
  enable_telemetry               = true
  internal_dns_name_label        = "myinternaldnsnamelabel"
  ip_forwarding_enabled          = true
  load_balancer_backend_address_pool_association = {
    "association1" = {
      load_balancer_backend_address_pool_id = azurerm_lb_backend_address_pool.standard.id
      ip_configuration_name                 = "external"
    }
  }
  nat_rule_association = {
    "association1" = {
      nat_rule_id           = azurerm_lb_nat_rule.rdp.id
      ip_configuration_name = "external"
    }
  }
  network_security_group_ids = azurerm_network_security_group.this[*].id
  tags = {
    environment = "example"
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_application_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_application_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group) (resource)
- [azurerm_lb.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) (resource)
- [azurerm_lb_backend_address_pool.gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) (resource)
- [azurerm_lb_backend_address_pool.standard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) (resource)
- [azurerm_lb_nat_rule.rdp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_nat_rule) (resource)
- [azurerm_lb_probe.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) (resource)
- [azurerm_lb_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) (resource)
- [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_nic"></a> [nic](#module\_nic)

Source: ../../

Version:

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

## Usage

Ensure you have Terraform installed and the Azure CLI authenticated to your Azure subscription.

Navigate to the directory containing this configuration and run:

```
terraform init
terraform plan
terraform apply
```
<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## AVM Versioning Notice

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to https://semver.org/
<!-- END_TF_DOCS -->