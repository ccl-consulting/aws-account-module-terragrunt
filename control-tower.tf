resource "aws_iam_role" "control_tower_admin" {
  name               = "AWSControlTowerAdmin"
  assume_role_policy = data.aws_iam_policy_document.control_tower_admin.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "control_tower_admin" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["controltower.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "control_tower_admin_policy" {
  name   = "AWSControlTowerAdminPolicy"
  role   = aws_iam_role.control_tower_admin.id
  policy = data.aws_iam_policy_document.control_tower_admin_policy_content.json
}

data "aws_iam_policy_document" "control_tower_admin_policy_content" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "control_tower_service_role_policy" {
  role       = aws_iam_role.control_tower_admin.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSControlTowerServiceRolePolicy"
}

resource "aws_iam_role" "control_tower_cloudtrail_role" {
  name               = "AWSControlTowerCloudTrailRole"
  assume_role_policy = data.aws_iam_policy_document.control_tower_cloudtrail_role.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "control_tower_cloudtrail_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "control_tower_cloudtrail_role_policy" {
  name   = "AWSControlTowerCloudTrailRolePolicy"
  role   = aws_iam_role.control_tower_cloudtrail_role.id
  policy = data.aws_iam_policy_document.control_tower_cloudtrail_role_policy_content.json
}

data "aws_iam_policy_document" "control_tower_cloudtrail_role_policy_content" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream"]
    resources = ["arn:aws:logs:*:*:log-group:aws-controltower/CloudTrailLogs:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:log-group:aws-controltower/CloudTrailLogs:*"]
  }
}

resource "aws_iam_role" "aws_control_tower_stackset_role" {
  name               = "AWSControlTowerStackSetRole"
  assume_role_policy = data.aws_iam_policy_document.control_tower_stackset_role.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "control_tower_stackset_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "control_tower_stackset_role_policy" {
  name   = "AWSControlTowerStackSetRolePolicy"
  role   = aws_iam_role.aws_control_tower_stackset_role.id
  policy = data.aws_iam_policy_document.control_tower_stackset_role_policy_content.json
}

data "aws_iam_policy_document" "control_tower_stackset_role_policy_content" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/AWSControlTowerExecution"]
  }
}

resource "aws_iam_role" "control_tower_config_aggregator_role_for_organizations" {
  name               = "AWSControlTowerConfigAggregatorRoleForOrganizations"
  assume_role_policy = data.aws_iam_policy_document.control_tower_config_aggregator_role_for_organizations_role.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "control_tower_config_aggregator_role_for_organizations_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "control_tower_config_role_for_organization_service_role" {
  role       = aws_iam_role.control_tower_config_aggregator_role_for_organizations.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_controltower_landing_zone" "zone" {
  manifest_json = templatefile("${path.module}/template/landingzonemanifest.tftpl", { governed_regions = var.governed_regions, logging_account_id = aws_organizations_account.logging.id, security_account_id = aws_organizations_account.security.id })
  version       = "3.3"

  depends_on = [
    data.aws_organizations_organization.org,
    aws_iam_role.control_tower_admin,
    aws_iam_role.control_tower_cloudtrail_role,
    aws_iam_role.control_tower_config_aggregator_role_for_organizations,
    aws_iam_role_policy.control_tower_stackset_role_policy,
    aws_iam_role_policy_attachment.control_tower_config_role_for_organization_service_role,
    aws_iam_role_policy_attachment.control_tower_service_role_policy
  ]

  # Needed to avoid retentionDays = "60" -> 60 at each apply.
  # Have not figured out yet why AWS gives syntax error with quotes in .tftpl
  lifecycle {
    ignore_changes = [
      manifest_json
    ]
  }
}
