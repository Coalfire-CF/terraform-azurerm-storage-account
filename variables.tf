variable "name" {
  type        = string
  description = "The storage account name"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{3,24}$", var.name))
    error_message = "Name may only contain alphanumeric characters and must be between 3-24 chars."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the resource in."
}

variable "location" {
  description = "The Azure location/region to create resources in."
  type        = string
}

variable "replication_type" {
  type        = string
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS."
  default     = "ZRS"
}

variable "diag_log_analytics_id" {
  type        = string
  description = "ID of the Log Analytics workspace diag settings should be stored in."
}

variable "account_kind" {
  type        = string
  description = "Account Kind for the Storage Account"
}

variable "account_tier" {
  type        = string
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "static_website" {
  type        = map(string)
  description = "Enable and configure static website on the storage account."
  default     = null
}

variable "virtual_network_subnet_ids" {
  type        = list(string)
  description = "A list of resource ids for subnets to allow access to the storage account."
  default     = null
}

variable "ip_rules" {
  type        = list(string)
  description = "List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges are not allowed."
  default     = null
}

variable "private_link_access" {
  type        = list(string)
  description = "List of the resource ids of the endpoint resource to be granted access."
  default     = []
}

variable "is_hns_enabled" {
  type        = bool
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2."
  default     = false
}

variable "nfsv3_enabled" {
  type        = bool
  description = "Is NFSv3 protocol enabled."
  default     = false
}

variable "network_rules_bypass" {
  type        = list(string)
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether the public network access is enabled."
  default     = false
}

variable "cross_tenant_replication_enabled" {
  type        = bool
  description = "Should cross Tenant replication be enabled? Source storage account is in one AAD tenant, and the destination account is in a different tenant."
  default     = false
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Whether the infrastructure encryption is enabled."
  default     = false
}

variable "tags" {
  description = "The tags to associate with the resources."
  type        = map(string)
}

variable "identity_ids" {
  type        = list(string)
  description = "Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account."
  default     = null
}

variable "storage_containers" {
  type        = list(string)
  description = "List of storage containers to create."
  default     = []
}

variable "storage_shares" {
  type = list(object({
    name  = string
    quota = number
  }))
  description = "List of storage shares to create and their quotas."
  default     = []
}

variable "enable_customer_managed_key" {
  type        = bool
  description = "Whether the storage account should be encrypted with customer managed keys."
  default     = false
}

variable "cmk_key_vault_id" {
  type        = string
  description = "The ID of the Key Vault for Customer Managed Key encryption."
  default     = null
}

variable "enable_advanced_threat_protection" {
  type        = bool
  description = "Whether advanced threat protection is enabled."
  default     = false
}

variable "lifecycle_policies" {
  description = "List of lifecycle policies to apply to the storage account. Refer to the documentation for more information."
  type = list(object({
    prefix_match = set(string)
    base_blob = optional(object({
      tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
      tier_to_archive_after_days_since_modification_greater_than     = optional(number)
      tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
      tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
      delete_after_days_since_modification_greater_than              = optional(number)
      delete_after_days_since_last_access_time_greater_than          = optional(number)
    }))
    version = optional(object({
      tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      change_tier_to_archive_after_days_since_creation               = optional(number)
      tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
      change_tier_to_cool_after_days_since_creation                  = optional(number)
      delete_after_days_since_creation                               = optional(number)
    }))
    snapshot = optional(object({
      change_tier_to_archive_after_days_since_creation               = optional(number)
      tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
      change_tier_to_cool_after_days_since_creation                  = optional(number)
      delete_after_days_since_creation_greater_than                  = optional(number)
    }))
  }))
  default = null
}

variable "endpoint_subnet_id" {
  type        = string
  description = "The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint."
  default     = null
}

variable "private_endpoint_subresource_names" {
  type        = list(string)
  description = "Subresource name which the private endpoint is able to connect to."
  default     = []
}

variable "private_dns_zone_id" {
  type        = string
  description = "The ID of the private DNS zone to link to the private endpoint if applicable."
  default     = null
}