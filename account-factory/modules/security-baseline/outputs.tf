# Security Baseline Module Outputs
# Implementation: Task 5

# IAM Role Outputs
output "iam_roles" {
  description = "Map of created IAM role ARNs"
  value = {
    cross_account_admin    = aws_iam_role.cross_account_admin.arn
    cross_account_readonly = aws_iam_role.cross_account_readonly.arn
    security_tooling       = aws_iam_role.security_tooling.arn
    break_glass            = aws_iam_role.break_glass.arn
    cloudtrail             = var.enable_cloudtrail ? aws_iam_role.cloudtrail[0].arn : null
    config                 = var.enable_config ? aws_iam_role.config[0].arn : null
  }
}

# Security Hub Outputs
output "security_hub_arn" {
  description = "ARN of the Security Hub account"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].arn : null
}

output "security_hub_enabled" {
  description = "Whether Security Hub is enabled"
  value       = var.enable_security_hub
}

output "security_hub_standards" {
  description = "List of enabled Security Hub compliance standards"
  value       = var.enable_security_hub ? var.compliance_standards : []
}

# GuardDuty Outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_detector_arn" {
  description = "ARN of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
}

output "guardduty_enabled" {
  description = "Whether GuardDuty is enabled"
  value       = var.enable_guardduty
}

# AWS Config Outputs
output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
}

output "config_recorder_arn" {
  description = "ARN of the AWS Config recorder"
  value       = var.enable_config ? "arn:aws:config:${data.aws_region.current.name}:${var.account_id}:config-recorder/${aws_config_configuration_recorder.main[0].name}" : null
}

output "config_enabled" {
  description = "Whether AWS Config is enabled"
  value       = var.enable_config
}

output "config_rules_deployed" {
  description = "List of deployed AWS Config rules"
  value       = var.enable_config ? var.config_rules : []
}

# CloudTrail Outputs
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
}

output "cloudtrail_enabled" {
  description = "Whether CloudTrail is enabled"
  value       = var.enable_cloudtrail
}

output "cloudtrail_log_group" {
  description = "CloudWatch Log Group for CloudTrail logs"
  value       = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

# Summary Output
output "baseline_summary" {
  description = "Summary of deployed security baseline components"
  value = {
    account_id           = var.account_id
    account_name         = var.account_name
    security_hub         = var.enable_security_hub
    guardduty            = var.enable_guardduty
    config               = var.enable_config
    cloudtrail           = var.enable_cloudtrail
    iam_roles_created    = 4 + (var.enable_cloudtrail ? 1 : 0) + (var.enable_config ? 1 : 0)
    compliance_standards = var.enable_security_hub ? length(var.compliance_standards) : 0
    config_rules         = var.enable_config ? length(var.config_rules) : 0
  }
}
