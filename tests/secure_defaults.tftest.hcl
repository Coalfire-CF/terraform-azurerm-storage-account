# Offline checks for the secure defaults and input guards. The provider is
# mocked, so no Azure credentials are needed. Plan runs only.

mock_provider "azurerm" {
  mock_data "azurerm_monitor_diagnostic_categories" {
    defaults = {
      log_category_groups = ["allLogs"]
      log_category_types  = ["StorageRead"]
      metrics             = ["Transaction"]
    }
  }
}

variables {
  name                  = "testsa"
  resource_group_name   = "test-rg"
  location              = "usgovvirginia"
  diag_log_analytics_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
  tags                  = { Function = "Storage" }
}

run "defaults_are_secure" {
  command = plan

  assert {
    condition     = azurerm_storage_account.main.public_network_access == "Disabled"
    error_message = "public_network_access must default to Disabled (R6, D5)."
  }

  assert {
    condition     = azurerm_storage_account.main.shared_access_key_enabled == false
    error_message = "shared_access_key_enabled must default to false (R15)."
  }

  assert {
    condition     = azurerm_storage_account.main.local_user_enabled == false
    error_message = "local_user_enabled must default to false (R15)."
  }

  assert {
    condition     = azurerm_storage_account.main.default_to_oauth_authentication == true
    error_message = "default_to_oauth_authentication must be true (R15)."
  }

  assert {
    condition     = azurerm_storage_account.main.min_tls_version == "TLS1_2"
    error_message = "min_tls_version must default to TLS1_2 (R11)."
  }

  assert {
    condition     = azurerm_storage_account.main.https_traffic_only_enabled == true
    error_message = "https_traffic_only_enabled must default to true (R11)."
  }

  assert {
    condition     = azurerm_storage_account.main.infrastructure_encryption_enabled == true
    error_message = "infrastructure_encryption_enabled must default to true (R12)."
  }

  assert {
    condition     = azurerm_storage_account.main.allow_nested_items_to_be_public == false
    error_message = "allow_nested_items_to_be_public must default to false (R6)."
  }

  assert {
    condition     = azurerm_storage_account.main.network_rules[0].default_action == "Deny"
    error_message = "The storage firewall must exist and default to Deny (R7)."
  }

  assert {
    condition     = length(azurerm_storage_account.main.network_rules[0].ip_rules) == 0 && length(azurerm_storage_account.main.network_rules[0].virtual_network_subnet_ids) == 0
    error_message = "No IPs or subnets may be allowed by default (R7)."
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "Blob soft delete must default to 7 days (R22)."
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].container_delete_retention_policy[0].days == 7
    error_message = "Container soft delete must default to 7 days (R22)."
  }

  assert {
    condition     = azurerm_storage_account.main.share_properties[0].retention_policy[0].days == 7
    error_message = "File share soft delete must default to 7 days (R22)."
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].versioning_enabled == true && azurerm_storage_account.main.blob_properties[0].change_feed_enabled == true
    error_message = "Blob versioning and change feed must default on for point-in-time restore (R22, D2)."
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].restore_policy[0].days == 6
    error_message = "Point-in-time restore must default on at 6 days (R22, D2)."
  }

  assert {
    condition     = length(azurerm_storage_account_customer_managed_key.main) == 0 && length(azurerm_role_assignment.sa_crypto_user) == 0
    error_message = "A customer-managed key must be optional and off by default (R12)."
  }

  assert {
    condition     = length(azurerm_private_endpoint.sa) == 0
    error_message = "No private endpoint without endpoint_subnet_id."
  }
}

run "containers_are_private" {
  command = plan

  variables {
    storage_containers = ["data"]
  }

  assert {
    condition     = azurerm_storage_container.main["data"].container_access_type == "private"
    error_message = "Containers must be private (R6)."
  }
}

# Checks block rendering only. diagnostics v3.0.0 targets blob, queue and
# table services that FileStorage lacks, so a live apply is not expected to work.
run "file_storage_renders_no_blob_properties" {
  command = plan

  variables {
    account_kind = "FileStorage"
    account_tier = "Premium"
    access_tier  = "Premium"
  }

  assert {
    condition     = length(azurerm_storage_account.main.blob_properties) == 0
    error_message = "FileStorage accounts take no blob_properties block."
  }

  assert {
    condition     = azurerm_storage_account.main.share_properties[0].retention_policy[0].days == 7
    error_message = "FileStorage accounts keep share soft delete."
  }
}

