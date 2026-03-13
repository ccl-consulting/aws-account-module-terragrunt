# Data sources for existing Landing Zone resources

# Get the current AWS organization
data "aws_organizations_organization" "current" {}

# Get existing organizational units
data "aws_organizations_organizational_units" "root" {
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

# Get information about the logging account
data "aws_organizations_account" "logging" {
  account_id = var.logging_account_id
}

# Get information about the security account
data "aws_organizations_account" "security" {
  account_id = var.security_account_id
}

# Get information about the management account
data "aws_caller_identity" "current" {}

# Get available AWS regions
data "aws_regions" "available" {
  all_regions = false
}

# Get existing Control Tower StackSet roles (if they exist)
# These roles are created by Control Tower and can be reused
data "aws_iam_role" "control_tower_stackset_role" {
  count = var.use_existing_control_tower_roles ? 1 : 0
  name  = "AWSControlTowerStackSetRole"
}

data "aws_iam_role" "control_tower_execution_role" {
  count = var.use_existing_control_tower_roles ? 1 : 0
  name  = "AWSControlTowerExecution"
}

# Get existing Transit Gateway (if specified)
data "aws_ec2_transit_gateway" "existing" {
  count = var.existing_transit_gateway_id != "" ? 1 : 0

  filter {
    name   = "transit-gateway-id"
    values = [var.existing_transit_gateway_id]
  }
}

# Get existing S3 bucket for CloudTrail logs (if specified)
data "aws_s3_bucket" "cloudtrail_logs" {
  count  = var.existing_cloudtrail_bucket_name != "" ? 1 : 0
  bucket = var.existing_cloudtrail_bucket_name
}

# Get existing S3 bucket for VPC Flow Logs (if specified)
data "aws_s3_bucket" "flow_logs" {
  count  = var.existing_flow_logs_bucket_name != "" ? 1 : 0
  bucket = var.existing_flow_logs_bucket_name
}

# Get existing CloudWatch Log Group for centralized logging (if specified)
data "aws_cloudwatch_log_group" "centralized_logs" {
  count = var.existing_log_group_name != "" ? 1 : 0
  name  = var.existing_log_group_name
}
