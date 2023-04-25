resource "azurerm_storage_container" "main" {
  for_each              = toset(var.storage_containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
