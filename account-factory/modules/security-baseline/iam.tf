# IAM Roles for Security Baseline
# Creates cross-account access roles, security tooling roles, and break-glass access roles
# Requirement 3.2: Include IAM roles for cross-account access, security tooling, and break-glass access

# Cross-Account Access Role
# Allows the management account to assume this role for administrative tasks
resource "aws_iam_role" "cross_account_admin" {
  name        = "AccountFactory-CrossAccountAdmin"
  description = "Cross-account administrative access role for Account Factory"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "AccountFactory-${var.account_id}"
          }
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-CrossAccountAdmin"
      Purpose   = "Cross-account administrative access"
      ManagedBy = "AccountFactory"
    }
  )
}

# Cross-Account Read-Only Role
# Provides read-only access for auditing and monitoring
resource "aws_iam_role" "cross_account_readonly" {
  name        = "AccountFactory-CrossAccountReadOnly"
  description = "Cross-account read-only access role for auditing"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-CrossAccountReadOnly"
      Purpose   = "Cross-account read-only access"
      ManagedBy = "AccountFactory"
    }
  )
}

# Security Tooling Role
# Used by security tools (Security Hub, GuardDuty, etc.) for cross-account access
resource "aws_iam_role" "security_tooling" {
  name        = "AccountFactory-SecurityTooling"
  description = "Role for security tooling integration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:root"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "securityhub.amazonaws.com",
            "guardduty.amazonaws.com",
            "config.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-SecurityTooling"
      Purpose   = "Security tooling integration"
      ManagedBy = "AccountFactory"
    }
  )
}

# Security Tooling Policy
# Grants permissions for security services to operate
resource "aws_iam_role_policy" "security_tooling" {
  name = "SecurityToolingPermissions"
  role = aws_iam_role.security_tooling.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "securityhub:*",
          "guardduty:*",
          "config:*",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:${var.account_id}:log-group:/aws/securityhub/*"
      }
    ]
  })
}

# Break-Glass Access Role
# Emergency access role with full administrative permissions
resource "aws_iam_role" "break_glass" {
  name        = "AccountFactory-BreakGlass"
  description = "Emergency break-glass access role with full administrative permissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "BreakGlass-${var.account_id}"
          }
          IpAddress = {
            # Restrict to specific IP ranges for additional security
            # This should be customized based on organization requirements
            "aws:SourceIp" = ["0.0.0.0/0"]
          }
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  max_session_duration = 3600 # 1 hour maximum session

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-BreakGlass"
      Purpose   = "Emergency administrative access"
      ManagedBy = "AccountFactory"
      Critical  = "true"
    }
  )
}

# CloudTrail Role for logging
# Allows CloudTrail to write logs to the centralized logging account
resource "aws_iam_role" "cloudtrail" {
  count       = var.enable_cloudtrail ? 1 : 0
  name        = "AccountFactory-CloudTrailRole"
  description = "Role for CloudTrail to write logs to centralized logging account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-CloudTrailRole"
      Purpose   = "CloudTrail logging"
      ManagedBy = "AccountFactory"
    }
  )
}

# Config Role for compliance monitoring
# Allows AWS Config to record configuration changes
resource "aws_iam_role" "config" {
  count       = var.enable_config ? 1 : 0
  name        = "AccountFactory-ConfigRole"
  description = "Role for AWS Config to record configuration changes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/ConfigRole"
  ]

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-ConfigRole"
      Purpose   = "AWS Config compliance monitoring"
      ManagedBy = "AccountFactory"
    }
  )
}

# Config Role Policy for S3 and SNS access
resource "aws_iam_role_policy" "config" {
  count = var.enable_config ? 1 : 0
  name  = "ConfigDeliveryPermissions"
  role  = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::account-factory-config-${var.logging_account_id}",
          "arn:aws:s3:::account-factory-config-${var.logging_account_id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "arn:aws:sns:*:${var.logging_account_id}:account-factory-config-topic"
      }
    ]
  })
}
