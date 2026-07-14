variable "name" {
  type        = string
  description = "Storage account name (lowercase alphanumeric, 3-24 chars, globally unique)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to create for this test run."
}

variable "location" {
  type        = string
  description = "Azure Government region."
  default     = "usgovvirginia"
}

variable "tags" {
  type        = map(string)
  description = "Tags for all test resources."
  default = {
    purpose = "terratest-self-test"
    repo    = "terraform-azurerm-storage-account"
  }
}
