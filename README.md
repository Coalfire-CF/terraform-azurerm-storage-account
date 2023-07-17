# Coalfire Azure Storage Account Module

## Description

This module manages an Azure storage account, lifecycle policies, containers and storage shares.

## Resource List

- Storage Account
- Containers
- Storage share
- Lifecycle policy
- CMK key and Iam Role Assignment
- Monitor diagnostic setting

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| name | The storage account name | string | N/A | yes |
| resource_group_name | The name of the resource group in which to create the resource in | string | N/A | yes |
| location | The Azure location/region to create resources in | string | N/A | yes |
| account_kind | Account Kind for the Storage Account | string | N/A | yes |
| diag_log_analytics_id | ID of the Log Analytics Workspace diagnostic logs should be sent to | string | N/A | yes |
| tags | The tags to associate with the resources | map(string) | N/A | yes |
| replication_type | Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS | string | ZRS | no |
| account_tier | Defines the Tier to use for this storage account. Valid options are Standard and Premium | string | Standard | no |
| virtual_network_subnet_ids | A list of resource ids for subnets to allow access to the storage account | list(string) | null | no |
| static_website | Enable and configure static website on the storage account | map(string) | null | no |
| ip_rules | List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges are not allowed | list(string) | null | no |
| private_link_access | List of the resource ids of the endpoint resource to be granted access | list(string) | [] | no |
| is_hns_enabled | Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 | bool | false | no |
| nfsv3_enabled | Is NFSv3 protocol enabled | bool | false | no |
| network_rules_bypass | Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None. | list(string) | null | no |
| public_network_access_enabled | Whether the public network access is enabled | bool | false | no |
| infrastructure_encryption_enabled | Whether the infrastructure encryption is enabled | bool | false | no |
| cross_tenant_replication_enabled | Should cross Tenant replication be enabled? Source storage account is in one AAD tenant, and the destination account is in a different tenant | bool | false | no |
| identity_ids | Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account | list(string) | null | no |
| storage_containers | List of storage containers to create | list(string) | [] | no |
| storage_shares | List of storage shares to create and their quotas | list(string) | [] | no |
| enable_customer_managed_key | Whether the storage account should be encrypted with customer managed keys | bool | false | no |
| cmk_key_vault_id | The ID of the Key Vault for Customer Managed Key encryption | string | null | no |
| enable_advanced_threat_protection | Whether advanced threat protection is enabled | bool | false | no |
| lifecycle_policies | List of lifecycle policies to apply to the storage account. Refer to the documentation to more information | list(object({prefix_match = set(string),base_blob = optional(object({})),optional(version = object({})),optional(snapshot = object({}))})) | no |
| endpoint_subnet_id | The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint | string | null | no |
| private_endpoint_subresource_names | Subresource name which the private endpoint is able to connect to | list(string) | [] | no |
| private_dns_zone_id | The ID of the private DNS zone to link to the private endpoint if applicable | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| name | Storage Account Name |
| id | Storage Account ID |
| managed_principal_id | System Assigned Managed Identity for the Storage Account |
| primary_connection_string | Primary SA connection string |
| primary_access_key | The primary access key for the storage account |
| primary_blob_endpoint | The primary blob endpoint for the storage account |
| primary_web_endpoint | The primary web endpoint for the storage account |
| storage_shares_ids | Map with storage share ids |

## Usage

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
}

module "core_sa" {
  source                    = "github.com/Coalfire-CF/ACE-Azure-StorageAccount?ref=vX.X.X"
  name                       = "${replace(var.resource_prefix, "-", "")}tfstatesa"
  resource_group_name        = azurerm_resource_group.management.name
  location                   = var.location
  account_kind               = "StorageV2"
  ip_rules                   = var.ip_for_remote_access
  diag_log_analytics_id      = azurerm_log_analytics_workspace.core-la.id
  virtual_network_subnet_ids = var.fw_virtual_network_subnet_ids
  tags                       = var.tags

