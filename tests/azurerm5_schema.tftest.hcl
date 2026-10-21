# Offline checks for the azurerm 5.x schema changes. The provider is mocked, so
# no Azure credentials are needed: run `terraform init -backend=false` then
# `terraform test`.

mock_provider "azurerm" {
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testsa"
    }
  }

  mock_resource "azurerm_key_vault_key" {
    defaults = {
      versionless_id = "https://test-kv.vault.usgovcloudapi.net/keys/created-cmk"
    }
  }

  mock_data "azurerm_monitor_diagnostic_categories" {
    defaults = {
      log_category_groups = ["allLogs"]
      log_category_types  = ["StorageRead"]
      metrics             = ["Transaction"]
    }
  }

  mock_data "azurerm_key_vault_key" {
    defaults = {
      versionless_id = "https://test-kv.vault.usgovcloudapi.net/keys/existing-cmk"
    }
  }
}

variables {
  name                  = "testsa"
  resource_group_name   = "test-rg"
  location              = "usgovvirginia"
  diag_log_analytics_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
  tags                  = {}
  cmk_key_vault_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/test-kv"
}

run "static_website_renders_as_separate_resource" {
  command = apply

  variables {
    enable_customer_managed_key = false
    static_website = {
      index_document     = "index.html"
      error_404_document = "404.html"
    }
  }

  assert {
    condition     = length(azurerm_storage_account_static_website.main) == 1
    error_message = "A non-null static_website must create one azurerm_storage_account_static_website."
  }

  assert {
    condition     = azurerm_storage_account_static_website.main[0].storage_account_id == azurerm_storage_account.main.id
    error_message = "The static website must target the module's storage account."
  }

  assert {
    condition     = azurerm_storage_account_static_website.main[0].index_document == "index.html" && azurerm_storage_account_static_website.main[0].error_404_document == "404.html"
    error_message = "index_document and error_404_document must come from var.static_website."
  }
}

run "no_static_website_by_default" {
  command = apply

  variables {
    enable_customer_managed_key = false
  }

  assert {
    condition     = length(azurerm_storage_account_static_website.main) == 0
    error_message = "A null static_website must create no static website resource."
  }

  assert {
    condition     = length(azurerm_storage_account_customer_managed_key.main) == 0
    error_message = "enable_customer_managed_key = false must create no CMK binding."
  }
}

run "cmk_uses_existing_key_versionless_id" {
  command = apply

  variables {
    enable_customer_managed_key = true
    cmk_key_name                = "existing-cmk"
  }

  assert {
    condition     = length(azurerm_storage_account_customer_managed_key.main) == 1
    error_message = "Expected one CMK binding."
  }

  assert {
    condition     = azurerm_storage_account_customer_managed_key.main[0].key_vault_key_id == "https://test-kv.vault.usgovcloudapi.net/keys/existing-cmk"
    error_message = "With cmk_key_name set, the CMK binding must use the existing key's versionless ID."
  }

  assert {
    condition     = length(module.storage_cmk) == 0
    error_message = "With cmk_key_name set, the module must not create a key."
  }
}

run "cmk_uses_created_key_versionless_id" {
  command = apply

  variables {
    enable_customer_managed_key = true
  }

  assert {
    condition     = length(module.storage_cmk) == 1
    error_message = "Without cmk_key_name, the module must create a key."
  }

  assert {
    condition     = azurerm_storage_account_customer_managed_key.main[0].key_vault_key_id == "https://test-kv.vault.usgovcloudapi.net/keys/created-cmk"
    error_message = "Without cmk_key_name, the CMK binding must use the created key's versionless ID."
  }
}
