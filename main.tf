locals {
  # Mirrors the azurerm 5.10.0 service support matrix (storage_account_data_plane_helpers.go).
  share_supported = var.account_kind == "FileStorage" || (
    var.account_tier == "Standard" && (
      var.account_kind == "StorageV2" ||
      (var.account_kind == "Storage" && contains(["LRS", "GRS", "RAGRS"], var.replication_type))
    )
  )

  # Point-in-time restore needs Standard StorageV2 without a hierarchical namespace.
  pitr_supported           = var.account_kind == "StorageV2" && var.account_tier == "Standard" && !var.is_hns_enabled
  blob_versioning_enabled  = coalesce(var.blob_properties.versioning_enabled, local.pitr_supported && var.point_in_time_restore_enabled)
  blob_change_feed_enabled = coalesce(var.blob_properties.change_feed_enabled, local.pitr_supported && var.point_in_time_restore_enabled)
  pitr_enabled             = local.pitr_supported && var.point_in_time_restore_enabled
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # prevent_destroy cannot be set from an input; a module-wide value would block every caller's teardown. Blob, container and share soft delete protect the data.
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_59:public_network_access = Disabled is set; CKV_AZURE_59 reads only the deprecated argument (azurerm 5 deprecates public_network_access_enabled)
  #checkov:skip=CKV_AZURE_33:azurerm 5 removed queue_properties, which this check reads; queue logs go to Log Analytics through module.diag (queueServices, allLogs)
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = var.account_tier
  account_replication_type          = var.replication_type
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  min_tls_version                   = var.min_tls_version
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  account_kind                      = var.account_kind
  access_tier                       = var.access_tier
  is_hns_enabled                    = var.is_hns_enabled
  nfsv3_enabled                     = var.nfsv3_enabled
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled
  public_network_access             = var.public_network_access
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  local_user_enabled                = var.local_user_enabled
  default_to_oauth_authentication   = true

  dynamic "identity" {
    for_each = var.enable_system_assigned_identity || try(length(var.identity_ids), 0) > 0 ? [1] : []

    content {
      type = var.enable_system_assigned_identity && try(length(var.identity_ids), 0) > 0 ? "SystemAssigned, UserAssigned" : (
        try(length(var.identity_ids), 0) > 0 ? "UserAssigned" : "SystemAssigned"
      )
      identity_ids = try(length(var.identity_ids), 0) > 0 ? var.identity_ids : null
    }
  }

  network_rules {
    default_action             = var.default_action
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

  dynamic "blob_properties" {
    for_each = var.account_kind == "FileStorage" ? [] : [var.blob_properties]

    content {
      change_feed_enabled           = local.blob_change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled
      versioning_enabled            = local.blob_versioning_enabled

      container_delete_retention_policy {
        days = var.container_delete_retention_days
      }

      delete_retention_policy {
        days = var.blob_delete_retention_days
      }

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rule

        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "restore_policy" {
        for_each = local.pitr_enabled ? [1] : []

        content {
          days = var.point_in_time_restore_days
        }
      }
    }
  }

  dynamic "share_properties" {
    for_each = local.share_supported ? [1] : []

    content {
      retention_policy {
        days = var.share_delete_retention_days
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      customer_managed_key, # required by https://github.com/hashicorp/terraform-provider-azurerm/issues/16085
    ]

    precondition {
      condition     = !var.enable_customer_managed_key || (var.cmk_key_vault_id != null && var.enable_system_assigned_identity)
      error_message = "enable_customer_managed_key = true needs cmk_key_vault_id and enable_system_assigned_identity = true."
    }

    precondition {
      condition = !local.pitr_enabled || (
        local.blob_versioning_enabled && local.blob_change_feed_enabled &&
        var.point_in_time_restore_days < var.blob_delete_retention_days
      )
      error_message = "Point-in-time restore needs blob_properties.versioning_enabled and change_feed_enabled left on, and point_in_time_restore_days below blob_delete_retention_days. Set point_in_time_restore_enabled = false to turn it off."
    }

    precondition {
      condition     = !(local.blob_versioning_enabled && var.is_hns_enabled)
      error_message = "blob_properties.versioning_enabled cannot be true when is_hns_enabled is true."
    }
  }

}

# azurerm 5.x removed the static_website block from azurerm_storage_account.
# The static_website input is unchanged; it now drives this separate resource.
resource "azurerm_storage_account_static_website" "main" {
  count              = var.static_website != null ? 1 : 0
  storage_account_id = azurerm_storage_account.main.id
  index_document     = try(var.static_website.index_document, null)
  error_404_document = try(var.static_website.error_404_document, null)
}

resource "azurerm_role_assignment" "sa_crypto_user" {
  count                = var.enable_customer_managed_key ? 1 : 0
  scope                = var.cmk_key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.main.identity[0].principal_id
}

# Create a new CMK key only if not provided
module "storage_cmk" {
  count  = var.enable_customer_managed_key && var.cmk_key_name == null ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-azurerm-key-vault//modules/kv_key?ref=v3.0.0"

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

# A caller-provided key is looked up so its versionless ID can be passed below.
data "azurerm_key_vault_key" "cmk" {
  count        = var.enable_customer_managed_key && var.cmk_key_name != null ? 1 : 0
  name         = var.cmk_key_name
  key_vault_id = var.cmk_key_vault_id
}

# Use the provided CMK key or the newly created one. azurerm 5.x takes a key ID
# instead of key_vault_id plus key_name. The versionless ID keeps automatic
# key version rotation, as the old key_name form did.
locals {
  cmk_key_versionless_id = var.enable_customer_managed_key ? (
    var.cmk_key_name != null ? data.azurerm_key_vault_key.cmk[0].versionless_id : module.storage_cmk[0].key_versionless_id
  ) : null
}

resource "azurerm_storage_account_customer_managed_key" "main" {
  count              = var.enable_customer_managed_key ? 1 : 0
  storage_account_id = azurerm_storage_account.main.id
  key_vault_key_id   = local.cmk_key_versionless_id

  depends_on = [
    azurerm_role_assignment.sa_crypto_user,
    module.storage_cmk
  ]
}

resource "azurerm_private_endpoint" "sa" {
  count               = var.endpoint_subnet_id != null ? 1 : 0
  name                = "${var.name}-sa-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-sa-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = var.private_endpoint_subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [var.private_dns_zone_id] : []

    content {
      name                 = "${var.name}-sa-dnsgroup"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }
}

resource "azurerm_advanced_threat_protection" "main" {
  count              = var.enable_advanced_threat_protection ? 1 : 0
  target_resource_id = azurerm_storage_account.main.id
  enabled            = true
}

module "diag" {
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics?ref=v3.0.0"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_storage_account.main.id
  resource_type         = "sa"
}
