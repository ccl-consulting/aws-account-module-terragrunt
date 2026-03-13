# Account Factory Module
# Main entry point for the Account Factory module
# Implementation: Task 25.1

# This module extends the AWS Landing Zone Terragrunt module to provide
# automated account provisioning with standardized security and networking baselines.

# Terraform and Provider Configuration
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Provider configuration is inherited from the root module
# Multi-region provider aliases are configured for baseline deployment

# Primary provider (management account)
provider "aws" {
  # Configuration inherited from Terragrunt
}

# Provider aliases for multi-region deployment
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}

# Module-level locals for orchestration
locals {
  # Validation flags - these trigger errors if validations fail
  # The validations are defined in locals.tf
  validation_checks = [
    local.validate_required_tags,
    local.validate_allowed_tags,
    local.validate_tag_patterns,
    local.validate_security_baseline_refs,
    local.validate_network_baseline_refs,
    local.validate_ou_references,
    local.validate_production_account_deletion
  ]

  # Account creation summary
  total_accounts = length(var.accounts)
  accounts_with_security_baseline_count = length(local.accounts_with_security_baseline)
  accounts_with_network_baseline_count  = length(local.accounts_with_network_baseline)

  # Baseline deployment summary
  security_baseline_deployments = length(local.accounts_with_security_baseline) * length(var.governed_regions)
  network_baseline_deployments  = sum([
    for name, account in local.accounts_with_network_baseline :
    length(local.account_regions[name])
  ])

  # Update detection summary
  accounts_requiring_security_updates = length(local.accounts_requiring_security_baseline_update)
  accounts_requiring_network_updates  = length(local.accounts_requiring_network_baseline_update)
}

# Validation: Check for duplicate emails
resource "null_resource" "validate_email_uniqueness" {
  count = length(local.duplicate_emails) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Error: Duplicate email addresses found: ${join(", ", local.duplicate_emails)}' && exit 1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Output deployment summary for visibility
output "deployment_summary" {
  description = "Summary of Account Factory deployment"
  value = {
    total_accounts                    = local.total_accounts
    accounts_with_security_baseline   = local.accounts_with_security_baseline_count
    accounts_with_network_baseline    = local.accounts_with_network_baseline_count
    security_baseline_deployments     = local.security_baseline_deployments
    network_baseline_deployments      = local.network_baseline_deployments
    accounts_requiring_security_updates = local.accounts_requiring_security_updates
    accounts_requiring_network_updates  = local.accounts_requiring_network_updates
    governed_regions                  = var.governed_regions
    production_account_protection     = var.enable_production_account_protection
  }
}
