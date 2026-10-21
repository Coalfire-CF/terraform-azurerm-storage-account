resource "azurerm_storage_container" "main" {
  #checkov:skip=CKV2_AZURE_21:Blob read logs go to Log Analytics through module.diag (blobServices, allLogs). This check accepts only azurerm_log_analytics_storage_insights, which needs a storage account key, and shared keys are disabled by default (R15).
  for_each              = toset(var.storage_containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
