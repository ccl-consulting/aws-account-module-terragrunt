# Use existing organization instead of creating a new one
data "aws_organizations_organization" "org" {}

## OU

resource "aws_organizations_organizational_unit" "suspended" {
  name      = "Suspended"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "common_services" {
  name      = "Common Services"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "workloads_staging" {
  name      = "Staging"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "workloads_dev" {
  name      = "Dev"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

## Global accounts (mandatory)

resource "aws_organizations_account" "logging" {
  name      = "Logging"
  email     = "${var.email_local_part}_logging@${var.email_domain}"
  parent_id = data.aws_organizations_organization.org.roots[0].id

  close_on_deletion = true

  lifecycle {
    ignore_changes = [parent_id]
  }
}

resource "aws_organizations_account" "security" {
  name      = "Security"
  email     = "${var.email_local_part}_security@${var.email_domain}"
  parent_id = data.aws_organizations_organization.org.roots[0].id

  close_on_deletion = true

  lifecycle {
    ignore_changes = [parent_id]
  }
}

resource "aws_organizations_account" "backups" {
  name      = "Backups"
  email     = "${var.email_local_part}_backups@${var.email_domain}"
  parent_id = aws_organizations_organizational_unit.common_services.id

  close_on_deletion = true
}

# # RBL TO VALIDATE WITH GGU: Not needed as management account is already created
# resource "aws_organizations_account" "management" {
#   name      = "Management"
#   email     = "${var.email_local_part}_management@${var.email_domain}"
#   parent_id = aws_organizations_organizational_unit.common_services.id

#   close_on_deletion = true
# }


# Workloads accounts

resource "aws_organizations_account" "workloads_prod" {
  count     = length(var.org_accounts.workloads.prod)
  name      = var.org_accounts.workloads.prod[count.index]
  email     = "${var.email_local_part}_${var.org_accounts.workloads.prod[count.index]}@${var.email_domain}"
  parent_id = aws_organizations_organizational_unit.workloads_prod.id

  close_on_deletion = true
}

resource "aws_organizations_account" "workloads_staging" {
  count     = length(var.org_accounts.workloads.staging)
  name      = var.org_accounts.workloads.staging[count.index]
  email     = "${var.email_local_part}_${var.org_accounts.workloads.staging[count.index]}@${var.email_domain}"
  parent_id = aws_organizations_organizational_unit.workloads_staging.id

  close_on_deletion = true
}

resource "aws_organizations_account" "workloads_dev" {
  count     = length(var.org_accounts.workloads.dev)
  name      = var.org_accounts.workloads.dev[count.index]
  email     = "${var.email_local_part}_${var.org_accounts.workloads.dev[count.index]}@${var.email_domain}"
  parent_id = aws_organizations_organizational_unit.workloads_dev.id

  close_on_deletion = true
}

resource "aws_organizations_account" "common_services" {
  count     = length(var.org_accounts.common_services)
  name      = var.org_accounts.common_services[count.index]
  email     = "${var.email_local_part}_${var.org_accounts.common_services[count.index]}@${var.email_domain}"
  parent_id = aws_organizations_organizational_unit.common_services.id

  close_on_deletion = true
}

locals {
  workload_accounts = concat(
    aws_organizations_account.workloads_dev[*],
    aws_organizations_account.workloads_staging[*],
    aws_organizations_account.workloads_prod[*]
  )

  landing_zone_accounts = [
    aws_organizations_account.backups,
    aws_organizations_account.logging,
    #    aws_organizations_account.management,
    aws_organizations_account.security
  ]

  all_accounts = concat(
    local.workload_accounts,
    local.landing_zone_accounts,
    aws_organizations_account.common_services[*]
  )
}

output "all_accounts" {
  description = "List of all AWS organization accounts created by this module"
  value       = local.all_accounts
}

output "workload_accounts" {
  description = "List of workload accounts (production, staging, development)"
  value       = local.workload_accounts
}
