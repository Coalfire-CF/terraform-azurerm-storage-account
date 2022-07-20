output "sa_name" {
  value       = azurerm_storage_account.sa.name
  description = "Storage Account Name"
}

output "sa_id" {
  value       = azurerm_storage_account.sa.id
  description = "Storage Account ID"
}

output "sa_managed_id" {
  value       = azurerm_storage_account.sa.identity.0.principal_id
  description = "System Assigned Managed Identity for the Storage Account"
}

output "sa_primary_connection_string" {
  value       = azurerm_storage_account.sa.primary_connection_string
  description = "Primary SA connection string"
  sensitive   = true
}

output "sa_primary_access_key" {
  value       = azurerm_storage_account.sa.primary_access_key
  description = "The primary access key for the storage account."
  sensitive   = true
}
