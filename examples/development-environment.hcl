# Development/Testing Landing Zone
# Configuration for development and testing environments with cost optimization

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/ccl-consulting/aws-account-module-terragrunt.git"
}

# Local variables for development environment
locals {
  environment = "development"
  cost_center = "Engineering"
  
  # Reduced scope for development
  dev_regions = ["us-east-1", "us-west-2"]
  
  # Development team structure
  dev_teams = [
    "frontend-team",
    "backend-team", 
    "mobile-team",
    "qa-team",
    "devops-team"
  ]
}

# Generate development-specific provider
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.region
  
  # Development assume role
  assume_role {
    role_arn = "arn:aws:iam::$${get_aws_account_id()}:role/DevelopmentAccessRole"
  }
  
  default_tags {
    tags = {
      Environment = "${local.environment}"
      CostCenter  = "${local.cost_center}"
      AutoShutdown = "true"  # Enable automatic shutdown for cost savings
      Purpose     = "Development"
    }
  }
}
EOF
}

# Development remote state (simpler configuration)
remote_state {
  backend = "local"
  config = {
    path = "terraform.tfstate"
  }
}

inputs = {
  # =========================================================================
  # DEVELOPMENT REGIONAL CONFIGURATION
  # =========================================================================
  
  region           = "us-east-1"
  backup_region    = "us-west-2"
  governed_regions = local.dev_regions
  
  # =========================================================================
  # EMAIL CONFIGURATION
  # =========================================================================
  
  email_local_part = "aws-dev"
  email_domain     = "ccl-consulting.com"  # Update with your domain
  
  # =========================================================================
  # DEVELOPMENT ACCOUNT STRUCTURE
  # =========================================================================
  
  org_accounts = {
    workloads = {
      # Development workload accounts per team
      prod = []  # No production accounts in dev environment
      
      staging = [
        "staging-integration",
        "staging-performance"
      ]
      
      dev = concat(
        [for team in local.dev_teams : "dev-${team}"],
        [
          "dev-sandbox",
          "dev-experimental",
          "dev-prototype"
        ]
      )
    }
    
    # Minimal common services for development
    common_services = [
      "shared-dev-tools",
      "shared-dev-monitoring",
      "shared-dev-artifacts"
    ]
  }
  
  # =========================================================================
  # DEVELOPMENT TAGGING STRATEGY
  # =========================================================================
  
  tags = {
    # Basic information
    "Owner"          = "CCL Consulting"
    "Provisioned by" = "Terraform"
    "Environment"    = local.environment
    "CostCenter"     = local.cost_center
    
    # Development-specific tags
    "Purpose"        = "Development"
    "AutoShutdown"   = "true"
    "CostOptimized"  = "true"
    "TestEnvironment" = "true"
    
    # Contact information
    "TechnicalOwner" = "dev-team@ccl-consulting.com"
    "Contact"        = "devops@ccl-consulting.com"
    
    # Lifecycle
    "CreatedFor"     = "Development"
    "Temporary"      = "false"
    "ReviewCycle"    = "Monthly"
  }
}

# =========================================================================
# DEVELOPMENT DEPLOYMENT CONFIGURATION
# =========================================================================

# Simplified dependencies for development
dependencies {
  paths = ["../prerequisites/basic-setup"]
}

# Development-specific hooks
terraform {
  before_hook "dev_environment_check" {
    commands = ["plan", "apply"]
    execute = [
      "bash", "-c", <<-EOT
        echo "🚀 Deploying development landing zone..."
        echo "💰 Cost optimization features enabled"
        echo "⚠️  This is a development environment - not for production use"
        
        # Check if we're in the right AWS account
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        echo "📍 Deploying to AWS Account: $$ACCOUNT_ID"
        
        # Warn about development limitations
        echo ""
        echo "📋 Development Environment Limitations:"
        echo "  • Limited to ${length(local.dev_regions)} regions"
        echo "  • Auto-shutdown policies will be applied"
        echo "  • Reduced backup retention periods"
        echo "  • Simplified monitoring configuration"
        echo ""
      EOT
    ]
  }
  
  after_hook "dev_post_deployment" {
    commands = ["apply"]
    execute = [
      "bash", "-c", <<-EOT
        echo "✅ Development landing zone deployed successfully!"
        echo ""
        echo "📋 Development Environment Summary:"
        echo "  • ${length(local.dev_teams)} team development accounts created"
        echo "  • Staging and experimental accounts available"
        echo "  • Cost optimization policies applied"
        echo ""
        echo "🔧 Next Steps for Development:"
        echo "  1. Set up development CI/CD pipelines"
        echo "  2. Configure development monitoring dashboards"
        echo "  3. Set up cost alerts and budgets"
        echo "  4. Configure auto-shutdown policies"
        echo "  5. Set up development access controls"
        echo ""
        echo "💡 Development Best Practices:"
        echo "  • Use spot instances where possible"
        echo "  • Enable auto-shutdown for non-critical resources"
        echo "  • Regular cleanup of unused resources"
        echo "  • Monitor costs daily"
        echo ""
        echo "📞 Support: dev-team@ccl-consulting.com"
      EOT
    ]
  }
}
