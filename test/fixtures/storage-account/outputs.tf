output "storage_account_name" {
  value       = module.storage_account.name
  description = "Created storage account name."
}

output "primary_blob_endpoint" {
  value       = module.storage_account.primary_blob_endpoint
  description = "Blob endpoint; proves the Gov cloud (usgovcloudapi.net) target."
}

output "https_traffic_only_enabled" {
  value       = data.azurerm_storage_account.created.https_traffic_only_enabled
  description = "Read-back posture: HTTPS-only enforcement."
}

output "min_tls_version" {
  value       = data.azurerm_storage_account.created.min_tls_version
  description = "Read-back posture: minimum TLS version."
}
