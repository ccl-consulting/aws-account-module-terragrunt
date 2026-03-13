# Security Baseline Module
# This module defines the security baseline configuration for member accounts
# Implementation: Task 5
#
# This module deploys a comprehensive security baseline to AWS accounts including:
# - IAM roles for cross-account access, security tooling, and break-glass access
# - AWS Security Hub with compliance standards
# - Amazon GuardDuty with findings export
# - AWS Config with compliance rules
# - AWS CloudTrail with log file validation
#
# Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Data sources for current region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Component files:
# - iam.tf: IAM roles for cross-account access, security tooling, and break-glass
# - security-hub.tf: Security Hub configuration with compliance standards
# - guardduty.tf: GuardDuty detector with findings export
# - config.tf: AWS Config recorder, delivery channel, and compliance rules
# - cloudtrail.tf: CloudTrail with log file validation and CloudWatch integration
