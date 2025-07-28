include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/ccl-consulting/aws-account-module-terragrunt.git"
}

inputs = {
  region           = "us-east-1"
  backup_region    = "us-west-2"
  governed_regions = ["us-east-1"]
  
  email_local_part = "aws"
  email_domain     = "startup.com"
  
  org_accounts = {
    workloads = {
      prod = ["production"]
      staging = ["staging"]
      dev = ["development"]
    }
    common_services = []
  }
  
  tags = {
    "Owner"          = "CCL Consulting"
    "Provisioned by" = "Terraform"
    "Environment"    = "Startup"
    "CostCenter"     = "Engineering"
    "Contact"        = "devops@startup.com"
  }
}
