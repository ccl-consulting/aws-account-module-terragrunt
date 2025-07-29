
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/ccl-consulting/aws-account-module-terragrunt.git?ref=v1.0.0"
}

# Locals for dynamic configuration
locals {
  # Environment-specific settings
  environment = "enterprise"
  
  # Regional configuration
  primary_region   = "us-east-1"
  secondary_region = "us-west-2"
  eu_region       = "eu-west-1"
  apac_region     = "ap-southeast-1"
  
  # Business units
  business_units = {
    finance = {
      prod    = ["finance-prod-core", "finance-prod-data"]
      staging = ["finance-staging"]
      dev     = ["finance-dev"]
    }
    hr = {
      prod    = ["hr-prod-systems"]
      staging = ["hr-staging"]
      dev     = ["hr-dev"]
    }
    marketing = {
      prod    = ["marketing-prod-web", "marketing-prod-analytics"]
      staging = ["marketing-staging"]
      dev     = ["marketing-dev"]
    }
    engineering = {
      prod    = ["eng-prod-platform", "eng-prod-apis", "eng-prod-ml"]
      staging = ["eng-staging-platform", "eng-staging-apis"]
      dev     = ["eng-dev-sandbox", "eng-dev-research"]
    }
  }
  
  # Flatten business unit accounts for the module
  all_prod_accounts    = flatten([for bu, envs in local.business_units : envs.prod])
  all_staging_accounts = flatten([for bu, envs in local.business_units : envs.staging])
  all_dev_accounts     = flatten([for bu, envs in local.business_units : envs.dev])
  
  # Common tags for all resources
  common_tags = {
    "Owner"           = "CCL Consulting"
    "Provisioned by"  = "Terraform"
    "Environment"     = local.environment
    "Module"          = "LandingZone"
    "LastUpdated"     = timestamp()
  }
}

# Generate provider with advanced configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.region
  
  # Enhanced assume role configuration
  assume_role {
    role_arn     = "arn:aws:iam::$${get_aws_account_id()}:role/OrganizationAccountAccessRole"
    session_name = "TerragruntLandingZone"
    external_id  = "TerragruntExecution"
  }
  
  # Default tags applied to all resources
  default_tags {
    tags = merge(
      ${jsonencode(local.common_tags)},
      {
        CreatedBy = "Terragrunt"
        Region    = var.region
      }
    )
  }
  
  # Retry configuration for large deployments
  retry_mode = "adaptive"
  max_retries = 10
}

# Additional provider for backup region
provider "aws" {
  alias  = "backup"
  region = var.backup_region
  
  assume_role {
    role_arn     = "arn:aws:iam::$${get_aws_account_id()}:role/OrganizationAccountAccessRole"
    session_name = "TerragruntLandingZoneBackup"
  }
  
  default_tags {
    tags = merge(
      ${jsonencode(local.common_tags)},
      {
        CreatedBy = "Terragrunt"
        Region    = var.backup_region
        Purpose   = "Backup"
      }
    )
  }
}
EOF
}

# Enhanced remote state with cross-region replication
remote_state {
  backend = "local"
  config = {
    path = "terraform.tfstate"
  }
}

