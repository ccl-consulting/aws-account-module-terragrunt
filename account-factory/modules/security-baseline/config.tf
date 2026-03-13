# AWS Config Configuration
# Enables AWS Config recorder, delivery channel, and deploys specified Config rules
# Requirement 3.5: Configure AWS Config rules for compliance monitoring

# AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0

  name     = "account-factory-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true

    recording_strategy {
      use_only = "ALL_SUPPORTED_RESOURCE_TYPES"
    }
  }
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "account-factory-config-delivery"
  s3_bucket_name = "account-factory-config-${var.logging_account_id}"
  s3_key_prefix  = "config/${var.account_id}"
  sns_topic_arn  = "arn:aws:sns:${data.aws_region.current.name}:${var.logging_account_id}:account-factory-config-topic"

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Start the Config Recorder
resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# AWS Config Aggregator (sends data to security account)
resource "aws_config_configuration_aggregator" "security_account" {
  count = var.enable_config ? 1 : 0

  name = "account-factory-aggregator"

  account_aggregation_source {
    account_ids = [var.security_account_id]
    all_regions = true
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Managed Config Rules

# Ensure IAM password policy requires minimum length
resource "aws_config_config_rule" "iam_password_policy" {
  count = var.enable_config && contains(var.config_rules, "iam-password-policy") ? 1 : 0

  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireSymbols             = true
    RequireNumbers             = true
    MinimumPasswordLength      = 14
    PasswordReusePrevention    = 24
    MaxPasswordAge             = 90
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure MFA is enabled for root account
resource "aws_config_config_rule" "root_account_mfa" {
  count = var.enable_config && contains(var.config_rules, "root-account-mfa-enabled") ? 1 : 0

  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure CloudTrail is enabled
resource "aws_config_config_rule" "cloudtrail_enabled" {
  count = var.enable_config && contains(var.config_rules, "cloudtrail-enabled") ? 1 : 0

  name = "cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure S3 buckets have encryption enabled
resource "aws_config_config_rule" "s3_bucket_encryption" {
  count = var.enable_config && contains(var.config_rules, "s3-bucket-server-side-encryption-enabled") ? 1 : 0

  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure S3 buckets have versioning enabled
resource "aws_config_config_rule" "s3_bucket_versioning" {
  count = var.enable_config && contains(var.config_rules, "s3-bucket-versioning-enabled") ? 1 : 0

  name = "s3-bucket-versioning-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure S3 buckets block public access
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  count = var.enable_config && contains(var.config_rules, "s3-bucket-public-read-prohibited") ? 1 : 0

  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure S3 buckets block public write access
resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  count = var.enable_config && contains(var.config_rules, "s3-bucket-public-write-prohibited") ? 1 : 0

  name = "s3-bucket-public-write-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure EBS volumes are encrypted
resource "aws_config_config_rule" "encrypted_volumes" {
  count = var.enable_config && contains(var.config_rules, "encrypted-volumes") ? 1 : 0

  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure RDS instances are encrypted
resource "aws_config_config_rule" "rds_storage_encrypted" {
  count = var.enable_config && contains(var.config_rules, "rds-storage-encrypted") ? 1 : 0

  name = "rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure RDS instances have backup enabled
resource "aws_config_config_rule" "rds_backup_enabled" {
  count = var.enable_config && contains(var.config_rules, "db-instance-backup-enabled") ? 1 : 0

  name = "db-instance-backup-enabled"

  source {
    owner             = "AWS"
    source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure EC2 instances are managed by Systems Manager
resource "aws_config_config_rule" "ec2_managed_instance" {
  count = var.enable_config && contains(var.config_rules, "ec2-instance-managed-by-systems-manager") ? 1 : 0

  name = "ec2-instance-managed-by-systems-manager"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure VPC flow logging is enabled
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  count = var.enable_config && contains(var.config_rules, "vpc-flow-logs-enabled") ? 1 : 0

  name = "vpc-flow-logs-enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure security groups don't allow unrestricted ingress
resource "aws_config_config_rule" "restricted_ssh" {
  count = var.enable_config && contains(var.config_rules, "restricted-ssh") ? 1 : 0

  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure security groups don't allow unrestricted RDP
resource "aws_config_config_rule" "restricted_rdp" {
  count = var.enable_config && contains(var.config_rules, "restricted-common-ports") ? 1 : 0

  name = "restricted-common-ports"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({
    blockedPort1 = "20"
    blockedPort2 = "21"
    blockedPort3 = "3389"
    blockedPort4 = "3306"
    blockedPort5 = "5432"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure IAM users have MFA enabled
resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  count = var.enable_config && contains(var.config_rules, "iam-user-mfa-enabled") ? 1 : 0

  name = "iam-user-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure IAM policies are not attached to users
resource "aws_config_config_rule" "iam_user_no_policies" {
  count = var.enable_config && contains(var.config_rules, "iam-user-no-policies-check") ? 1 : 0

  name = "iam-user-no-policies-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_NO_POLICIES_CHECK"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure access keys are rotated
resource "aws_config_config_rule" "access_keys_rotated" {
  count = var.enable_config && contains(var.config_rules, "access-keys-rotated") ? 1 : 0

  name = "access-keys-rotated"

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  input_parameters = jsonencode({
    maxAccessKeyAge = "90"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# Ensure unused IAM credentials are removed
resource "aws_config_config_rule" "iam_user_unused_credentials" {
  count = var.enable_config && contains(var.config_rules, "iam-user-unused-credentials-check") ? 1 : 0

  name = "iam-user-unused-credentials-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }

  input_parameters = jsonencode({
    maxCredentialUsageAge = "90"
  })

  depends_on = [aws_config_configuration_recorder.main]
}
