# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_network_interface.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_network_interface" "this" {
  location                       = var.location
  name                           = var.name
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = var.accelerated_networking_enabled
  auxiliary_mode                 = var.auxiliary_mode
  auxiliary_sku                  = var.auxiliary_sku
  dns_servers                    = var.dns_servers
  edge_zone                      = var.edge_zone
  internal_dns_name_label        = var.internal_dns_name_label
  ip_forwarding_enabled          = var.ip_forwarding_enabled
  tags                           = var.tags

  dynamic "ip_configuration" {
    for_each = var.ip_configurations

    content {
      name                                               = ip_configuration.value.name
      private_ip_address_allocation                      = ip_configuration.value.private_ip_address_allocation
      gateway_load_balancer_frontend_ip_configuration_id = ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_id
      primary                                            = ip_configuration.value.primary
      private_ip_address                                 = ip_configuration.value.private_ip_address_allocation == "Static" ? ip_configuration.value.private_ip_address : null
      private_ip_address_version                         = ip_configuration.value.private_ip_address_version
      public_ip_address_id                               = ip_configuration.value.public_ip_address_id
      subnet_id                                          = ip_configuration.value.private_ip_address_version == "IPv4" ? ip_configuration.value.subnet_id : null
    }
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each = { for key, value in var.load_balancer_backend_address_pool_association : key => value if length(value.load_balancer_backend_address_pool_id) > 0 }

  backend_address_pool_id = each.value.load_balancer_backend_address_pool_id
  ip_configuration_name   = each.value.ip_configuration_name
  network_interface_id    = azurerm_network_interface.this.id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
  for_each = { for key, value in var.application_gateway_backend_address_pool_association : key => value if length(value.application_gateway_backend_address_pool_id) > 0 }

  backend_address_pool_id = each.value.application_gateway_backend_address_pool_id
  ip_configuration_name   = each.value.ip_configuration_name
  network_interface_id    = azurerm_network_interface.this.id
}

resource "azurerm_network_interface_application_security_group_association" "this" {
  for_each = { for key, value in var.application_security_group_association : key => value if length(value.application_security_group_id) > 0 }

  application_security_group_id = each.value.application_security_group_id
  network_interface_id          = azurerm_network_interface.this.id
}

resource "azurerm_network_interface_nat_rule_association" "this" {
  for_each = { for key, value in var.nat_rule_association : key => value if length(value.nat_rule_id) > 0 }

  ip_configuration_name = each.value.ip_configuration_name
  nat_rule_id           = each.value.nat_rule_id
  network_interface_id  = azurerm_network_interface.this.id
}

resource "azurerm_network_interface_security_group_association" "this" {
  for_each = { for key, value in var.network_security_group_association : key => value if length(value.network_security_group_id) > 0 }

  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = each.value.network_security_group_id
}
