resource "azurerm_storage_share" "main" {
  for_each             = { for share in var.storage_shares : share.name => share }
  name                 = each.value.name
  storage_account_id   = azurerm_storage_account.main.id
  quota                = each.value.quota
}