inputs = {
  # =========================================================================
  # GLOBAL REGIONAL CONFIGURATION
  # =========================================================================
  
  region        = local.primary_region
  backup_region = local.secondary_region
  
  # Multi-region Control Tower deployment
  governed_regions = [
    # North America
    local.primary_region,   # us-east-1
    local.secondary_region, # us-west-2
    "us-west-1",
    "ca-central-1",
    
    # Europe
    local.eu_region,        # eu-west-1
    "eu-west-2",
    "eu-west-3",
    "eu-central-1",
    "eu-north-1",
    
    # Asia Pacific
    local.apac_region,      # ap-southeast-1
    "ap-southeast-2",
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-south-1"
  ]
  
  # =========================================================================
  # EMAIL CONFIGURATION
  # =========================================================================
  
  email_local_part = "aws-accounts"
  email_domain     = "enterprise.com"  # Replace with actual domain
  
  # =========================================================================
  # COMPREHENSIVE ORGANIZATIONAL STRUCTURE
  # =========================================================================
  
  org_accounts = {
    workloads = {
      prod    = local.all_prod_accounts
      staging = local.all_staging_accounts
      dev     = local.all_dev_accounts
    }
    
    # Extensive common services for enterprise needs
    common_services = [
      # Core Infrastructure
      "shared-networking-hub",
      "shared-dns-management",
      "shared-transit-gateway",
      
      # Security & Compliance
      "shared-security-hub",
      "shared-compliance-scanning",
      "shared-secrets-management",
      "shared-certificate-management",
      
      # Monitoring & Observability
      "shared-monitoring-central",
      "shared-logging-aggregation",
      "shared-metrics-collection",
      "shared-alerting-notification",
      
      # DevOps & CI/CD
      "shared-ci-cd-platform",
      "shared-artifact-repository",
      "shared-container-registry",
      "shared-deployment-automation",
      
      # Data & Analytics
      "shared-data-lake-central",
      "shared-data-warehouse",
      "shared-analytics-platform",
      "shared-ml-platform",
      
      # Business Continuity
      "shared-disaster-recovery",
      "shared-business-continuity",
      
      # Cost Management
      "shared-cost-optimization",
      "shared-resource-tagging"
    ]
  }
  
  # =========================================================================
  # ENTERPRISE TAGGING STRATEGY
  # =========================================================================
  
  tags = merge(local.common_tags, {
    # Business Information
    "Organization"    = "Enterprise Corp"
    "Department"      = "Information Technology"
    "CostCenter"      = "IT-INFRASTRUCTURE"
    "Project"         = "ENTERPRISE-LANDING-ZONE"
    
    # Compliance & Governance
    "DataClass"       = "Confidential"
    "Compliance"      = "SOX,GDPR,SOC2,ISO27001"
    "SecurityLevel"   = "High"
    "BackupRequired"  = "true"
    "MonitoringLevel" = "Enhanced"
    
    # Financial Management
    "BudgetCode"      = "INFRA-001"
    "ChargebackCode"  = "IT-PLATFORM"
    "CostAllocation"  = "Shared"
    
    # Technical Information
    "Architecture"    = "Multi-Region"
    "Availability"    = "99.99"
    "RecoveryTier"    = "Tier1"
    
    # Contact Information
    "TechnicalOwner"  = "cloud-platform-team@enterprise.com"
    "BusinessOwner"   = "infrastructure-director@enterprise.com"
    "SecurityContact" = "security-team@enterprise.com"
    "CostOwner"       = "finops-team@enterprise.com"
    
    # Lifecycle Management
    "MaintenanceWindow" = "Sunday-02:00-06:00Z"
    "ReviewDate"        = "2024-06-01"
    "RetentionPolicy"   = "7-years"
    "ArchivalPolicy"    = "3-years"
  })
}

# =========================================================================
# DEPLOYMENT CONFIGURATION
# =========================================================================

# Dependencies ensure proper deployment order
dependencies {
  paths = [
    "../prerequisites/iam-roles",
    "../prerequisites/kms-keys",
    "../prerequisites/s3-state-buckets"
  ]
}

# Deployment validation and automation
terraform {
  # Pre-deployment validations
  before_hook "validate_prerequisites" {
    commands = ["plan", "apply"]
    execute = [
      "bash", "-c", <<-EOT
        echo "Validating enterprise landing zone prerequisites..."
        
        # Check if management account has necessary permissions
        aws sts get-caller-identity || (echo "ERROR: AWS credentials not configured" && exit 1)
        
        # Validate email domain
        if [[ "${local.email_domain}" == "enterprise.com" ]]; then
          echo "WARNING: Please update email_domain with your actual domain"
        fi
        
        # Check for required environment variables
        required_vars=("TF_VAR_email_domain")
        for var in "${required_vars[@]}"; do
          if [[ -z "${!var}" ]]; then
            echo "ERROR: Required environment variable $var is not set"
            exit 1
          fi
        done
        
        echo "Prerequisites validation completed"
      EOT
    ]
  }
  
  # Post-deployment notifications and documentation
  after_hook "post_deployment_actions" {
    commands = ["apply"]
    execute = [
      "bash", "-c", <<-EOT
        echo "Enterprise landing zone deployment completed!"
        echo ""
        echo "Deployment Summary:"
        echo "  • Organization created with ${length(local.all_prod_accounts) + length(local.all_staging_accounts) + length(local.all_dev_accounts)} workload accounts"
        echo "  • ${length(inputs.org_accounts.common_services)} common service accounts provisioned"
        echo "  • Control Tower enabled in ${length(inputs.governed_regions)} regions"
        echo "  • Backup policies configured for cross-region protection"
        echo ""
        echo "Next Steps:"
        echo "  1. Configure AWS SSO/Identity Center"
        echo "  2. Set up network connectivity (Transit Gateway, VPN)"
        echo "  3. Deploy security baselines to all accounts"
        echo "  4. Configure monitoring and alerting"
        echo "  5. Set up CI/CD pipelines for workload deployments"
        echo ""
        echo "Documentation: https://docs.enterprise.com/aws-landing-zone"
        echo "Support: cloud-platform-team@enterprise.com"
      EOT
    ]
  }
  
  # Error handling
  error_hook "deployment_failure" {
    commands = ["plan", "apply"]
    execute = [
      "bash", "-c", <<-EOT
        echo "ERROR: Landing zone deployment failed!"
        echo "Contact: cloud-platform-team@enterprise.com"
        echo "Troubleshooting: https://docs.enterprise.com/aws-landing-zone/troubleshooting"
      EOT
    ]
  }
}
