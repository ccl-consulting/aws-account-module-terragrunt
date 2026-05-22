resource "aws_organizations_policy" "scps" {
  for_each    = var.scps
  name        = each.value.name
  description = each.value.description
  content     = each.value.content
  type        = "SERVICE_CONTROL_POLICY"
}

locals {
  _scp_ou_map = { for ou in 
  [
    aws_organizations_organizational_unit.suspended,
    aws_organizations_organizational_unit.security,
    aws_organizations_organizational_unit.common_services,
    aws_organizations_organizational_unit.workloads,
    aws_organizations_organizational_unit.workloads_prod,
    aws_organizations_organizational_unit.workloads_staging,
    aws_organizations_organizational_unit.workloads_dev,
  ] : "ou:${ou.name}" => ou.id }

  # Tous les comptes de l'org (gérés ou non par ce module) — permet de cibler
  # n'importe quel compte individuel par son nom, quelle que soit son OU
  _scp_account_map = {
    for acc in data.aws_organizations_organization.org.accounts : "account:${acc.name}" => acc.id
  }

  _scp_target_map = merge(local._scp_ou_map, local._scp_account_map)

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
