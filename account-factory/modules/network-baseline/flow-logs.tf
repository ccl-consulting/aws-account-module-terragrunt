# VPC Flow Logs
# Configures VPC Flow Logs with delivery to centralized logging account
# Requirements: 4.6

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.account_name}"
  retention_in_days = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-vpc-flow-logs"
    }
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.account_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-vpc-flow-logs-role"
    }
  )
}

# IAM Policy for VPC Flow Logs to write to CloudWatch
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.account_name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-vpc-flow-log"
    }
  )
}

# Optional: S3 Bucket for Flow Logs (cross-account to logging account)
# This would require additional configuration in the logging account
# to create the S3 bucket and bucket policy allowing cross-account writes

# Data source for logging account S3 bucket (if exists)
data "aws_s3_bucket" "logging" {
  count = var.enable_flow_logs && var.logging_account_id != "" ? 1 : 0

  bucket = "vpc-flow-logs-${var.logging_account_id}"

  # This assumes the logging account has a bucket with this naming convention
  # In a real implementation, this would be passed as a variable
  provider = aws.logging
}

# Alternative Flow Logs to S3 (commented out - requires cross-account setup)
# resource "aws_flow_log" "s3" {
#   count = var.enable_flow_logs && var.logging_account_id != "" ? 1 : 0
#
#   vpc_id                   = aws_vpc.main.id
#   traffic_type             = "ALL"
#   log_destination_type     = "s3"
#   log_destination          = data.aws_s3_bucket.logging[0].arn
#   log_format               = "$${account-id} $${action} $${bytes} $${dstaddr} $${dstport} $${end} $${flow-direction} $${instance-id} $${interface-id} $${log-status} $${packets} $${pkt-dstaddr} $${pkt-srcaddr} $${protocol} $${srcaddr} $${srcport} $${start} $${sublocation-id} $${sublocation-type} $${subnet-id} $${tcp-flags} $${traffic-path} $${type} $${version} $${vpc-id}"
#   max_aggregation_interval = 60
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.account_name}-vpc-flow-log-s3"
#     }
#   )
# }
