# Basic Account Factory Configuration Example
# Implementation: Task 23.1

# This example demonstrates basic account creation with security and network baselines
# for development, staging, and production environments

terraform {
  source = "..//account-factory"
}

# Include root terragrunt configuration
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # Management account configuration
  management_account_id = "123456789012"
  logging_account_id    = "123456789013"
  security_account_id   = "123456789014"

  # Governed regions for baseline deployment
  governed_regions = ["us-east-1", "us-west-2"]

  # Organizational unit mapping
  existing_ou_ids = {
    "Development" = "ou-xxxx-11111111"
    "Staging"     = "ou-xxxx-22222222"
    "Production"  = "ou-xxxx-33333333"
  }

  # Production OU protection
  production_ou_ids = ["ou-xxxx-33333333"]
  enable_production_account_protection = true

  # Default tags applied to all accounts
  default_tags = {
    ManagedBy   = "AccountFactory"
    Terraform   = "true"
    Environment = "managed"
  }

  # Required tags for all accounts
  required_tags = ["Owner", "Environment", "CostCenter"]

  # Security baseline configuration
  security_baselines = {
    default = {
      version              = "1.0.0"
      enable_security_hub  = true
      enable_guardduty     = true
      enable_config        = true
      enable_cloudtrail    = true
      compliance_standards = [
        "aws-foundational-security-best-practices",
        "cis-aws-foundations-benchmark/v/1.4.0"
      ]
    }
  }

  # Network baseline configuration
  network_baselines = {
    standard = {
      version                = "1.0.0"
      vpc_cidr               = "10.0.0.0/16"
      availability_zones     = 3
      enable_transit_gateway = true
      enable_flow_logs       = true
    }
  }

  # Account definitions
  accounts = {
    dev-application = {
      email               = "aws-dev-app@example.com"
      organizational_unit = "Development"
      security_baseline   = "default"
      network_baseline    = "standard"
      baseline_version    = "latest"
      regions             = ["us-east-1"]
      tags = {
        Owner       = "dev-team@example.com"
        Environment = "development"
        CostCenter  = "engineering"
        Application = "web-app"
      }
      close_on_deletion  = false
      delegated_services = []
    }

    staging-application = {
      email               = "aws-staging-app@example.com"
      organizational_unit = "Staging"
      security_baseline   = "default"
      network_baseline    = "standard"
      baseline_version    = "latest"
      regions             = ["us-east-1", "us-west-2"]
      tags = {
        Owner       = "platform-team@example.com"
        Environment = "staging"
        CostCenter  = "engineering"
        Application = "web-app"
      }
      close_on_deletion  = false
      delegated_services = []
    }

    prod-application = {
      email               = "aws-prod-app@example.com"
      organizational_unit = "Production"
      security_baseline   = "default"
      network_baseline    = "standard"
      baseline_version    = "latest"
      regions             = ["us-east-1", "us-west-2"]
      tags = {
        Owner       = "platform-team@example.com"
        Environment = "production"
        CostCenter  = "engineering"
        Application = "web-app"
      }
      close_on_deletion  = false
      delegated_services = []
    }
  }

  # Service Control Policies
  service_control_policies = {}

  # Integration with existing Landing Zone
  use_existing_control_tower_roles = false
  existing_transit_gateway_id      = ""
}
