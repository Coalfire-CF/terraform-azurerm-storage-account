resource "azurerm_storage_container" "main" {
  for_each              = toset(var.storage_containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
