# Amazon GuardDuty Configuration
# Enables GuardDuty with findings exported to the security account
# Requirement 3.4: Enable Amazon GuardDuty with findings exported to the security account

# Enable GuardDuty detector
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-GuardDuty"
      ManagedBy = "AccountFactory"
    }
  )
}

# Configure GuardDuty to export findings to S3 in the logging account
resource "aws_guardduty_publishing_destination" "s3" {
  count = var.enable_guardduty ? 1 : 0

  detector_id     = aws_guardduty_detector.main[0].id
  destination_arn = "arn:aws:s3:::account-factory-guardduty-${var.logging_account_id}"
  kms_key_arn     = "arn:aws:kms:${data.aws_region.current.name}:${var.logging_account_id}:alias/account-factory-guardduty"

  destination_type = "S3"

  depends_on = [aws_guardduty_detector.main]
}

# Enable GuardDuty threat intelligence sets
# This uses AWS-managed threat intelligence feeds
resource "aws_guardduty_threatintelset" "aws_managed" {
  count = var.enable_guardduty ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main[0].id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/aws-guardduty-threat-intel-feeds/threat-intel-set.txt"
  name        = "AWS-Managed-Threat-Intel"

  depends_on = [aws_guardduty_detector.main]
}

# Enable GuardDuty IP sets for trusted IPs (optional)
# Organizations can customize this to whitelist known good IPs
resource "aws_guardduty_ipset" "trusted_ips" {
  count = var.enable_guardduty ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main[0].id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/account-factory-guardduty-${var.logging_account_id}/trusted-ips.txt"
  name        = "TrustedIPs"

  depends_on = [aws_guardduty_detector.main]

  lifecycle {
    # Ignore changes to location as it may be updated externally
    ignore_changes = [location]
  }
}

# Configure GuardDuty filter to suppress low-severity findings (optional)
resource "aws_guardduty_filter" "low_severity" {
  count = var.enable_guardduty ? 1 : 0

  name        = "SuppressLowSeverity"
  action      = "ARCHIVE"
  detector_id = aws_guardduty_detector.main[0].id
  rank        = 1

  finding_criteria {
    criterion {
      field  = "severity"
      equals = ["1", "2", "3"]
    }
  }

  depends_on = [aws_guardduty_detector.main]
}

# Enable EKS Protection (if EKS is used in the account)
resource "aws_guardduty_detector_feature" "eks_protection" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_detector.main]
}

# Enable RDS Protection
resource "aws_guardduty_detector_feature" "rds_protection" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_detector.main]
}

# Enable Lambda Protection
resource "aws_guardduty_detector_feature" "lambda_protection" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_detector.main]
}

# Enable EBS Malware Protection
resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"

  depends_on = [aws_guardduty_detector.main]
}

# Enable S3 Protection
resource "aws_guardduty_detector_feature" "s3_protection" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_detector.main]
}

# Enable EKS Runtime Monitoring
resource "aws_guardduty_detector_feature" "eks_runtime_monitoring" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "EKS_RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "ENABLED"
  }

  depends_on = [aws_guardduty_detector.main]
}

# Enable Runtime Monitoring for EC2
resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.main[0].id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "ENABLED"
  }

  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "ENABLED"
  }

  depends_on = [aws_guardduty_detector.main]
}
