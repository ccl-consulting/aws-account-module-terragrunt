# Security Baseline Module Variables
# Implementation: Task 5

variable "account_id" {
  description = "AWS account ID where the baseline will be deployed"
  type        = string
}

variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "logging_account_id" {
  description = "ID of the centralized logging account"
  type        = string
}

variable "security_account_id" {
  description = "ID of the centralized security account"
  type        = string
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail"
  type        = bool
  default     = true
}

variable "compliance_standards" {
  description = "List of Security Hub compliance standards to enable"
  type        = list(string)
  default     = ["aws-foundational-security-best-practices"]
}

variable "config_rules" {
  description = "List of AWS Config rule names to deploy"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
