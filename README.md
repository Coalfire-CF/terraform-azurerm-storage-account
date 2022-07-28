# Coalfire Azure Storage Account

## Description

Use this module to create a V2 Storage Account.

### Versions

Terraform: 1.1.7
AzureRM Provider: 3.4.1
Validated Cloud: Government
FedRAMP Compliance Level: Mod/High
DoD Impact Compliance Level: -
Other Compliance Levels: -

## Resource List

These are the resources that this module supports:

- X

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| global_tags | Global Tags | map(string) | - | yes |
| regional_tags | Regional Tags | map(string) | none | yes |
| sa_tags | Tags specific to the Storage Account | map(string)| | |
| sa_name | Name of the Storage Account | string | - | yes |
| location | Region SA will be deployed in | - | string | yes |
| resource_group_name | Azure Resource Group resource will be deployed in | string | - | yes |
| replication_type | LRS/GRS/ZRS/etc. | string | - | yes |
| diag_log_analytics_id | | string | - | yes |
| account_kind | Storage Account Type  | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| sa_name | Name of the Storage Account|
| sa_id | Resource ID of the Storage Account|
| sa_managed_id | Azure System Managed ID for the Storage Account|
| sa_primary_connection_string | Storage Account primary connection string |
| sa_primary_access_key | Storage Account Primary Access Key |

## Usage

```hcl
module "install_blob" {
  source = "github.com/Coalfire-CF/ACE-Azure-Diagnostics?ref=vX.X.X"

  sa_name               = "installsa"
  resource_group_name   = data.terraform_remote_state.setup.outputs.management_rg_name
  replication_type      = "LRS"
  account_kind          = "StorageV2"
  diag_log_analytics_id = data.terraform_remote_state.core.outputs.core_la_id
  location              = var.location
  global_tags           = var.global_tags
  regional_tags         = var.regional_tags
  sa_tags = {
    Function = "CICD"
    Plane    = "Management"
  }
}
```
