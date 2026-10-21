terraform {
  required_version = ">= 1.16.6, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}

# Auth comes from ARM_* env vars exported by org-terratest
# (ARM_USE_OIDC, ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID).
# The provider block sets the environment.
provider "azurerm" {
  features {}
  environment                     = "usgovernment"
  storage_use_azuread             = true
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Storage", "Microsoft.OperationalInsights", "Microsoft.Insights"]
}
