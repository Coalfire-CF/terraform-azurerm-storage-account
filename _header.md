![Coalfire](coalfire_logo.png)

# terraform-azurerm-storage-account

## Description

This module manages an Azure Storage Account, lifecycle policies, containers and storage shares. It is used in the [Coalfire-Azure-RAMPpak](https://github.com/Coalfire-CF/Coalfire-Azure-RAMPpak) FedRAMP Framework.

Learn more at [Coalfire OpenSource](https://coalfire.com/opensource).

## Dependencies

- Security-Core

## Resource List

- Storage Account
- Containers
- Storage share
- Lifecycle policy
- Optional CMK key and RBAC role assignment (the key can be passed in or created by the module)
- Monitor diagnostic setting

## Usage

The module creates no customer-managed key by default. Set `enable_customer_managed_key = true` to encrypt with a key in Key Vault. Leave `cmk_key_name` unset to have the module create the key, or set it to use an existing key.

This module can be called as outlined below.

- Create a `local` folder under `terraform/azure`.
- Create a `main.tf` file in the `local` folder.
- Copy the code below into `main.tf`.
- From the `terraform/azure/local` directory run `terraform init`.
- Run `terraform plan` to review the resources being created.
- If everything looks correct in the plan output, run `terraform apply`.

```hcl
provider "azurerm" {
  features {}
  environment         = "usgovernment"
  storage_use_azuread = true
}

module "core_sa" {
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-storage-account?ref=v3.0.0"
  name                  = "${replace(var.resource_prefix, "-", "")}tfstatesa"
  resource_group_name   = azurerm_resource_group.management.name
  location              = var.location
  account_kind          = "StorageV2"
  diag_log_analytics_id = azurerm_log_analytics_workspace.core-la.id
  tags                  = var.tags

  # Private endpoint. Public network access is Disabled by default.
  endpoint_subnet_id                 = var.pe_subnet_id
  private_dns_zone_id                = var.blob_private_dns_zone_id
  private_endpoint_subresource_names = ["blob"]

  storage_containers = [
    "tfstate"
  ]
  storage_shares = [
    {
      name  = "test"
      quota = 500
    }
  ]
  lifecycle_policies = [
    {
      prefix_match = ["tfstate"]
      version = {
        delete_after_days_since_creation = 90
      }
    }
  ]

  # OPTIONAL: customer-managed key
  enable_customer_managed_key = true
  cmk_key_vault_id            = module.core_kv.id
  cmk_key_name                = azurerm_key_vault_key.tfstate_cmk.name # Omit to have the module create the key
}
```

## Secure defaults

- Public network access is `Disabled`. The firewall default action is `Deny`, with no IPs or subnets allowed.
- Shared keys and local users are off. Requests use Entra ID authorization by default.
- TLS 1.2 and HTTPS only.
- Anonymous blob access is off.
- Infrastructure encryption is on. A customer-managed key is optional. It needs a Key Vault and the system-assigned identity.
- Blob, container and share soft delete keep deleted data for 7 days.
- On Standard StorageV2 without HNS, blob versioning, change feed and point-in-time restore (6 days) are on by default. Set `point_in_time_restore_enabled = false` to turn them off.
- HNS, Premium and other account kinds keep soft delete only.
- Change feed keeps data until `blob_properties.change_feed_retention_in_days` is set.
- Replication is GRS by default for an alternate site. Use `replication_type` for ZRS or GZRS.

`primary_access_key` and `primary_connection_string` exist for callers that must use Shared Key (for example a SAS for a VM diagnostics extension). They are sensitive and null unless `shared_access_key_enabled = true`.

## Static website

`static_website` writes through the blob data plane. With shared keys off (the default), the caller's azurerm provider must set `storage_use_azuread = true`, and the runner must reach the blob endpoint (a private endpoint, or `public_network_access = "Enabled"` with the runner's IP in `ip_rules`).

To serve the site, set `public_network_access = "Enabled"` with firewall rules, or add a private endpoint for the `web` subresource. The defaults do not serve a public site.

## Supported account kinds

Until terraform-azurerm-diagnostics accepts an account kind or a service list, only Standard StorageV2 (and Standard Storage v1 with LRS, GRS or RAGRS) are expected to apply. The diagnostics module targets the blob, queue, table and file services on every account, and other kinds lack some of them.
