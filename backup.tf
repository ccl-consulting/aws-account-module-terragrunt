# Enable AWS service access for backup service first
resource "aws_organizations_service_access" "backup" {
  service_principal = "backup.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "backups" {
  account_id        = aws_organizations_account.backups.id
  service_principal = "backup.amazonaws.com"
  
  depends_on = [aws_organizations_service_access.backup]
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
    resources = ["arn:aws:organizations::${data.aws_organizations_organization.org.master_account_id}:policy/*/backup_policy/*", ]
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
      "arn:aws:organizations::${data.aws_organizations_organization.org.master_account_id}:root/*",
      "arn:aws:organizations::${data.aws_organizations_organization.org.master_account_id}:ou/*",
      "arn:aws:organizations::${data.aws_organizations_organization.org.master_account_id}:account/*",
      "arn:aws:organizations::${data.aws_organizations_organization.org.master_account_id}:policy/*/backup_policy/*"
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
# Create backup vault
#####

resource "aws_backup_vault" "organization_backup_vault" {
  name        = local.backup_vault_name
  kms_key_arn = aws_kms_key.backup_key.arn

  tags = merge(var.tags, {
    "Purpose" = "Organization Backup Vault"
    "Region"  = var.region
  })
}

resource "aws_kms_key" "backup_key" {
  description             = "KMS key for backup vault encryption"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    "Purpose" = "Backup Encryption Key"
  })
}

resource "aws_kms_alias" "backup_key_alias" {
  name          = "alias/backup-vault-key"
  target_key_id = aws_kms_key.backup_key.key_id
}

#####
# Create backup plan
#####

resource "aws_backup_plan" "organization_backup_plan" {
  name = "organization-backup-policy"

  rule {
    rule_name         = "daily_backups"
    target_vault_name = aws_backup_vault.organization_backup_vault.name
    schedule          = "cron(0 2 ? * 4 *)" # Every Thursday at 2:00 AM UTC

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }

    recovery_point_tags = merge(var.tags, {
      "BackupPlan" = "organization-backup-policy"
    })
  }

  tags = merge(var.tags, {
    "Purpose" = "Organization Backup Plan"
  })
}

#####
# Create backup selection
#####

resource "aws_backup_selection" "organization_backup_selection" {
  iam_role_arn = aws_iam_role.backup_selection_role.arn
  name         = "organization-backup-selection"
  plan_id      = aws_backup_plan.organization_backup_plan.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }

  depends_on = [
    aws_organizations_resource_policy.allow_delegated_backup_administrator
  ]
}