  #OPTIONAL
  public_network_access_enabled = true
  enable_customer_managed_key   = true
  cmk_key_vault_id              = module.core_kv.id
  cmk_key_vault_key_name        = azurerm_key_vault_key.tfstate-cmk.name
  storage_containers = [
    "tfstate"
  ]
  storage_shares = [
    {
      name = "test"
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
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_diag"></a> [diag](#module\_diag) | github.com/Coalfire-CF/ACE-Azure-Diagnostics | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_advanced_threat_protection.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/advanced_threat_protection) | resource |
| [azurerm_key_vault_key.cmk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) | resource |
| [azurerm_private_endpoint.sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.sa_crypto_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_customer_managed_key.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_customer_managed_key) | resource |
| [azurerm_storage_container.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_management_policy.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |
| [azurerm_storage_share.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_kind"></a> [account\_kind](#input\_account\_kind) | Account Kind for the Storage Account | `string` | `"Storagev2"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Defines the Tier to use for this storage account. Valid options are Standard and Premium. | `string` | `"Standard"` | no |
| <a name="input_cmk_key_vault_id"></a> [cmk\_key\_vault\_id](#input\_cmk\_key\_vault\_id) | The ID of the Key Vault for Customer Managed Key encryption. | `string` | `null` | no |
| <a name="input_cross_tenant_replication_enabled"></a> [cross\_tenant\_replication\_enabled](#input\_cross\_tenant\_replication\_enabled) | Should cross Tenant replication be enabled? Source storage account is in one AAD tenant, and the destination account is in a different tenant. | `bool` | `false` | no |
| <a name="input_diag_log_analytics_id"></a> [diag\_log\_analytics\_id](#input\_diag\_log\_analytics\_id) | ID of the Log Analytics workspace diag settings should be stored in. | `string` | n/a | yes |
| <a name="input_enable_advanced_threat_protection"></a> [enable\_advanced\_threat\_protection](#input\_enable\_advanced\_threat\_protection) | Whether advanced threat protection is enabled. | `bool` | `false` | no |
| <a name="input_enable_customer_managed_key"></a> [enable\_customer\_managed\_key](#input\_enable\_customer\_managed\_key) | Whether the storage account should be encrypted with customer managed keys. | `bool` | `false` | no |
| <a name="input_endpoint_subnet_id"></a> [endpoint\_subnet\_id](#input\_endpoint\_subnet\_id) | The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. | `string` | `null` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account. | `list(string)` | `null` | no |
| <a name="input_ip_rules"></a> [ip\_rules](#input\_ip\_rules) | List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges are not allowed. | `list(string)` | `null` | no |
| <a name="input_is_hns_enabled"></a> [is\_hns\_enabled](#input\_is\_hns\_enabled) | Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2. | `bool` | `false` | no |
| <a name="input_lifecycle_policies"></a> [lifecycle\_policies](#input\_lifecycle\_policies) | List of lifecycle policies to apply to the storage account. Refer to the documentation for more information. | <pre>list(object({<br>    prefix_match = set(string)<br>    base_blob = optional(object({<br>      tier_to_cool_after_days_since_modification_greater_than        = optional(number)<br>      tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)<br>      tier_to_archive_after_days_since_modification_greater_than     = optional(number)<br>      tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)<br>      tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br>      delete_after_days_since_modification_greater_than              = optional(number)<br>      delete_after_days_since_last_access_time_greater_than          = optional(number)<br>    }))<br>    version = optional(object({<br>      tier_to_cool_after_days_since_modification_greater_than        = optional(number)<br>      change_tier_to_archive_after_days_since_creation               = optional(number)<br>      tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br>      change_tier_to_cool_after_days_since_creation                  = optional(number)<br>      delete_after_days_since_creation                               = optional(number)<br>    }))<br>    snapshot = optional(object({<br>      change_tier_to_archive_after_days_since_creation               = optional(number)<br>      tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br>      change_tier_to_cool_after_days_since_creation                  = optional(number)<br>      delete_after_days_since_creation_greater_than                  = optional(number)<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure location/region to create resources in. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The storage account name | `string` | n/a | yes |
| <a name="input_network_rules_bypass"></a> [network\_rules\_bypass](#input\_network\_rules\_bypass) | Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None. | `list(string)` | `null` | no |
| <a name="input_nfsv3_enabled"></a> [nfsv3\_enabled](#input\_nfsv3\_enabled) | Is NFSv3 protocol enabled. | `bool` | `false` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | The ID of the private DNS zone to link to the private endpoint if applicable. | `string` | `null` | no |
| <a name="input_private_endpoint_subresource_names"></a> [private\_endpoint\_subresource\_names](#input\_private\_endpoint\_subresource\_names) | Subresource name which the private endpoint is able to connect to. | `list(string)` | `[]` | no |
| <a name="input_private_link_access"></a> [private\_link\_access](#input\_private\_link\_access) | List of the resource ids of the endpoint resource to be granted access. | `list(string)` | `[]` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether the public network access is enabled. | `bool` | `false` | no |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Unless you have a specific reason for data without alternate site requirements  you should minimum use ZRS | `string` | `"GRS"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the resource in. | `string` | n/a | yes |
| <a name="input_static_website"></a> [static\_website](#input\_static\_website) | Enable and configure static website on the storage account. | `map(string)` | `null` | no |
| <a name="input_storage_containers"></a> [storage\_containers](#input\_storage\_containers) | List of storage containers to create. | `list(string)` | `[]` | no |
| <a name="input_storage_shares"></a> [storage\_shares](#input\_storage\_shares) | List of storage shares to create and their quotas. | <pre>list(object({<br>    name  = string<br>    quota = number<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to associate with the resources. | `map(string)` | n/a | yes |
| <a name="input_virtual_network_subnet_ids"></a> [virtual\_network\_subnet\_ids](#input\_virtual\_network\_subnet\_ids) | A list of resource ids for subnets to allow access to the storage account. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_ids"></a> [container\_ids](#output\_container\_ids) | The IDs of the storage containers |
| <a name="output_container_names"></a> [container\_names](#output\_container\_names) | The names of the storage containers |
| <a name="output_id"></a> [id](#output\_id) | Storage Account ID. |
| <a name="output_managed_principal_id"></a> [managed\_principal\_id](#output\_managed\_principal\_id) | System Assigned Managed Identity for the Storage Account. |
| <a name="output_name"></a> [name](#output\_name) | Storage Account Name. |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | The primary access key for the storage account. |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | The primary blob endpoint for the storage account. |
| <a name="output_primary_connection_string"></a> [primary\_connection\_string](#output\_primary\_connection\_string) | Primary SA connection string. |
| <a name="output_primary_web_endpoint"></a> [primary\_web\_endpoint](#output\_primary\_web\_endpoint) | The primary web endpoint for the storage account. |
| <a name="output_storage_shares_ids"></a> [storage\_shares\_ids](#output\_storage\_shares\_ids) | Map with storage share ids. |
<!-- END_TF_DOCS -->