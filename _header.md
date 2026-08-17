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
- CMK key and RBAC Role Assignment (CMK Key can either be inputted into module or created dynamically with the Storage Account)
- Monitor diagnostic setting

## Usage

Please review the variables.tf to review the default CMK key created as it can be changed to fit different compliance of environments. Additionally, do not set variable 'cmk_key_name' if you want a CMK to be dynamically created for the Storage Account.

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
  source                    = "github.com/Coalfire-CF/terraform-azurerm-storage-account?ref=v1.2.11"
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
  cmk_key_name                  = azurerm_key_vault_key.tfstate_cmk.name #Define if you want to have already created CMK set for the Storage Account
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

