resource "aws_organizations_delegated_administrator" "backups" {
  account_id        = aws_organizations_account.backups.id
  service_principal = "backup.amazonaws.com"
}

resource "aws_backup_global_settings" "cross_account_backup" {
  global_settings = {
    "isCrossAccountBackupEnabled" = "true"
  }
}

resource "aws_organizations_resource_policy" "allow_delegated_backup_administrator" {
  content = data.aws_iam_policy_document.organization_backup_policy.json
}

data "aws_iam_policy_document" "organization_backup_policy" {
  statement {
    sid = "AllowOrganizationsRead"
    actions = [
      "organizations:Describe*",
      "organizations:List*"
    ]
    resources = ["*"]
    principals {
      identifiers = [aws_organizations_account.backups.id]
      type        = "AWS"
    }
  }
  statement {
    sid = "AllowBackupPoliciesCreation"
    actions = [
      "organizations:CreatePolicy"
    ]
    resources = ["*"]
    principals {
      identifiers = [aws_organizations_account.backups.id]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "organizations:PolicyType"
      values   = ["BACKUP_POLICY"]
    }
  }
  statement {
    sid = "AllowBackupPoliciesModification"
    actions = [
      "organizations:DescribePolicy",
      "organizations:UpdatePolicy",
      "organizations:DeletePolicy"
    ]
    resources = ["arn:aws:organizations::${aws_organizations_organization.org.master_account_id}:policy/*/backup_policy/*", ]
    principals {
      identifiers = [aws_organizations_account.backups.id]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "organizations:PolicyType"
      values   = ["BACKUP_POLICY"]
    }
  }
  statement {
    sid = "AllowBackupPoliciesAttachmentAndDetachmentToAllAccountsAndOUs"
    actions = [
      "organizations:AttachPolicy",
      "organizations:DetachPolicy"
    ]
    resources = [
      "arn:aws:organizations::${aws_organizations_organization.org.master_account_id}:root/*",
      "arn:aws:organizations::${aws_organizations_organization.org.master_account_id}:ou/*",
      "arn:aws:organizations::${aws_organizations_organization.org.master_account_id}:account/*",
      "arn:aws:organizations::${aws_organizations_organization.org.master_account_id}:policy/*/backup_policy/*"
    ]
    principals {
      identifiers = [aws_organizations_account.backups.id]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "organizations:PolicyType"
      values   = ["BACKUP_POLICY"]
    }
  }
}

locals {
  backup_vault_name     = "common-backup-vault"
  backup_selection_role = "AWSBackupDefaultServiceRole"
}

#####
# Create backup selection role
#####

resource "aws_iam_role" "backup_selection_role" {
  name               = local.backup_selection_role
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup_selection_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_selection_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

#####
# Create backup policy
#####

module "central-backup-policy" {
  source = "git::https://github.com/ccl-consulting/terraform-modules.git//aws-accounts-terragrunt/modules/aws-lz-central-backups?ref=update/template"


  name                       = "organization-backup-policy"
  backup_cron_schedule       = "cron(0 2 ? * 4 *)" # Every Thursday at 2:00 AM UTC
  backup_selection_role_name = local.backup_selection_role
  vault_name                 = local.backup_vault_name
  backup_selection_tags = {
    Backup = ["true"]
  }

  target_resource_region = var.region
  secondary_vault_region = var.backup_region

  account_id    = aws_organizations_account.backups.id
  parent_org_id = aws_organizations_organization.org.id

  depends_on = [
    aws_organizations_resource_policy.allow_delegated_backup_administrator
  ]
}
