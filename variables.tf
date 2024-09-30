variable "ip_configurations" {
  type = map(object({
    name                                               = string
    gateway_load_balancer_frontend_ip_configuration_id = optional(string, null)
    subnet_id                                          = string
    private_ip_address_version                         = optional(string, "IPv4")
    private_ip_address_allocation                      = optional(string, "Dynamic")
    public_ip_address_id                               = optional(string, null)
    primary                                            = optional(bool, null)
    private_ip_address                                 = optional(string, null)
  }))
  description = "A map of ip configurations for the network interface. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time."

  validation {
    condition     = alltrue([for config in var.ip_configurations : contains(["IPv4", "IPv6"], config.private_ip_address_version)])
    error_message = "The private IP address version must be 'IPv4' or 'IPv6'."
  }
  validation {
    condition     = alltrue([for config in var.ip_configurations : contains(["Static", "Dynamic"], config.private_ip_address_allocation)])
    error_message = "The private IP address version must be 'Static' or 'Dynamic'."
  }
  validation {
    condition     = length(var.ip_configurations) <= 1 || anytrue([for ip in var.ip_configurations : ip.primary])
    error_message = "At least one ip configuration must have 'primary' set to true."
  }
}

variable "location" {
  type        = string
  description = "The Azure location where the network interface should exist."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the network interface."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "The name must be between 1 and 80 characters long and can only contain letters, numbers, underscores, periods, and dashes."
  }
  validation {
    error_message = "The name must start with a letter or a number"
    condition     = can(regex("^[a-zA-Z0-9]", var.name))
  }
  validation {
    error_message = "The name must end with a letter or number or undescore"
    condition     = can(regex("[a-zA-Z0-9_]$", var.name))
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the network interface."
  nullable    = false
}

variable "accelerated_networking_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether accelerated networking should be enabled on the network interface or not."
}

variable "application_gateway_backend_address_pool_association" {
  type = object({
    application_gateway_backend_address_pool_id = string
    ip_configuration_name                       = string
  })
  default     = null
  description = <<DESCRIPTION
An object describing the application gateway to associate with the resource. This includes the following properties:
- `application_gateway_backend_address_pool_id` - The resource ID of the application gateway backend address pool.
- `ip_configuration_name` - The name of the network interface IP configuration.
DESCRIPTION 
}

variable "application_security_group_ids" {
  type        = list(string)
  default     = null
  description = "(Optional) List of application security group IDs."
}

variable "dns_servers" {
  type        = list(string)
  default     = null
  description = "(Optional) Specifies a list of IP addresses representing DNS servers."
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the extended location of the network interface."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "internal_dns_name_label" {
  type        = string
  default     = null
  description = "(Optional) The (relative) DNS Name used for internal communications between virtual machines in the same virtual network."
}

variable "ip_forwarding_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether IP forwarding should be enabled on the network interface or not."
}

variable "load_balancer_backend_address_pool_association" {
  type = map(object({
    load_balancer_backend_address_pool_id = string
    ip_configuration_name                 = string
  }))
  default     = null
  description = <<DESCRIPTION
A map of object describing the load balancer to associate with the resource. This includes the following properties:
- `load_balancer_backend_address_pool_id` - The resource ID of the load balancer backend address pool.
- `ip_configuration_name` - The name of the network interface IP configuration.
DESCRIPTION 
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "nat_rule_association" {
  type = map(object({
    nat_rule_id           = string
    ip_configuration_name = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map describing the NAT rule to associate with the resource. This includes the following properties:
- `nat_rule_id` - The resource ID of the NAT rule.
- `ip_configuration_name` - The name of the network interface IP configuration.
DESCRIPTION 
}

variable "network_security_group_ids" {
  type        = list(string)
  default     = null
  description = "(Optional) List of network security group IDs."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Map of tags to assign to the network interface."
}
