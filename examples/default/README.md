<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
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
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.managed_disk.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = var.enable_telemetry # see variables.tf

  ip_configurations = {
    "ipconfig1" = {
      name      = "ipconfig1"
      subnet_id = azurerm_subnet.this.id
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure location where the network interface should exist.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the network interface.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group in which to create the network interface.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_accelerated_networking_enabled"></a> [accelerated\_networking\_enabled](#input\_accelerated\_networking\_enabled)

Description: (Optional) Specifies whether accelerated networking should be enabled on the network interface or not.

Type: `bool`

Default: `false`

### <a name="input_application_gateway_backend_address_pool_association"></a> [application\_gateway\_backend\_address\_pool\_association](#input\_application\_gateway\_backend\_address\_pool\_association)

Description: A map describing the application gateway to associate with the resource. This includes the following properties:
- `application_gateway_backend_address_pool_id` - The resource ID of the application gateway backend address pool.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    application_gateway_backend_address_pool_id = list(string)
    ip_configuration_name                       = string
  }))
```

Default: `{}`

### <a name="input_application_security_group_association"></a> [application\_security\_group\_association](#input\_application\_security\_group\_association)

Description: A map describing the application security group to associate with the resource. This includes the following properties:
- `application_security_group_id` - The resource ID of the application security group.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    application_security_group_id = list(string)
    ip_configuration_name         = string
  }))
```

Default: `{}`

### <a name="input_auxiliary_mode"></a> [auxiliary\_mode](#input\_auxiliary\_mode)

Description: (Optional) Specifies the auxiliary mode used to enable network high-performance feature on Network Virtual Appliances (NVAs). Possible values are AcceleratedConnections, Floating, MaxConnections and None.

Type: `string`

Default: `"None"`

### <a name="input_auxiliary_sku"></a> [auxiliary\_sku](#input\_auxiliary\_sku)

Description: (Optional) Specifies the SKU used for the network high-performance feature on Network Virtual Appliances (NVAs).

Type: `string`

Default: `"None"`

### <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers)

Description: (Optional) Specifies a list of IP addresses representing DNS servers.

Type: `list(string)`

Default: `null`

### <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone)

Description: (Optional) Specifies the extended location of the network interface.

Type: `string`

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_internal_dns_name_label"></a> [internal\_dns\_name\_label](#input\_internal\_dns\_name\_label)

Description: (Optional) The (relative) DNS Name used for internal communications between virtual machines in the same virtual network.

Type: `string`

Default: `null`

### <a name="input_ip_configurations"></a> [ip\_configurations](#input\_ip\_configurations)

Description: A map of ip configurations for the network interface. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

Type:

```hcl
map(object({
    name                                               = string
    gateway_load_balancer_frontend_ip_configuration_id = optional(string, null)
    subnet_id                                          = string
    private_ip_address_version                         = optional(string, "IPv4")
    private_ip_address_allocation                      = optional(string, "Dynamic")
    public_ip_address_id                               = optional(string, null)
    primary                                            = optional(bool, false)
    private_ip_address                                 = optional(string, null)
  }))
```

Default:

```json
{
  "ipconfig1": {
    "name": "ipconfig1"
  }
}
```

### <a name="input_ip_forwarding_enabled"></a> [ip\_forwarding\_enabled](#input\_ip\_forwarding\_enabled)

Description: (Optional) Specifies whether IP forwarding should be enabled on the network interface or not.

Type: `bool`

Default: `false`

### <a name="input_load_balancer_backend_address_pool_association"></a> [load\_balancer\_backend\_address\_pool\_association](#input\_load\_balancer\_backend\_address\_pool\_association)

Description: (Optional) A map describing the load balancer to associate with the resource. This includes the following properties:
- `load_balancer_backend_address_pool_id` - The resource ID of the load balancer backend address pool.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    backend_address_pool_id = list(string)
    ip_configuration_name   = string
  }))
```

Default: `{}`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_nat_rule_association"></a> [nat\_rule\_association](#input\_nat\_rule\_association)

Description: A map describing the NAT  gateway to associate with the resource. This includes the following properties:
- `nat_rule_id` - The resource ID of the NAT rule.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    nat_rule_id           = list(string)
    ip_configuration_name = string
  }))
```

Default: `{}`

### <a name="input_network_security_group_association"></a> [network\_security\_group\_association](#input\_network\_security\_group\_association)

Description: A map describing the network security group to associate with the resource. This includes the following properties:
- `network_security_group_id` - The resource ID of the network security group.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    network_security_group_id = list(string)
    ip_configuration_name     = string
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to assign to the network interface.

Type: `map(string)`

Default: `null`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

### <a name="module_test"></a> [test](#module\_test)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->