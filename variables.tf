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
  description = "Enable and configure static website on the storage account."
  default     = null
}

variable "virtual_network_subnet_ids" {
  type        = list(string)
  description = "A list of resource ids for subnets to allow access to the storage account."
  default     = null
}

variable "default_action" {
  type        = string
  description = "The default action for network rules. Valid options are 'Allow' or 'Deny'."
  default     = "Deny"
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

variable "https_traffic_only_enabled" {
  type        = bool
  description = "Is HTTPS traffic only enabled?"
  default     = true
}

variable "min_tls_version" {
  type        = string
  description = "The minimum TLS version to be permitted on requests to storage. Possible values include: 'TLS1_0', 'TLS1_1', 'TLS1_2'."
  default     = "TLS1_2"
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  description = "Allow nested items within the storage account to be public."
  default     = false
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
  default     = ["AzureServices", "Logging", "Metrics"]
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether the public network access is enabled."
  default     = true
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Is infrastructure encryption enabled? This provides a second layer of encryption at rest for data in the storage account."
  default     = true
}

variable "cross_tenant_replication_enabled" {
  type        = bool
  description = "Should cross Tenant replication be enabled? Source storage account is in one AAD tenant, and the destination account is in a different tenant."
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
  description = "Subresource name which the private endpoint is able to connect to."
  default     = []
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
  description = "Enable customer-managed key encryption for the storage account"
  type        = bool
  default     = true
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
    change_feed_enabled           = optional(bool, false)
    change_feed_retention_in_days = optional(number, null)
    default_service_version       = optional(string, null)
    last_access_time_enabled      = optional(bool, false)
    versioning_enabled            = optional(bool, false)
    container_delete_retention_policy = optional(object({
      days = number
    }), null)
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), null)
    delete_retention_policy = optional(object({
      days = number
    }), null)
    restore_policy = optional(object({
      days = number
    }), null)
  })
  default     = null
  description = <<-DESCRIPTION
    Blob service properties for advanced features including versioning, soft delete, and CORS configuration.
    
    - change_feed_enabled: Enable change feed for the blob service
    - change_feed_retention_in_days: Retention period in days for change feed (1-146000)
    - default_service_version: Default API version for blob service requests
    - last_access_time_enabled: Enable last access time tracking for lifecycle management
    - versioning_enabled: Enable blob versioning
    - container_delete_retention_policy: Soft delete retention for deleted containers
    - cors_rule: CORS rules for blob service
    - delete_retention_policy: Soft delete retention for deleted blobs (1-365 days)
    - restore_policy: Point-in-time restore configuration (requires versioning and delete retention)
  DESCRIPTION
}