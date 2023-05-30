resource "azurerm_storage_account" "main" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = var.account_tier
  account_replication_type          = var.replication_type
  enable_https_traffic_only         = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  account_kind                      = var.account_kind
  is_hns_enabled                    = var.is_hns_enabled
  nfsv3_enabled                     = var.nfsv3_enabled
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

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

resource "azurerm_key_vault_key" "cmk" {
  count        = var.enable_customer_managed_key ? 1 : 0
  name         = "${azurerm_storage_account.main.name}-cmk"
  key_vault_id = var.cmk_key_vault_id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_storage_account_customer_managed_key" "main" {
  count              = var.enable_customer_managed_key ? 1 : 0
  storage_account_id = azurerm_storage_account.main.id
  key_vault_id       = var.cmk_key_vault_id
  key_name           = azurerm_key_vault_key.cmk.0.name

  depends_on = [
    azurerm_role_assignment.sa_crypto_user,
    azurerm_key_vault_key.cmk
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
  #source                = "github.com/Coalfire-CF/ACE-Azure-Diagnostics?ref=v1.0.1"
  source                = "github.com/Coalfire-CF/ACE-Azure-Diagnostics"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_storage_account.main.id
  resource_type         = "sa"
}
