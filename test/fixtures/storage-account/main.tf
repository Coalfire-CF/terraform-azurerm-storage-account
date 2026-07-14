resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# The module's diag_log_analytics_id input is required, so the fixture carries a
# minimal Log Analytics workspace.
resource "azurerm_log_analytics_workspace" "test" {
  name                = "law-${var.name}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

module "storage_account" {
  source = "../../.." # the module at PR HEAD - this fixture tests the working tree, not a release

  name                  = var.name
  resource_group_name   = azurerm_resource_group.test.name
  location              = var.location
  diag_log_analytics_id = azurerm_log_analytics_workspace.test.id
  replication_type      = "LRS" # cheapest for an ephemeral test; posture defaults under test are unchanged
  tags                  = var.tags

  # The module defaults enable_customer_managed_key to true, which requires
  # cmk_key_vault_id (undefined here) and fails azurerm_role_assignment.sa_crypto_user
  # with "Missing required argument". This self-test doesn't exercise CMK/Key Vault infra.
  enable_customer_managed_key = false
}

# Read-back of the created account so posture assertions go through Terraform
# outputs (no Azure Go SDK auth needed in the test).
data "azurerm_storage_account" "created" {
  name                = module.storage_account.name
  resource_group_name = azurerm_resource_group.test.name
}
