# CloudFormation StackSets for Baseline Deployment
# This file contains StackSet resources for security and network baselines
# Implementation: Tasks 8, 9, 10

# Security Baseline StackSet
resource "aws_cloudformation_stack_set" "security_baseline" {
  for_each = var.security_baselines

  name             = "account-factory-security-baseline-${each.key}"
  description      = "Security baseline ${each.key} version ${each.value.version}"
  permission_model = "SERVICE_MANAGED"

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  # Load CloudFormation template from file
  template_body = file("${path.module}/templates/security-baseline-stackset.yaml")

  # Parameters for the CloudFormation template
  parameters = {
    AccountName         = "placeholder" # Will be overridden per instance
    AccountId           = "placeholder" # Will be overridden per instance
    LoggingAccountId    = var.logging_account_id
    SecurityAccountId   = var.security_account_id
    EnableSecurityHub   = tostring(each.value.enable_security_hub)
    EnableGuardDuty     = tostring(each.value.enable_guardduty)
    EnableConfig        = tostring(each.value.enable_config)
    EnableCloudTrail    = tostring(each.value.enable_cloudtrail)
    ComplianceStandards = join(",", each.value.compliance_standards)
    ResourceTags        = "{}" # Will be overridden per instance with merged tags
  }

  # Configure update behavior - use update operations instead of recreation
  lifecycle {
    ignore_changes = [administration_role_arn]
    # Prevent destruction and recreation - always update in place
    create_before_destroy = false
  }

  # Operation preferences for updates
  operation_preferences {
    failure_tolerance_count      = 1
    max_concurrent_count         = 5
    region_concurrency_type      = "PARALLEL"
    failure_tolerance_percentage = null
    max_concurrent_percentage    = null
  }
}

# Security Baseline StackSet Instances
resource "aws_cloudformation_stack_set_instance" "security_baseline" {
  for_each = local.accounts_with_security_baseline

  stack_set_name = aws_cloudformation_stack_set.security_baseline[each.value.security_baseline].name

  # Deploy to all governed regions for security baseline
  deployment_targets {
    organizational_unit_ids = [local.account_ou_mapping[each.key]]
  }

  # Specify regions for deployment
  region = var.governed_regions[0] # Primary region for StackSet instance management

  # Override parameters per account
  parameter_overrides = {
    AccountName       = each.key
    AccountId         = aws_organizations_account.accounts[each.key].id
    LoggingAccountId  = var.logging_account_id
    SecurityAccountId = var.security_account_id
    # Pass merged tags as JSON string for baseline resources
    ResourceTags = jsonencode(local.baseline_resource_tags[each.key])
  }

  # Configure update operation preferences
  operation_preferences {
    failure_tolerance_count = 1
    max_concurrent_count    = 5
    region_concurrency_type = "PARALLEL"
  }

  # Ensure updates are performed in place
  lifecycle {
    create_before_destroy = false
  }

  depends_on = [aws_organizations_account.accounts]
}

# Network Baseline StackSet
resource "aws_cloudformation_stack_set" "network_baseline" {
  for_each = var.network_baselines

  name             = "account-factory-network-baseline-${each.key}"
  description      = "Network baseline ${each.key} version ${each.value.version}"
  permission_model = "SERVICE_MANAGED"

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  # Load CloudFormation template from file
  template_body = file("${path.module}/templates/network-baseline-stackset.yaml")

  # Parameters for the CloudFormation template
  parameters = {
    AccountName          = "placeholder" # Will be overridden per instance
    AccountId            = "placeholder" # Will be overridden per instance
    VpcCidr              = each.value.vpc_cidr
    AvailabilityZones    = tostring(each.value.availability_zones)
    EnableTransitGateway = tostring(each.value.enable_transit_gateway)
    TransitGatewayId     = var.existing_transit_gateway_id != "" ? var.existing_transit_gateway_id : ""
    EnableFlowLogs       = tostring(each.value.enable_flow_logs)
    LoggingAccountId     = var.logging_account_id
    ResourceTags         = "{}" # Will be overridden per instance with merged tags
  }

  # Configure update behavior - use update operations instead of recreation
  lifecycle {
    ignore_changes = [administration_role_arn]
    # Prevent destruction and recreation - always update in place
    create_before_destroy = false
  }

  # Operation preferences for updates
  operation_preferences {
    failure_tolerance_count      = 1
    max_concurrent_count         = 5
    region_concurrency_type      = "PARALLEL"
    failure_tolerance_percentage = null
    max_concurrent_percentage    = null
  }
}

