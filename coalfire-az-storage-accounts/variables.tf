variable "global_tags" {
  type        = map(string)
  description = "Global level tags"
}

variable "regional_tags" {
  type        = map(string)
  description = "Regional level tags"
}
variable "sa_tags" {
  type        = map(string)
  description = "Resource Specific Tags"
}

variable "sa_name" {
  type        = string
  description = "storage account name"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group resource will be deployed in"
}

variable "replication_type" {
  type        = string
  description = "LRS/GRS/ZRS/etc."
}

variable "diag_log_analytics_id" {
  type        = string
  description = "ID of the Log Analytics workspace diag settings should be stored in"
}

variable "account_kind" {
  type        = string
  description = "Account Kind for the Storage Account"
}
