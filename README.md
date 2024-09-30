<!-- BEGIN_TF_DOCS -->
# Azure Network Interface Module

This module is designed to deploy and manage Azure Network Interfaces. It allows for the creation of network interfaces and their association with various Azure resources, such as subnets, network security groups, public IP addresses, and more.

## Features

This module supports managing network interfaces and their associated resources. It includes capabilities for:

- Creating a new network interface
- Adding IP configurations to a network interface
- Associating a network security group with a network interface
- Assigning public IP addresses to a network interface
- Configuring DNS settings for a network interface
- Enabling accelerated networking on a network interface
- Connecting a network interface to a NAT rule
- Adding a network interface to a backend pool of an application gateway
- Configuring IPv4 and IPv6 dual networking on a network interface
- Adding a network interface to an application security group
- Enabling IP forwarding on a network interface
- Adding a network interface to a Gateway or Standard Load Balancer

## Usage

To use this module in your Terraform configuration, provide values for the required variables.

### Example - Create a network interface on an existing subnet

This example demonstrates the basic usage of the module to create a new network interface using an existing subnet.

```terraform
module "avm-res-network-interface" {
  source = "Azure/avm-res-network-interface/azurerm"

  location            = "East US"
  name                = "myNIC"
  resource_group_name = "myResourceGroup"
  ip_configurations = {
    "ipconfig1" = {
      name      = "ipconfig1"
      private_ip_address_allocation = "Dynamic"      
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet/subnets/subnet1"
    }  
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (0.3.2)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_network_interface_application_gateway_backend_address_pool_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_gateway_backend_address_pool_association) (resource)
- [azurerm_network_interface_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_security_group_association) (resource)
- [azurerm_network_interface_backend_address_pool_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) (resource)
- [azurerm_network_interface_nat_rule_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_nat_rule_association) (resource)
- [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/0.3.2/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/0.3.2/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

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
    primary                                            = optional(bool, null)
    private_ip_address                                 = optional(string, null)
  }))
```

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

Description: An object describing the application gateway to associate with the resource. This includes the following properties:
- `application_gateway_backend_address_pool_id` - The resource ID of the application gateway backend address pool.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
object({
    application_gateway_backend_address_pool_id = string
    ip_configuration_name                       = string
  })
```

Default: `null`

### <a name="input_application_security_group_ids"></a> [application\_security\_group\_ids](#input\_application\_security\_group\_ids)

Description: (Optional) List of application security group IDs.

Type: `list(string)`

Default: `null`

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
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_internal_dns_name_label"></a> [internal\_dns\_name\_label](#input\_internal\_dns\_name\_label)

Description: (Optional) The (relative) DNS Name used for internal communications between virtual machines in the same virtual network.

Type: `string`

Default: `null`

### <a name="input_ip_forwarding_enabled"></a> [ip\_forwarding\_enabled](#input\_ip\_forwarding\_enabled)

Description: (Optional) Specifies whether IP forwarding should be enabled on the network interface or not.

Type: `bool`

Default: `false`

### <a name="input_load_balancer_backend_address_pool_association"></a> [load\_balancer\_backend\_address\_pool\_association](#input\_load\_balancer\_backend\_address\_pool\_association)

Description: A map of object describing the load balancer to associate with the resource. This includes the following properties:
- `load_balancer_backend_address_pool_id` - The resource ID of the load balancer backend address pool.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    load_balancer_backend_address_pool_id = string
    ip_configuration_name                 = string
  }))
```

Default: `null`

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

Description: A map describing the NAT rule to associate with the resource. This includes the following properties:
- `nat_rule_id` - The resource ID of the NAT rule.
- `ip_configuration_name` - The name of the network interface IP configuration.

Type:

```hcl
map(object({
    nat_rule_id           = string
    ip_configuration_name = string
  }))
```

Default: `{}`

### <a name="input_network_security_group_ids"></a> [network\_security\_group\_ids](#input\_network\_security\_group\_ids)

Description: (Optional) List of network security group IDs.

Type: `list(string)`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to assign to the network interface.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_location"></a> [location](#output\_location)

Description: The Azure deployment region.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: This is the full output for the resource.

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: The name of the resource group.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: This id of the resource.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
