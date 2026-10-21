output "name" {
  value       = azurerm_storage_account.main.name
  description = "Storage Account Name."
}

output "id" {
  value       = azurerm_storage_account.main.id
  description = "Storage Account ID."
}

output "managed_principal_id" {
  value       = try(azurerm_storage_account.main.identity[0].principal_id, null)
  description = "System Assigned Managed Identity for the Storage Account."
}

output "primary_connection_string" {
  value       = var.shared_access_key_enabled ? azurerm_storage_account.main.primary_connection_string : null
  description = "Primary connection string. Null unless shared_access_key_enabled is true."
  sensitive   = true
}

output "primary_access_key" {
  value       = var.shared_access_key_enabled ? azurerm_storage_account.main.primary_access_key : null
  description = "Primary access key. Null unless shared_access_key_enabled is true."
  sensitive   = true
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.main.primary_blob_endpoint
  description = "The primary blob endpoint for the storage account."
}

output "primary_web_endpoint" {
  value       = azurerm_storage_account.main.primary_web_endpoint
  description = "The primary web endpoint for the storage account."
}

output "storage_shares_ids" {
  value       = { for share in azurerm_storage_share.main : share.name => share.id }
  description = "Map with storage share ids."
}

output "container_ids" {
  description = "The IDs of the storage containers"
  value       = { for c in azurerm_storage_container.main : c.name => c.id }
}

output "container_names" {
  description = "The names of the storage containers"
  value       = { for c in azurerm_storage_container.main : c.name => c.name }
}

