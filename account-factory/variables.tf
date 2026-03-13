# Account Definitions
variable "accounts" {
  description = "Map of accounts to create with their configurations"
  type = map(object({
    email               = string
    organizational_unit = string
    security_baseline   = optional(string, "default")
    network_baseline    = optional(string, "none")
    baseline_version    = optional(string, "latest")
    regions             = optional(list(string), [])
    tags                = optional(map(string), {})
    close_on_deletion   = optional(bool, false)
    delegated_services  = optional(list(string), [])
  }))
  default = {}

  # Email format validation
  validation {
    condition     = alltrue([for name, account in var.accounts : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", account.email))])
    error_message = "All account email addresses must be valid email format."
  }

  # Email uniqueness validation
  validation {
    condition = length(var.accounts) == 0 || length([
      for email in [for name, account in var.accounts : account.email] :
      email if length([for e in [for n, a in var.accounts : a.email] : e if e == email]) > 1
    ]) == 0
    error_message = "All account email addresses must be unique. Duplicate emails found in accounts configuration."
  }

  # Organizational unit reference validation (when existing_ou_ids is provided)
  validation {
    condition = alltrue([
      for name, account in var.accounts :
      # Allow both OU IDs (ou-xxxx format) and OU names that will be resolved via existing_ou_ids
      can(regex("^ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", account.organizational_unit)) ||
      can(regex("^r-[a-z0-9]{4,32}$", account.organizational_unit)) || # Root OU format
      length(account.organizational_unit) > 0                          # OU name that should be in existing_ou_ids
    ])
    error_message = "All organizational_unit values must be either valid OU IDs (ou-xxxx format), root ID (r-xxxx format), or OU names that exist in existing_ou_ids variable."
  }
}

# Baseline Configurations
variable "security_baselines" {
  description = "Security baseline template definitions"
  type = map(object({
    version              = string
    enable_security_hub  = optional(bool, true)
    enable_guardduty     = optional(bool, true)
    enable_config        = optional(bool, true)
    enable_cloudtrail    = optional(bool, true)
    compliance_standards = optional(list(string), ["aws-foundational-security-best-practices"])
    config_rules         = optional(list(string), [])
  }))
  default = {
    default = {
      version = "1.0.0"
    }
  }
}

variable "network_baselines" {
  description = "Network baseline template definitions"
  type = map(object({
    version                = string
    vpc_cidr               = string
    availability_zones     = number
    enable_transit_gateway = optional(bool, true)
    enable_flow_logs       = optional(bool, true)
    subnet_configuration = optional(object({
      public_subnets   = optional(list(string), [])
      private_subnets  = optional(list(string), [])
      isolated_subnets = optional(list(string), [])
    }), {})
  }))
  default = {}
}

# Service Control Policies
variable "service_control_policies" {
  description = "Service Control Policies to apply to accounts or OUs"
  type = map(object({
    description = string
    policy      = string
    targets     = list(string) # Account IDs or OU IDs
  }))
  default = {}

  # JSON policy syntax validation
  validation {
    condition     = alltrue([for name, scp in var.service_control_policies : can(jsondecode(scp.policy))])
    error_message = "All Service Control Policy documents must be valid JSON."
  }

  # Policy target validation (account IDs or OU IDs)
  validation {
    condition = alltrue([
      for name, scp in var.service_control_policies :
      alltrue([
        for target in scp.targets :
        can(regex("^\\d{12}$", target)) ||                          # 12-digit account ID
        can(regex("^ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", target)) || # OU ID format
        can(regex("^r-[a-z0-9]{4,32}$", target))                    # Root ID format
      ])
    ])
    error_message = "All SCP targets must be valid AWS account IDs (12 digits), OU IDs (ou-xxxx format), or root IDs (r-xxxx format)."
  }
}

# Integration with existing Landing Zone
variable "existing_ou_ids" {
  description = "Map of existing organizational unit names to IDs"
  type        = map(string)
  default     = {}
}

variable "logging_account_id" {
  description = "ID of the centralized logging account"
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.logging_account_id))
    error_message = "Logging account ID must be a 12-digit AWS account ID."
  }
}

variable "security_account_id" {
  description = "ID of the centralized security account"
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.security_account_id))
    error_message = "Security account ID must be a 12-digit AWS account ID."
  }
}

variable "governed_regions" {
  description = "List of AWS regions where baselines will be deployed"
  type        = list(string)

  validation {
    condition     = length(var.governed_regions) > 0
    error_message = "At least one governed region must be specified."
  }
}

variable "management_account_id" {
  description = "ID of the AWS Organizations management account"
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.management_account_id))
    error_message = "Management account ID must be a 12-digit AWS account ID."
  }
}

# Tagging
variable "default_tags" {
  description = "Default tags applied to all accounts and resources"
  type        = map(string)
  default = {
    "ManagedBy" = "AccountFactory"
  }
}

variable "required_tags" {
  description = "List of tag keys that must be present on all accounts"
  type        = list(string)
  default     = ["Owner", "Environment", "CostCenter"]
}

variable "custom_tag_schema" {
  description = "Custom tag schema for validation. If provided, overrides default required_tags validation."
  type = object({
    required_keys = optional(list(string), [])
    allowed_keys  = optional(list(string), [])
    key_patterns  = optional(map(string), {}) # Map of tag key to regex pattern for value validation
  })
  default = {
    required_keys = []
    allowed_keys  = []
    key_patterns  = {}
  }
}

variable "baseline_default_tags" {
  description = "Default tags to apply to baseline resources (merged with account tags)"
  type        = map(string)
  default = {
    "DeployedBy" = "AccountFactory"
  }
}

# Account Lifecycle Management
variable "suspended_ou_id" {
  description = "ID of the Suspended organizational unit where removed accounts are moved"
  type        = string
  default     = ""

  validation {
    condition     = var.suspended_ou_id == "" || can(regex("^ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", var.suspended_ou_id))
    error_message = "Suspended OU ID must be empty or a valid OU ID (ou-xxxx format)."
  }
}

variable "production_ou_ids" {
  description = "List of OU IDs that contain production accounts requiring additional deletion protection"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ou_id in var.production_ou_ids :
      can(regex("^ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", ou_id))
    ])
    error_message = "All production OU IDs must be valid OU IDs (ou-xxxx format)."
  }
}

variable "enable_production_account_protection" {
  description = "Enable additional validation to prevent accidental deletion of production accounts"
  type        = bool
  default     = true
}

# Integration with existing Landing Zone resources
variable "use_existing_control_tower_roles" {
  description = "Use existing Control Tower StackSet roles instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_transit_gateway_id" {
  description = "ID of existing Transit Gateway to use for network baseline attachments"
  type        = string
  default     = ""

  validation {
    condition     = var.existing_transit_gateway_id == "" || can(regex("^tgw-[a-z0-9]{17}$", var.existing_transit_gateway_id))
    error_message = "Transit Gateway ID must be empty or a valid TGW ID (tgw-xxxxxxxxxxxxxxxxx format)."
  }
}

variable "existing_cloudtrail_bucket_name" {
  description = "Name of existing S3 bucket for CloudTrail logs"
  type        = string
  default     = ""
}

variable "existing_flow_logs_bucket_name" {
  description = "Name of existing S3 bucket for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "existing_log_group_name" {
  description = "Name of existing CloudWatch Log Group for centralized logging"
  type        = string
  default     = ""
}
