# AWS Organizations Account Resources
# This file contains account creation resources
# Implementation: Task 3.1, Task 16.1

resource "aws_organizations_account" "accounts" {
  for_each = var.accounts

  name      = each.key
  email     = each.value.email
  parent_id = local.account_ou_mapping[each.key]

  # Apply merged tags (default + account-specific)
  tags = local.account_tags[each.key]

  # Configure close_on_deletion behavior based on account configuration
  # When true: Account will be closed when removed from Terraform
  # When false: Account will remain active (should be manually moved to Suspended OU)
  close_on_deletion = each.value.close_on_deletion

  lifecycle {
    # Prevent accidental deletion of accounts
    # Set to false to allow Terraform to manage account lifecycle
    # Production accounts are protected via validation in locals.tf
    prevent_destroy = false

    # Ignore changes to role_name as it's managed by Control Tower
    ignore_changes = [role_name]
  }

  # Ensure validation completes before account creation
  depends_on = [
    # Validation checks in locals.tf ensure:
    # - Required tags are present
    # - Baseline references are valid
    # - OU references are valid
    # - Email addresses are unique
    # - Production account deletion protection
  ]
}

# Note on Account Suspension:
# When an account is removed from the var.accounts configuration:
# 1. If close_on_deletion = false: The account remains in AWS Organizations
#    - Manually move the account to the Suspended OU (var.suspended_ou_id)
#    - Apply the suspended account SCP to prevent resource creation
#    - The account will be removed from Terraform state but not deleted
# 2. If close_on_deletion = true: The account will be closed by AWS
#    - Account enters a 90-day suspension period
#    - After 90 days, the account is permanently closed
#    - Email address becomes available for reuse after closure
#
# For automated suspension, consider using a separate process or Lambda function
# that monitors Terraform state changes and moves removed accounts to Suspended OU.

