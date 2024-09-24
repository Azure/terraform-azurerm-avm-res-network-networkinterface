output "location" {
  description = "The Azure deployment region."
  value       = var.location
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_network_interface.this
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = var.resource_group_name
}