# Network Baseline StackSet Instances
resource "aws_cloudformation_stack_set_instance" "network_baseline" {
  for_each = local.accounts_with_network_baseline

  stack_set_name = aws_cloudformation_stack_set.network_baseline[each.value.network_baseline].name

  # Deploy to account-specific regions for network baseline
  deployment_targets {
    organizational_unit_ids = [local.account_ou_mapping[each.key]]
  }

  # Specify regions for deployment
  region = length(local.account_regions[each.key]) > 0 ? local.account_regions[each.key][0] : var.governed_regions[0]

  # Override parameters per account
  parameter_overrides = {
    AccountName       = each.key
    AccountId         = aws_organizations_account.accounts[each.key].id
    VpcCidr           = var.network_baselines[each.value.network_baseline].vpc_cidr
    AvailabilityZones = tostring(var.network_baselines[each.value.network_baseline].availability_zones)
    LoggingAccountId  = var.logging_account_id
    # Pass merged tags as JSON string for baseline resources
    ResourceTags = jsonencode(local.baseline_resource_tags[each.key])
  }

  # Configure update operation preferences
  operation_preferences {
    failure_tolerance_count = 1
    max_concurrent_count    = 5
    region_concurrency_type = "PARALLEL"
  }

  # Ensure updates are performed in place
  lifecycle {
    create_before_destroy = false
  }

  depends_on = [aws_organizations_account.accounts]
}

# Cross-Account Execution Roles
# These roles are created in member accounts to allow StackSet execution
# Implementation: Task 10
# If use_existing_control_tower_roles is true, these roles are assumed to exist

resource "aws_iam_role" "stackset_execution" {
  for_each = var.use_existing_control_tower_roles ? {} : var.accounts

  name        = "AWSControlTowerExecution"
  description = "Execution role for CloudFormation StackSets deployed by Account Factory"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:role/service-role/AWSControlTowerStackSetRole"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.account_tags[each.key],
    {
      Name      = "AWSControlTowerExecution"
      Purpose   = "StackSet execution role"
      ManagedBy = "AccountFactory"
    }
  )
}

# Policy for security baseline deployment
resource "aws_iam_role_policy" "stackset_execution_security" {
  for_each = var.use_existing_control_tower_roles ? {} : var.accounts

  name = "SecurityBaselineDeployment"
  role = aws_iam_role.stackset_execution[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:EnableSecurityHub",
          "securityhub:DisableSecurityHub",
          "securityhub:UpdateSecurityHubConfiguration",
          "securityhub:BatchEnableStandards",
          "securityhub:BatchDisableStandards",
          "securityhub:CreateFindingAggregator",
          "securityhub:DeleteFindingAggregator",
          "securityhub:UpdateFindingAggregator",
          "securityhub:EnableImportFindingsForProduct",
          "securityhub:DisableImportFindingsForProduct"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "guardduty:CreateDetector",
          "guardduty:DeleteDetector",
          "guardduty:UpdateDetector",
          "guardduty:CreatePublishingDestination",
          "guardduty:DeletePublishingDestination",
          "guardduty:UpdatePublishingDestination",
          "guardduty:CreateThreatIntelSet",
          "guardduty:DeleteThreatIntelSet",
          "guardduty:UpdateThreatIntelSet",
          "guardduty:CreateIPSet",
          "guardduty:DeleteIPSet",
          "guardduty:UpdateIPSet",
          "guardduty:CreateFilter",
          "guardduty:DeleteFilter",
          "guardduty:UpdateFilter",
          "guardduty:UpdateDetectorFeature"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "config:PutConfigurationRecorder",
          "config:DeleteConfigurationRecorder",
          "config:PutDeliveryChannel",
          "config:DeleteDeliveryChannel",
          "config:StartConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "config:PutConfigurationAggregator",
          "config:DeleteConfigurationAggregator",
          "config:PutConfigRule",
          "config:DeleteConfigRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:CreateTrail",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
          "cloudtrail:StartLogging",
          "cloudtrail:StopLogging",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:PutInsightSelectors"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:CreateLogStream",
          "logs:DeleteLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:DeleteMetricFilter"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:DeleteRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:EnableRule",
          "events:DisableRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for network baseline deployment
resource "aws_iam_role_policy" "stackset_execution_network" {
  for_each = var.use_existing_control_tower_roles ? {} : var.accounts

  name = "NetworkBaselineDeployment"
  role = aws_iam_role.stackset_execution[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:DescribeVpcs",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:DescribeSubnets",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DescribeInternetGateways",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:DescribeAddresses",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:DescribeNatGateways",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:ReplaceRoute",
          "ec2:DescribeRouteTables",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateNetworkAcl",
          "ec2:DeleteNetworkAcl",
          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclAssociation",
          "ec2:DescribeNetworkAcls",
          "ec2:CreateFlowLogs",
          "ec2:DeleteFlowLogs",
          "ec2:DescribeFlowLogs",
          "ec2:CreateTransitGatewayVpcAttachment",
          "ec2:DeleteTransitGatewayVpcAttachment",
          "ec2:ModifyTransitGatewayVpcAttachment",
          "ec2:DescribeTransitGatewayVpcAttachments",
          "ec2:DescribeTransitGateways",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}
