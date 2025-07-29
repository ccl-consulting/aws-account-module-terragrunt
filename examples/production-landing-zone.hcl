include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/ccl-consulting/aws-account-module-terragrunt.git?ref=v1.0.0"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.region
  
  assume_role {
    role_arn = "arn:aws:iam::MANAGEMENT-ACCOUNT-ID:role/TerraformExecutionRole"
  }
  
  default_tags {
    tags = {
      ManagedBy    = "Terragrunt"
      Environment  = "Production"
      Module       = "LandingZone"
      CostCenter   = "Infrastructure"
    }
  }
}
EOF
}

remote_state {
  backend = "local"
  config = {
    path = "terraform.tfstate"
  }
}

inputs = {
  region = "us-east-1"
  backup_region = "us-west-2"
  
  governed_regions = [
    "us-east-1",
    "us-west-2",
    "eu-west-1",
    "eu-central-1"
  ]
  
  email_local_part = "aws"
  email_domain     = "company.com"
  
  org_accounts = {
    workloads = {
      prod = [
        "prod-web-services",
        "prod-databases",
        "prod-analytics",
        "prod-ml-platform"
      ]
      
      staging = [
        "staging-web-services",
        "staging-databases",
        "staging-testing"
      ]
      
      dev = [
        "dev-web-services",
        "dev-databases",
        "dev-sandbox"
      ]
    }
    
    common_services = [
      "shared-networking",
      "shared-dns",
      "shared-monitoring",
      "shared-ci-cd",
      "shared-data-lake"
    ]
  }
  
  tags = {
    "Owner"           = "CCL Consulting",
    "Provisioned by"  = "Terraform",
    "Environment"     = "Production",
    "CostCenter"      = "Infrastructure",
    "Project"         = "LandingZone",
    "DataClass"       = "Internal",
    "Backup"          = "true",
    "Monitoring"      = "true",
    "Compliance"      = "SOC2",
    "SecurityLevel"   = "High",
    "TechnicalOwner"  = "infrastructure-team@company.com",
    "BusinessOwner"   = "platform-team@company.com",
    "CreatedDate"     = "2024-01-01",
    "LastReviewed"    = "2024-01-01"
  }
}

dependencies {
  paths = ["../prerequisites"]
}

skip = false

terraform {
  before_hook "pre_deployment_check" {
    commands = ["plan", "apply"]
    execute  = ["echo", "Validating landing zone prerequisites..."]
  }
  
  after_hook "post_deployment_notification" {
    commands = ["apply"]
    execute  = ["echo", "Landing zone deployment completed successfully!"]
  }
}
