# Coalfire Storage Account

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
      quota = 50
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
