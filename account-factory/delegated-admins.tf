# Delegated Administrator Configuration
# This file contains delegated administrator resources
# Implementation: Task 12
# Requirements: 10.1, 10.2, 10.3, 10.4, 10.5

# Validate delegated administrator uniqueness per service
locals {
  # Create a map of service to list of accounts
  service_to_accounts = {
    for service in distinct([for item in local.delegated_admin_services : item.service]) :
    service => [
      for item in local.delegated_admin_services :
      item.account_name if item.service == service
    ]
  }

  # Find services with multiple delegated administrators
  duplicate_delegated_admins = {
    for service, accounts in local.service_to_accounts :
    service => accounts if length(accounts) > 1
  }

  # Validation: Fail if any service has multiple delegated administrators
  validate_delegated_admin_uniqueness = length(local.duplicate_delegated_admins) == 0 ? true : tobool(
    "Validation failed: The following services have multiple delegated administrators: ${jsonencode(local.duplicate_delegated_admins)}"
  )
}

# Delegated Administrators
resource "aws_organizations_delegated_administrator" "admins" {
  for_each = {
    for item in local.delegated_admin_services :
    "${item.account_name}-${item.service}" => item
  }

  account_id        = aws_organizations_account.accounts[each.value.account_name].id
  service_principal = each.value.service

  depends_on = [aws_organizations_account.accounts]
}

# Common AWS service principals for delegated administration
# These are the most commonly used services that support delegated administration:
# - securityhub.amazonaws.com: AWS Security Hub
# - guardduty.amazonaws.com: Amazon GuardDuty
# - macie.amazonaws.com: Amazon Macie
# - fms.amazonaws.com: AWS Firewall Manager
# - access-analyzer.amazonaws.com: IAM Access Analyzer
# - config.amazonaws.com: AWS Config
# - config-multiaccountsetup.amazonaws.com: AWS Config Multi-Account Setup
# - cloudtrail.amazonaws.com: AWS CloudTrail
# - auditmanager.amazonaws.com: AWS Audit Manager
# - detective.amazonaws.com: Amazon Detective
# - inspector2.amazonaws.com: Amazon Inspector
# - sso.amazonaws.com: AWS IAM Identity Center (SSO)
# - stacksets.cloudformation.amazonaws.com: CloudFormation StackSets
# - member.org.stacksets.cloudformation.amazonaws.com: CloudFormation StackSets (Organizations)

# Resource policies for delegated administrator access
# These policies enable the delegated administrator account to manage services across the organization

# Security Hub delegated administrator policy
resource "aws_securityhub_organization_admin_account" "security_hub" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "securityhub.amazonaws.com"
  }

  admin_account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

# GuardDuty delegated administrator policy
resource "aws_guardduty_organization_admin_account" "guardduty" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "guardduty.amazonaws.com"
  }

  admin_account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

# Macie delegated administrator policy
resource "aws_macie2_organization_admin_account" "macie" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "macie.amazonaws.com"
  }

  admin_account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

# Access Analyzer delegated administrator policy
resource "aws_accessanalyzer_organization_admin_account" "access_analyzer" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "access-analyzer.amazonaws.com"
  }

  admin_account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

# Audit Manager delegated administrator policy
resource "aws_auditmanager_organization_admin_account_registration" "audit_manager" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "auditmanager.amazonaws.com"
  }

  admin_account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

# Detective delegated administrator policy
resource "aws_detective_organization_admin_account" "detective" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "detective.amazonaws.com"
  }

  account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

# Inspector delegated administrator policy
resource "aws_inspector2_delegated_admin_account" "inspector" {
  for_each = {
    for item in local.delegated_admin_services :
    item.account_name => item if item.service == "inspector2.amazonaws.com"
  }

  account_id = aws_organizations_account.accounts[each.key].id

  depends_on = [
    aws_organizations_delegated_administrator.admins,
    aws_organizations_account.accounts
  ]
}

