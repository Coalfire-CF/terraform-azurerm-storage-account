terraform {
  required_version = "~> 1.14.9" # matches the module's constraint

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.70"
    }
  }
}

# Auth and environment come entirely from ARM_* env vars exported by org-terratest
# (ARM_USE_OIDC, ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_ENVIRONMENT).
provider "azurerm" {
  features {}
}
