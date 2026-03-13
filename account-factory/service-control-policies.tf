# Service Control Policy Management
# This file contains SCP resources and attachments
# Implementation: Task 11
# Requirements: 6.1, 6.2, 6.4, 6.5

# Service Control Policies
resource "aws_organizations_policy" "scp" {
  for_each = var.service_control_policies

  name        = each.key
  description = each.value.description
  content     = each.value.policy
  type        = "SERVICE_CONTROL_POLICY"

  tags = merge(
    var.default_tags,
    {
      Name      = each.key
      ManagedBy = "AccountFactory"
    }
  )
}

# Service Control Policy Attachments
resource "aws_organizations_policy_attachment" "scp_attachment" {
  for_each = {
    for pair in flatten([
      for name, scp in var.service_control_policies : [
        for target in scp.targets : {
          policy_name = name
          target_id   = target
        }
      ]
    ]) : "${pair.policy_name}-${pair.target_id}" => pair
  }

  policy_id = aws_organizations_policy.scp[each.value.policy_name].id
  target_id = each.value.target_id
}

# Mandatory SCP for suspended accounts
# This restrictive SCP is automatically applied when accounts are suspended
# Requirements: 12.3
resource "aws_organizations_policy" "suspended_account_scp" {
  name        = "SuspendedAccountRestrictions"
  description = "Restrictive SCP applied to suspended accounts to prevent resource creation"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptRead"
        Effect = "Deny"
        NotAction = [
          # Allow read-only actions for auditing and investigation
          "iam:Get*",
          "iam:List*",
          "organizations:Describe*",
          "organizations:List*",
          "sts:GetCallerIdentity",
          "cloudtrail:LookupEvents",
          "cloudtrail:Get*",
          "cloudtrail:Describe*",
          "cloudtrail:List*",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "logs:Describe*",
          "logs:Get*",
          "logs:FilterLogEvents",
          "logs:TestMetricFilter",
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyAccountLeaving"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyBillingAccess"
        Effect = "Deny"
        Action = [
          "aws-portal:*",
          "budgets:*",
          "ce:*",
          "cur:*",
          "purchase-orders:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.default_tags,
    {
      Name      = "SuspendedAccountRestrictions"
      Purpose   = "Restrict suspended accounts"
      ManagedBy = "AccountFactory"
      Critical  = "true"
    }
  )
}

# Automatic SCP attachment to Suspended OU
# This ensures all accounts in the Suspended OU have the restrictive SCP applied
resource "aws_organizations_policy_attachment" "suspended_ou_scp" {
  count = var.suspended_ou_id != "" ? 1 : 0

  policy_id = aws_organizations_policy.suspended_account_scp.id
  target_id = var.suspended_ou_id
}

# Data source for current organization
data "aws_organizations_organization" "current" {}

