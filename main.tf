resource "azurerm_storage_account" "main" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = var.account_tier
  account_replication_type          = var.replication_type
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  account_kind                      = var.account_kind
  is_hns_enabled                    = var.is_hns_enabled
  nfsv3_enabled                     = var.nfsv3_enabled
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = true

  identity {
    type         = var.identity_ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_ids
  }

  lifecycle {
    ignore_changes = [
      customer_managed_key, # required by https://github.com/hashicorp/terraform-provider-azurerm/issues/16085
    ]
  }

  dynamic "network_rules" {
    for_each = var.public_network_access_enabled && (var.virtual_network_subnet_ids != null || var.ip_rules != null) ? [1] : []
    content {
      default_action             = "Deny"
      ip_rules                   = var.ip_rules
      virtual_network_subnet_ids = var.virtual_network_subnet_ids
      bypass                     = var.network_rules_bypass
      dynamic "private_link_access" {
        for_each = toset(var.private_link_access)
        content {
          endpoint_resource_id = private_link_access.value
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = var.static_website != null ? [1] : []
    content {
      index_document     = try(var.static_website.index_document, null)
      error_404_document = try(var.static_website.error_404_document, null)
    }
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "sa_crypto_user" {
  count                = var.enable_customer_managed_key ? 1 : 0
  scope                = var.cmk_key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.main.identity.0.principal_id
}

# Create a new CMK key only if not provided
module "storage_cmk" {
  count  = var.enable_customer_managed_key && var.cmk_key_name == null ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-azurerm-key-vault/modules/kv_key?ref=v1.1.1"

  name         = "${azurerm_storage_account.main.name}-cmk"
  key_type     = var.cmk_key_type
  key_vault_id = var.cmk_key_vault_id
  key_size     = var.cmk_key_size

  # Custom rotation policy
  rotation_policy_enabled     = var.cmk_rotation_policy_enabled
  rotation_expire_after       = var.cmk_rotation_expire_after
  rotation_time_before_expiry = var.cmk_rotation_time_before_expiry

  tags = var.tags

  depends_on = [azurerm_role_assignment.sa_crypto_user]
}

# Use provided CMK key name or the newly created one
locals {
  cmk_key_name = var.enable_customer_managed_key ? (
    var.cmk_key_name != null ? var.cmk_key_name : module.storage_cmk[0].key_name
  ) : null
}

resource "azurerm_storage_account_customer_managed_key" "main" {
  count              = var.enable_customer_managed_key ? 1 : 0
  storage_account_id = azurerm_storage_account.main.id
  key_vault_id       = var.cmk_key_vault_id
  key_name           = local.cmk_key_name

  depends_on = [
    azurerm_role_assignment.sa_crypto_user,
    module.storage_cmk
  ]
}

resource "azurerm_private_endpoint" "sa" {
  count               = var.endpoint_subnet_id != null ? 1 : 0
  name                = "${replace(var.name, "-sa", "")}-sa-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${replace(var.name, "-sa", "")}-sa-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = var.private_endpoint_subresource_names
  }

  private_dns_zone_group {
    name                 = "${replace(var.name, "-sa", "")}-sa-dnsgroup"
    private_dns_zone_ids = var.private_dns_zone_id != null ? [var.private_dns_zone_id] : []
  }
}

resource "azurerm_advanced_threat_protection" "main" {
  count              = var.enable_advanced_threat_protection ? 1 : 0
  target_resource_id = azurerm_storage_account.main.id
  enabled            = true
}

module "diag" {
  #Evaluate if we want to keep this specifically pinned to this version or reference the latest
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_storage_account.main.id
  resource_type         = "sa"
}
