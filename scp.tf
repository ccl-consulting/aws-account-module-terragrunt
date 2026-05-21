resource "aws_organizations_policy" "scps" {
  for_each    = var.scps
  name        = each.value.name
  description = each.value.description
  content     = each.value.content
  type        = "SERVICE_CONTROL_POLICY"
}

locals {
  _scp_target_map = {
    "ou:workloads"         = aws_organizations_organizational_unit.workloads.id
    "ou:workloads_prod"    = aws_organizations_organizational_unit.workloads_prod.id
    "ou:workloads_staging" = aws_organizations_organizational_unit.workloads_staging.id
    "ou:workloads_dev"     = aws_organizations_organizational_unit.workloads_dev.id
    "ou:security"          = aws_organizations_organizational_unit.security.id
    "ou:common_services"   = aws_organizations_organizational_unit.common_services.id
    "ou:suspended"         = aws_organizations_organizational_unit.suspended.id
    "account:logging"      = aws_organizations_account.logging.id
    "account:security"     = aws_organizations_account.security.id
    "account:backups"      = aws_organizations_account.backups.id
  }

  _scp_attachments = flatten([
    for scp_key, scp in var.scps : [
      for target in scp.targets : {
        key       = "${scp_key}::${target}"
        policy_id = aws_organizations_policy.scps[scp_key].id
        target_id = local._scp_target_map[target]
      }
    ]
  ])
}

resource "aws_organizations_policy_attachment" "scps" {
  for_each  = { for att in local._scp_attachments : att.key => att }
  policy_id = each.value.policy_id
  target_id = each.value.target_id
}
