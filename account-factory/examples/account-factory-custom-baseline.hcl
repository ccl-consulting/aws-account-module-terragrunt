# Custom Baseline Configuration Example
# Implementation: Task 23.3

# This example demonstrates custom security and network baseline configurations
# with baseline versioning and region-specific variations

terraform {
  source = "..//account-factory"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # Management account configuration
  management_account_id = "123456789012"
  logging_account_id    = "123456789013"
  security_account_id   = "123456789014"

  # Governed regions
  governed_regions = ["us-east-1", "us-west-2", "eu-west-1"]

  # Organizational units
  existing_ou_ids = {
    "HighSecurity" = "ou-xxxx-11111111"
    "Standard"     = "ou-xxxx-22222222"
    "Development"  = "ou-xxxx-33333333"
  }

  # Production protection
  production_ou_ids                = ["ou-xxxx-11111111"]
  enable_production_account_protection = true

  # Default tags
  default_tags = {
    ManagedBy = "AccountFactory"
    Terraform = "true"
  }

  # Custom tag schema with validation
  custom_tag_schema = {
    required_keys = ["Owner", "Environment", "CostCenter", "DataClassification"]
    allowed_keys  = ["Owner", "Environment", "CostCenter", "DataClassification", "Application", "Compliance"]
    key_patterns = {
      Owner          = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"  # Email format
      Environment    = "^(development|staging|production)$"
      CostCenter     = "^CC-[0-9]{4}$"
      DataClassification = "^(public|internal|confidential|restricted)$"
    }
  }

  # Multiple security baselines with different compliance requirements
  security_baselines = {
    high-security = {
      version              = "2.0.0"
      enable_security_hub  = true
      enable_guardduty     = true
      enable_config        = true
      enable_cloudtrail    = true
      compliance_standards = [
        "aws-foundational-security-best-practices",
        "cis-aws-foundations-benchmark/v/1.4.0",
        "pci-dss/v/3.2.1",
        "nist-800-53/v/5.0.0"
      ]
    }
    standard = {
      version              = "1.5.0"
      enable_security_hub  = true
      enable_guardduty     = true
      enable_config        = true
      enable_cloudtrail    = true
      compliance_standards = [
        "aws-foundational-security-best-practices"
      ]
    }
    minimal = {
      version              = "1.0.0"
      enable_security_hub  = true
      enable_guardduty     = false
      enable_config        = false
      enable_cloudtrail    = true
      compliance_standards = []
    }
  }

  # Multiple network baselines with different CIDR ranges and configurations
  network_baselines = {
    large-vpc = {
      version                = "2.0.0"
      vpc_cidr               = "10.0.0.0/16"
      availability_zones     = 3
      enable_transit_gateway = true
      enable_flow_logs       = true
    }
    medium-vpc = {
      version                = "1.5.0"
      vpc_cidr               = "10.1.0.0/20"
      availability_zones     = 2
      enable_transit_gateway = true
      enable_flow_logs       = true
    }
    small-vpc = {
      version                = "1.0.0"
      vpc_cidr               = "10.2.0.0/24"
      availability_zones     = 2
      enable_transit_gateway = false
      enable_flow_logs       = false
    }
  }

  # Accounts with different baseline configurations and versions
  accounts = {
    # High security account with latest baselines
    prod-payment-processing = {
      email               = "aws-prod-payment@example.com"
      organizational_unit = "HighSecurity"
      security_baseline   = "high-security"
      network_baseline    = "large-vpc"
      baseline_version    = "latest"  # Always use latest version
      regions             = ["us-east-1", "us-west-2", "eu-west-1"]
      tags = {
        Owner              = "security-team@example.com"
        Environment        = "production"
        CostCenter         = "CC-1001"
        DataClassification = "restricted"
        Application        = "payment-processing"
        Compliance         = "PCI-DSS"
      }
      close_on_deletion  = false
      delegated_services = []
    }

    # Standard account with pinned baseline version
    staging-api = {
      email               = "aws-staging-api@example.com"
      organizational_unit = "Standard"
      security_baseline   = "standard"
      network_baseline    = "medium-vpc"
      baseline_version    = "1.5.0"  # Pinned to specific version
      regions             = ["us-east-1"]
      tags = {
        Owner              = "api-team@example.com"
        Environment        = "staging"
        CostCenter         = "CC-2001"
        DataClassification = "internal"
        Application        = "api-gateway"
      }
      close_on_deletion  = false
      delegated_services = []
    }

    # Development account with minimal baseline
    dev-sandbox = {
      email               = "aws-dev-sandbox@example.com"
      organizational_unit = "Development"
      security_baseline   = "minimal"
      network_baseline    = "small-vpc"
      baseline_version    = "latest"
      regions             = ["us-east-1"]
      tags = {
        Owner              = "dev-team@example.com"
        Environment        = "development"
        CostCenter         = "CC-3001"
        DataClassification = "public"
        Application        = "sandbox"
      }
      close_on_deletion  = true  # Can be closed when removed
      delegated_services = []
    }

    # Security tooling account with delegated admin services
    security-tools = {
      email               = "aws-security-tools@example.com"
      organizational_unit = "HighSecurity"
      security_baseline   = "high-security"
      network_baseline    = "medium-vpc"
      baseline_version    = "latest"
      regions             = ["us-east-1", "us-west-2"]
      tags = {
        Owner              = "security-team@example.com"
        Environment        = "production"
        CostCenter         = "CC-1002"
        DataClassification = "confidential"
        Application        = "security-tooling"
      }
      close_on_deletion = false
      delegated_services = [
        "securityhub.amazonaws.com",
        "guardduty.amazonaws.com",
        "access-analyzer.amazonaws.com"
      ]
    }
  }

  # Service Control Policies
  service_control_policies = {
    require-encryption = {
      description = "Require encryption for S3 and EBS"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyUnencryptedS3"
            Effect = "Deny"
            Action = ["s3:PutObject"]
            Resource = "*"
            Condition = {
              StringNotEquals = {
                "s3:x-amz-server-side-encryption" = "AES256"
              }
            }
          }
        ]
      })
      targets = ["ou-xxxx-11111111"]  # High security OU
    }
  }

  # Integration with existing Landing Zone
  use_existing_control_tower_roles = true
  existing_transit_gateway_id      = "tgw-0123456789abcdef0"
  existing_cloudtrail_bucket_name  = "org-cloudtrail-logs"
  existing_flow_logs_bucket_name   = "org-vpc-flow-logs"
}
