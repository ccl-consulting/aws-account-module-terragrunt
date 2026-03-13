# AWS CloudTrail Configuration
# Deploys CloudTrail logging integrated with the centralized logging account
# Requirement 3.6: Deploy CloudTrail logging integrated with the centralized logging account

# CloudTrail for account-level logging
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "account-factory-trail"
  s3_bucket_name                = "account-factory-cloudtrail-${var.logging_account_id}"
  s3_key_prefix                 = "cloudtrail/${var.account_id}"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  # Send CloudTrail logs to CloudWatch Logs for real-time monitoring
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail[0].arn

  # Enable insights for anomaly detection
  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  insight_selector {
    insight_type = "ApiErrorRateInsight"
  }

  # Advanced event selectors for comprehensive logging
  advanced_event_selector {
    name = "Log all management events"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  advanced_event_selector {
    name = "Log all S3 data events"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }

  advanced_event_selector {
    name = "Log all Lambda data events"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::Lambda::Function"]
    }
  }

  # KMS encryption for CloudTrail logs
  kms_key_id = "arn:aws:kms:${data.aws_region.current.name}:${var.logging_account_id}:alias/account-factory-cloudtrail"

  # SNS topic for CloudTrail notifications
  sns_topic_name = "account-factory-cloudtrail-notifications"

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-CloudTrail"
      ManagedBy = "AccountFactory"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.cloudtrail,
    aws_iam_role.cloudtrail
  ]
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "/aws/cloudtrail/account-factory"
  retention_in_days = 90
  kms_key_id        = "arn:aws:kms:${data.aws_region.current.name}:${var.logging_account_id}:alias/account-factory-cloudwatch"

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-CloudTrail-Logs"
      ManagedBy = "AccountFactory"
    }
  )
}

# IAM Policy for CloudTrail to write to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "CloudTrailCloudWatchLogsPolicy"
  role = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailCreateLogStream"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      },
      {
        Sid    = "AWSCloudTrailPutLogEvents"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

# EventBridge rule to detect high-risk CloudTrail events
resource "aws_cloudwatch_event_rule" "high_risk_events" {
  count = var.enable_cloudtrail ? 1 : 0

  name        = "account-factory-high-risk-events"
  description = "Detect high-risk CloudTrail events"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "DeleteTrail",
        "StopLogging",
        "UpdateTrail",
        "DeleteFlowLogs",
        "DeleteDetector",
        "DisassociateFromMasterAccount",
        "DeleteMembers",
        "DeclineInvitations",
        "DisableSecurityHub",
        "DeleteConfigRule",
        "DeleteConfigurationRecorder",
        "DeleteDeliveryChannel",
        "StopConfigurationRecorder",
        "PutBucketPolicy",
        "PutBucketAcl",
        "DeleteBucketPolicy",
        "DeleteBucketEncryption"
      ]
    }
  })

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-HighRiskEvents"
      ManagedBy = "AccountFactory"
    }
  )
}

# EventBridge target to send high-risk events to SNS
resource "aws_cloudwatch_event_target" "high_risk_sns" {
  count = var.enable_cloudtrail ? 1 : 0

  rule      = aws_cloudwatch_event_rule.high_risk_events[0].name
  target_id = "SendToSNS"
  arn       = "arn:aws:sns:${data.aws_region.current.name}:${var.security_account_id}:account-factory-security-alerts"
}

# EventBridge rule to detect root account usage
resource "aws_cloudwatch_event_rule" "root_account_usage" {
  count = var.enable_cloudtrail ? 1 : 0

  name        = "account-factory-root-account-usage"
  description = "Detect root account usage"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["Root"]
      }
    }
  })

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-RootAccountUsage"
      ManagedBy = "AccountFactory"
    }
  )
}

# EventBridge target to send root account usage alerts to SNS
resource "aws_cloudwatch_event_target" "root_account_sns" {
  count = var.enable_cloudtrail ? 1 : 0

  rule      = aws_cloudwatch_event_rule.root_account_usage[0].name
  target_id = "SendToSNS"
  arn       = "arn:aws:sns:${data.aws_region.current.name}:${var.security_account_id}:account-factory-security-alerts"
}

# EventBridge rule to detect unauthorized API calls
resource "aws_cloudwatch_event_rule" "unauthorized_api_calls" {
  count = var.enable_cloudtrail ? 1 : 0

  name        = "account-factory-unauthorized-api-calls"
  description = "Detect unauthorized API calls"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      errorCode = [
        "AccessDenied",
        "UnauthorizedOperation"
      ]
    }
  })

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-UnauthorizedAPICalls"
      ManagedBy = "AccountFactory"
    }
  )
}

# EventBridge target to send unauthorized API call alerts to SNS
resource "aws_cloudwatch_event_target" "unauthorized_api_sns" {
  count = var.enable_cloudtrail ? 1 : 0

  rule      = aws_cloudwatch_event_rule.unauthorized_api_calls[0].name
  target_id = "SendToSNS"
  arn       = "arn:aws:sns:${data.aws_region.current.name}:${var.security_account_id}:account-factory-security-alerts"
}

# CloudWatch Metric Filter for failed console sign-ins
resource "aws_cloudwatch_log_metric_filter" "failed_console_signin" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "FailedConsoleSignIn"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"

  metric_transformation {
    name      = "FailedConsoleSignInCount"
    namespace = "AccountFactory/Security"
    value     = "1"
  }
}

# CloudWatch Alarm for failed console sign-ins
resource "aws_cloudwatch_metric_alarm" "failed_console_signin" {
  count = var.enable_cloudtrail ? 1 : 0

  alarm_name          = "account-factory-failed-console-signin"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedConsoleSignInCount"
  namespace           = "AccountFactory/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Alert on multiple failed console sign-in attempts"
  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${var.security_account_id}:account-factory-security-alerts"]

  tags = merge(
    var.tags,
    {
      Name      = "AccountFactory-FailedConsoleSignIn"
      ManagedBy = "AccountFactory"
    }
  )
}
