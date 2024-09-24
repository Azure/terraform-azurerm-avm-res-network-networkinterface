<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Search and update TODOs within the code and remove the TODO comments once complete.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

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
    primary                                            = optional(bool, false)
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

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->