resource "azurerm_storage_account" "sa" {
  name                = var.sa_name
  resource_group_name = var.resource_group_name

  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  account_kind                    = var.account_kind

  identity {
    type = "SystemAssigned"
  }

  # lifecycle {
  #   prevent_destroy = var.prevent_destroy
  #   ignore_changes = [
  #     customer_managed_key # required by https://github.com/hashicorp/terraform-provider-azurerm/issues/16085
  #   ]
  # }

  # network_rules {
  #   default_action             = "Deny"
  #   ip_rules                   = ["100.0.0.1"]
  #   virtual_network_subnet_ids = [azurerm_subnet.example.id]
  # }

  tags = merge(var.global_tags, var.regional_tags, var.sa_tags)
}

module "diag" {
  source                = "github.com/Coalfire-CF/ACE-Azure-Diaganostics?ref=v1.0.1"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_storage_account.sa.id
  resource_type         = "sa"
}
