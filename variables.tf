variable "name" {
  type        = string
  description = "The storage account name"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Name may only contain lowercase letters and numbers and must be between 3-24 chars."
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
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Unless you have a specific reason for data without alternate site requirements  you should minimum use ZRS"
  default     = "GRS" # GRS is the default to align with the Azure NIST/FedRAMP Policy

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "diag_log_analytics_id" {
  type        = string
  description = "ID of the Log Analytics workspace diag settings should be stored in."
}

variable "account_kind" {
  type        = string
  description = "Account Kind for the Storage Account"
  default     = "StorageV2"
}

variable "access_tier" {
  type        = string
  default     = "Hot"
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot, Cool, Cold and Premium."
  validation {
    condition     = contains(["Hot", "Cool", "Cold", "Premium"], var.access_tier)
    error_message = "access_tier must be one of: 'Hot', 'Cool', 'Cold', or 'Premium'."
  }
}

variable "account_tier" {
  type        = string
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "static_website" {
  type        = map(string)
  description = "Static website settings (index_document, error_404_document). Static website writes through the blob data plane: with shared keys off, the caller's provider needs storage_use_azuread = true and the runner needs network access to the blob endpoint. Serving content needs public_network_access = Enabled or a web private endpoint."
  default     = null
}

variable "virtual_network_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs allowed through the storage firewall. Applies only when public_network_access is Enabled."
  default     = []
  nullable    = false
}

variable "default_action" {
  type        = string
  description = "Firewall default action when no ip_rules or virtual_network_subnet_ids match. Allow lets any network that can reach the endpoint in. Keep Deny."
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.default_action)
    error_message = "default_action must be 'Allow' or 'Deny'."
  }
}

variable "ip_rules" {
  type        = list(string)
  description = "Public IPv4 addresses or CIDR ranges allowed through the storage firewall. Private ranges are not allowed. Applies only when public_network_access is Enabled."
  default     = []
  nullable    = false
}

variable "private_link_access" {
  type        = list(string)
  description = "List of the resource ids of the endpoint resource to be granted access."
  default     = []
}

variable "https_traffic_only_enabled" {
  type        = bool
  description = "Require HTTPS for all requests. Setting false allows unencrypted HTTP; only NFSv3 accounts need that."
  default     = true
}

variable "min_tls_version" {
  type        = string
  description = "The minimum TLS version for requests to storage. azurerm 5 accepts only TLS1_2."
  default     = "TLS1_2"

  validation {
    condition     = var.min_tls_version == "TLS1_2"
    error_message = "min_tls_version must be TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  description = "Allow containers and blobs to be made public. True lets containers and blobs be made anonymously readable. Keep false."
  default     = false
}

variable "is_hns_enabled" {
  type        = bool
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2. True turns off blob versioning and point-in-time restore."
  default     = false
}

variable "nfsv3_enabled" {
  type        = bool
  description = "Is NFSv3 protocol enabled. NFSv3 authorizes by network only, not Entra ID, and needs https_traffic_only_enabled = false."
  default     = false
}

variable "network_rules_bypass" {
  type        = list(string)
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None."
  default     = ["AzureServices", "Logging", "Metrics"]
}

variable "public_network_access" {
  type        = string
  description = "Public network access to the storage account: Disabled or Enabled. Enabled exposes the service endpoints to the internet, limited only by network_rules. Keep Disabled and use a private endpoint."
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "Enabled"], var.public_network_access)
    error_message = "public_network_access must be 'Disabled' or 'Enabled'."
  }
}

variable "shared_access_key_enabled" {
  type        = bool
  description = "Allow Shared Key (account key and key-signed SAS) authorization. True lets anyone holding a key bypass Entra ID and RBAC. Keep false unless a caller must use a key."
  default     = false
}

variable "local_user_enabled" {
  type        = bool
  description = "Allow SFTP and other local users. True adds password or SSH key identities outside Entra ID. Keep false."
  default     = false
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Infrastructure encryption: a second layer of encryption at rest. False removes the second encryption layer at rest (R12). Keep true."
  default     = true
}

variable "cross_tenant_replication_enabled" {
  type        = bool
  description = "Should cross Tenant replication be enabled? True lets data replicate to a storage account in another Entra tenant. Keep false."
  default     = false
}

variable "tags" {
  description = "The tags to associate with the resources."
  type        = map(string)
}

variable "enable_system_assigned_identity" {
  type        = bool
  default     = true
  description = "Enable system-assigned managed identity"
}

variable "identity_ids" {
  type        = list(string)
  default     = null
  description = "List of user-assigned managed identity IDs"
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
  description = "The one storage subresource the private endpoint connects to: blob, blob_secondary, dfs, dfs_secondary, file, queue, queue_secondary, table, table_secondary, web or web_secondary."
  default     = ["blob"]

  validation {
    condition     = length(var.private_endpoint_subresource_names) == 1
    error_message = "private_endpoint_subresource_names must hold exactly one subresource."
  }
}

