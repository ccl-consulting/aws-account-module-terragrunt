# Multi-Account Configuration Example
# Implementation: Task 23.2

# This example demonstrates managing 10+ accounts using Terragrunt for_each patterns,
# configuration inheritance with include blocks, and account grouping by environment

terraform {
  source = "..//account-factory"
}

# Include root terragrunt configuration
include "root" {
  path = find_in_parent_folders()
}

# Local variables for account generation
locals {
  # Define environments and their configurations
  environments = {
    dev = {
      ou_id           = "ou-xxxx-11111111"
      vpc_cidr_prefix = "10.0"
      cost_center     = "engineering"
    }
    staging = {
      ou_id           = "ou-xxxx-22222222"
      vpc_cidr_prefix = "10.1"
      cost_center     = "engineering"
    }
    prod = {
      ou_id           = "ou-xxxx-33333333"
      vpc_cidr_prefix = "10.2"
      cost_center     = "operations"
    }
  }

  # Define applications
  applications = ["web-app", "api", "data-pipeline", "analytics"]

  # Generate accounts for each environment and application combination
  accounts = merge([
    for env_name, env_config in local.environments : {
      for app in local.applications :
      "${env_name}-${app}" => {
        email               = "aws-${env_name}-${app}@example.com"
        organizational_unit = env_config.ou_id
        security_baseline   = "default"
        network_baseline    = "standard"
        baseline_version    = "latest"
        regions             = env_name == "prod" ? ["us-east-1", "us-west-2"] : ["us-east-1"]
        tags = {
          Owner       = "${app}-team@example.com"
          Environment = env_name
          CostCenter  = env_config.cost_center
          Application = app
        }
        close_on_deletion  = false
        delegated_services = []
      }
    }
  ]...)
}

inputs = {
  # Management account configuration
  management_account_id = "123456789012"
  logging_account_id    = "123456789013"
  security_account_id   = "123456789014"

  # Governed regions
  governed_regions = ["us-east-1", "us-west-2"]

  # Organizational unit mapping
  existing_ou_ids = {
    for env_name, env_config in local.environments :
    env_name => env_config.ou_id
  }

  # Production OU protection
  production_ou_ids                = [local.environments.prod.ou_id]
  enable_production_account_protection = true

  # Default tags
  default_tags = {
    ManagedBy = "AccountFactory"
    Terraform = "true"
  }

  # Required tags
  required_tags = ["Owner", "Environment", "CostCenter", "Application"]

  # Security baseline
  security_baselines = {
    default = {
      version              = "1.0.0"
      enable_security_hub  = true
      enable_guardduty     = true
      enable_config        = true
      enable_cloudtrail    = true
      compliance_standards = [
        "aws-foundational-security-best-practices"
      ]
    }
  }

  # Network baselines with different CIDR blocks per environment
  network_baselines = {
    standard = {
      version                = "1.0.0"
      vpc_cidr               = "10.0.0.0/16"
      availability_zones     = 3
      enable_transit_gateway = true
      enable_flow_logs       = true
    }
  }

  # Use generated accounts
  accounts = local.accounts

  # Service Control Policies
  service_control_policies = {
    deny-root-user = {
      description = "Deny root user access except for account management"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyRootUser"
            Effect = "Deny"
            Action = "*"
            Resource = "*"
            Condition = {
              StringLike = {
                "aws:PrincipalArn" = "arn:aws:iam::*:root"
              }
            }
          }
        ]
      })
      targets = [
        local.environments.dev.ou_id,
        local.environments.staging.ou_id,
        local.environments.prod.ou_id
      ]
    }
  }

  # Integration settings
  use_existing_control_tower_roles = false
  existing_transit_gateway_id      = "tgw-0123456789abcdef0"
}