run "rejects_unknown_public_network_access" {
  command = plan

  variables {
    public_network_access = "true"
  }

  expect_failures = [var.public_network_access]
}

run "rejects_old_tls" {
  command = plan

  variables {
    min_tls_version = "TLS1_1"
  }

  expect_failures = [var.min_tls_version]
}

run "rejects_default_action_typo" {
  command = plan

  variables {
    default_action = "deny"
  }

  expect_failures = [var.default_action]
}

run "cmk_requires_key_vault" {
  command = plan

  variables {
    enable_customer_managed_key = true
  }

  expect_failures = [azurerm_storage_account.main]
}

run "premium_storagev2_has_no_share_or_pitr" {
  command = plan

  variables {
    account_tier     = "Premium"
    replication_type = "LRS"
  }

  assert {
    condition     = length(azurerm_storage_account.main.share_properties) == 0
    error_message = "Premium StorageV2 does not support share_properties (azurerm 5.10.0)."
  }

  assert {
    condition     = length(azurerm_storage_account.main.blob_properties[0].restore_policy) == 0 && azurerm_storage_account.main.blob_properties[0].versioning_enabled == false
    error_message = "Point-in-time restore and its versioning default apply only to Standard StorageV2."
  }
}

run "storage_v1_zrs_has_no_share_or_pitr" {
  command = plan

  variables {
    account_kind     = "Storage"
    replication_type = "ZRS"
  }

  assert {
    condition     = length(azurerm_storage_account.main.share_properties) == 0
    error_message = "Storage v1 with ZRS does not support share_properties (azurerm 5.10.0)."
  }

  assert {
    condition     = length(azurerm_storage_account.main.blob_properties[0].restore_policy) == 0 && azurerm_storage_account.main.blob_properties[0].versioning_enabled == false && azurerm_storage_account.main.blob_properties[0].change_feed_enabled == false
    error_message = "Storage v1 must not send versioning, change feed or restore policy."
  }
}

run "hns_turns_off_versioning_and_pitr" {
  command = plan

  variables {
    is_hns_enabled = true
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].versioning_enabled == false && length(azurerm_storage_account.main.blob_properties[0].restore_policy) == 0
    error_message = "HNS accounts must not get versioning or point-in-time restore."
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "HNS accounts keep blob soft delete."
  }
}

run "pitr_can_be_turned_off" {
  command = plan

  variables {
    point_in_time_restore_enabled = false
  }

  assert {
    condition     = length(azurerm_storage_account.main.blob_properties[0].restore_policy) == 0 && azurerm_storage_account.main.blob_properties[0].versioning_enabled == false
    error_message = "point_in_time_restore_enabled = false must drop the restore policy and its versioning default."
  }
}

run "rejects_pitr_days_at_or_above_soft_delete" {
  command = plan

  variables {
    blob_delete_retention_days = 6
  }

  expect_failures = [azurerm_storage_account.main]
}

run "rejects_pitr_without_versioning" {
  command = plan

  variables {
    blob_properties = { versioning_enabled = false }
  }

  expect_failures = [azurerm_storage_account.main]
}

run "rejects_versioning_with_hns" {
  command = plan

  variables {
    is_hns_enabled  = true
    blob_properties = { versioning_enabled = true }
  }

  expect_failures = [azurerm_storage_account.main]
}

run "private_endpoint_when_subnet_given" {
  command = plan

  variables {
    endpoint_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/pe"
    private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net"
  }

  assert {
    condition     = azurerm_private_endpoint.sa[0].private_service_connection[0].subresource_names == tolist(["blob"])
    error_message = "The private endpoint must default to the blob subresource (R8)."
  }

  assert {
    condition     = azurerm_private_endpoint.sa[0].private_dns_zone_group[0].private_dns_zone_ids == tolist([var.private_dns_zone_id])
    error_message = "The private endpoint must join the given private DNS zone (R8)."
  }
}