variable "private_dns_zone_id" {
  type        = string
  description = "The ID of the private DNS zone to link to the private endpoint if applicable."
  default     = null
}

### KV CMK KEY VARIABLES ###
variable "cmk_key_name" {
  description = "Name of an existing Key Vault key to use for customer-managed encryption. If null, a new key will be created when enable_customer_managed_key is true."
  type        = string
  default     = null
}

variable "enable_customer_managed_key" {
  description = "Use a customer-managed key in Key Vault. Needs cmk_key_vault_id and enable_system_assigned_identity = true. When false, platform-managed keys plus infrastructure encryption apply."
  type        = bool
  default     = false
}

variable "cmk_key_vault_id" {
  description = "The ID of the Key Vault where the CMK key is or will be stored"
  type        = string
  default     = null
}

variable "cmk_key_type" {
  description = "The type of key to create for CMK. Use 'RSA-HSM' for FedRAMP High or 'RSA' for standard"
  type        = string
  default     = "RSA"
}

variable "cmk_key_size" {
  description = "The size of the RSA key for CMK"
  type        = number
  default     = 4096
}

variable "cmk_rotation_policy_enabled" {
  description = "Enable automatic rotation policy for the CMK key"
  type        = bool
  default     = true
}

variable "cmk_rotation_expire_after" {
  description = "Duration after which the key will expire (ISO 8601 format, e.g., P180D for 180 days)"
  type        = string
  default     = "P180D"
}

variable "cmk_rotation_time_before_expiry" {
  description = "Time before expiry when rotation should occur (ISO 8601 format, e.g., P30D for 30 days)"
  type        = string
  default     = "P30D"
}

## Blob Service Properties Variable ##
variable "blob_properties" {
  type = object({
    change_feed_enabled           = optional(bool)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool, false)
    versioning_enabled            = optional(bool)
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), [])
  })
  default     = {}
  nullable    = false
  description = <<-DESCRIPTION
    Optional blob service features. Soft delete is set by blob_delete_retention_days and container_delete_retention_days. Setting versioning_enabled or change_feed_enabled to false where point-in-time restore applies fails the plan unless point_in_time_restore_enabled = false.

    - change_feed_enabled: Change feed. Null means on when point-in-time restore applies, else off.
    - change_feed_retention_in_days: Retention period in days for change feed (1-146000)
    - default_service_version: Default API version for blob service requests
    - last_access_time_enabled: Enable last access time tracking for lifecycle management
    - versioning_enabled: Blob versioning. Null means on when point-in-time restore applies, else off. Not allowed with is_hns_enabled.
    - cors_rule: CORS rules for blob service
  DESCRIPTION
}

variable "blob_delete_retention_days" {
  type        = number
  description = "Days deleted blobs are kept (blob soft delete). Not applied when account_kind is FileStorage. Lower values shorten the window to recover deleted data."
  default     = 7
  nullable    = false

  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "blob_delete_retention_days must be between 1 and 365."
  }
}

variable "container_delete_retention_days" {
  type        = number
  description = "Days deleted containers are kept (container soft delete). Not applied when account_kind is FileStorage. Lower values shorten the window to recover deleted data."
  default     = 7
  nullable    = false

  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365
    error_message = "container_delete_retention_days must be between 1 and 365."
  }
}

variable "share_delete_retention_days" {
  type        = number
  description = "Days deleted file shares are kept (share soft delete). Applied where the account has a file service (Standard StorageV2, FileStorage, and Standard Storage with LRS, GRS or RAGRS). Lower values shorten the window to recover deleted data."
  default     = 7
  nullable    = false

  validation {
    condition     = var.share_delete_retention_days >= 1 && var.share_delete_retention_days <= 365
    error_message = "share_delete_retention_days must be between 1 and 365."
  }
}

variable "point_in_time_restore_enabled" {
  type        = bool
  description = "Blob point-in-time restore. Applies only to Standard StorageV2 accounts without is_hns_enabled; other accounts ignore it. Turns on blob versioning and change feed unless blob_properties sets them. False also leaves versioning and change feed off unless blob_properties sets them, so overwritten or deleted blobs cannot be rolled back."
  default     = true
  nullable    = false
}

variable "point_in_time_restore_days" {
  type        = number
  description = "Days that point-in-time restore can go back. Must be below blob_delete_retention_days."
  default     = 6
  nullable    = false

  validation {
    condition     = var.point_in_time_restore_days >= 1 && var.point_in_time_restore_days <= 364
    error_message = "point_in_time_restore_days must be between 1 and 364."
  }
}
