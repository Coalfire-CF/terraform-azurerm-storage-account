resource "azurerm_storage_management_policy" "main" {
  count = var.lifecycle_policies != null ? 1 : 0

  storage_account_id = azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = var.lifecycle_policies
    iterator = rule
    content {
      name    = "rule-${rule.key}"
      enabled = true
      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = ["blockBlob"]
      }
      actions {
        dynamic "base_blob" {
          for_each = rule.value.base_blob != null ? [1] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than        = try(rule.value.base_blob.tier_to_cool_after_days_since_modification_greater_than, null)
            tier_to_cool_after_days_since_last_access_time_greater_than    = try(rule.value.base_blob.tier_to_cool_after_days_since_last_access_time_greater_than, null)
            tier_to_archive_after_days_since_modification_greater_than     = try(rule.value.base_blob.tier_to_archive_after_days_since_modification_greater_than, null)
            tier_to_archive_after_days_since_last_access_time_greater_than = try(rule.value.base_blob.tier_to_archive_after_days_since_last_access_time_greater_than, null)
            tier_to_archive_after_days_since_last_tier_change_greater_than = try(rule.value.base_blob.tier_to_archive_after_days_since_last_tier_change_greater_than, null)
            delete_after_days_since_modification_greater_than              = try(rule.value.base_blob.delete_after_days_since_modification_greater_than, null)
            delete_after_days_since_last_access_time_greater_than          = try(rule.value.base_blob.delete_after_days_since_last_access_time_greater_than, null)
          }
        }
        dynamic "version" {
          for_each = rule.value.version != null ? [1] : []
          content {
            change_tier_to_archive_after_days_since_creation               = try(rule.value.version.change_tier_to_archive_after_days_since_creation, null)
            tier_to_archive_after_days_since_last_tier_change_greater_than = try(rule.value.version.tier_to_archive_after_days_since_last_tier_change_greater_than, null)
            change_tier_to_cool_after_days_since_creation                  = try(rule.value.version.change_tier_to_cool_after_days_since_creation, null)
            delete_after_days_since_creation                               = try(rule.value.version.delete_after_days_since_creation, null)
          }
        }
        dynamic "snapshot" {
          for_each = rule.value.snapshot != null ? [1] : []
          content {
            change_tier_to_archive_after_days_since_creation               = try(rule.value.snapshot.change_tier_to_archive_after_days_since_creation, null)
            tier_to_archive_after_days_since_last_tier_change_greater_than = try(rule.value.snapshot.tier_to_archive_after_days_since_last_tier_change_greater_than, null)
            change_tier_to_cool_after_days_since_creation                  = try(rule.value.snapshot.change_tier_to_cool_after_days_since_creation, null)
            delete_after_days_since_creation_greater_than                  = try(rule.value.snapshot.delete_after_days_since_creation_greater_than, null)
          }
        }
      }
    }
  }
}