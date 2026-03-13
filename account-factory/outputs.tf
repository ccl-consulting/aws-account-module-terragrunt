# Account Catalog
output "account_catalog" {
  description = "Complete catalog of all managed accounts"
  value = {
    for name, account in aws_organizations_account.accounts : name => {
      id                        = account.id
      name                      = account.name
      email                     = account.email
      organizational_unit       = account.parent_id
      security_baseline         = var.accounts[name].security_baseline
      security_baseline_version = local.baseline_versions[name].security_baseline_version
      network_baseline          = var.accounts[name].network_baseline
      network_baseline_version  = local.baseline_versions[name].network_baseline_version
      tags                      = account.tags_all
      status                    = account.status
      close_on_deletion         = var.accounts[name].close_on_deletion
      delegated_services        = var.accounts[name].delegated_services
    }
  }
}

# Accounts by Environment
output "accounts_by_environment" {
  description = "Accounts grouped by environment tag"
  value = {
    for env in distinct([for a in var.accounts : lookup(a.tags, "Environment", "unknown")]) :
    env => [
      for name, account in var.accounts :
      aws_organizations_account.accounts[name].id
      if lookup(account.tags, "Environment", "unknown") == env
    ]
  }
}

# Accounts by OU
output "accounts_by_ou" {
  description = "Accounts grouped by organizational unit"
  value = {
    for ou in distinct([for a in var.accounts : a.organizational_unit]) :
    ou => [
      for name, account in var.accounts :
      aws_organizations_account.accounts[name].id
      if account.organizational_unit == ou
    ]
  }
}

# Accounts by Baseline Type
output "accounts_by_baseline_type" {
  description = "Accounts grouped by security and network baseline types"
  value = {
    security_baselines = {
      for baseline in distinct([for a in var.accounts : a.security_baseline if a.security_baseline != "none" && a.security_baseline != ""]) :
      baseline => [
        for name, account in var.accounts :
        aws_organizations_account.accounts[name].id
        if account.security_baseline == baseline
      ]
    }
    network_baselines = {
      for baseline in distinct([for a in var.accounts : a.network_baseline if a.network_baseline != "none" && a.network_baseline != ""]) :
      baseline => [
        for name, account in var.accounts :
        aws_organizations_account.accounts[name].id
        if account.network_baseline == baseline
      ]
    }
  }
}

# Baseline Deployment Status
output "baseline_deployment_status" {
  description = "Status of baseline deployments per account"
  value = {
    security_baselines = length(aws_cloudformation_stack_set_instance.security_baseline) > 0 ? {
      for name, stackset in aws_cloudformation_stack_set_instance.security_baseline :
      name => {
        stack_set_id = stackset.stack_set_name
        status       = stackset.status
        account_id   = stackset.account_id
      }
    } : {}
    network_baselines = length(aws_cloudformation_stack_set_instance.network_baseline) > 0 ? {
      for name, stackset in aws_cloudformation_stack_set_instance.network_baseline :
      name => {
        stack_set_id = stackset.stack_set_name
        status       = stackset.status
        account_id   = stackset.account_id
      }
    } : {}
  }
}

# Delegated Administrators
output "delegated_administrators" {
  description = "Map of AWS services to their delegated administrator accounts"
  value = length(aws_organizations_delegated_administrator.admins) > 0 ? {
    for service, admin in aws_organizations_delegated_administrator.admins :
    service => admin.account_id
  } : {}
}

# Account IDs by Name (for easy reference)
output "account_ids" {
  description = "Map of account names to account IDs"
  value = {
    for name, account in aws_organizations_account.accounts :
    name => account.id
  }
}

# Account ARNs by Name
output "account_arns" {
  description = "Map of account names to account ARNs"
  value = {
    for name, account in aws_organizations_account.accounts :
    name => account.arn
  }
}

# Account Filtering Functions
# Filter accounts by specific tag key-value pairs
output "accounts_by_tag" {
  description = "Accounts grouped by all unique tag key-value combinations for filtering"
  value = {
    for tag_key in distinct(flatten([for a in var.accounts : keys(a.tags)])) :
    tag_key => {
      for tag_value in distinct([for a in var.accounts : lookup(a.tags, tag_key, null) if lookup(a.tags, tag_key, null) != null]) :
      tag_value => [
        for name, account in var.accounts :
        aws_organizations_account.accounts[name].id
        if lookup(account.tags, tag_key, null) == tag_value
      ]
    }
  }
}

# Filter accounts by baseline version
output "accounts_by_baseline_version" {
  description = "Accounts grouped by security and network baseline versions"
  value = {
    security_baseline_versions = {
      for version in distinct([for name, account in var.accounts : account.baseline_version if account.security_baseline != "none" && account.security_baseline != ""]) :
      version => [
        for name, account in var.accounts :
        aws_organizations_account.accounts[name].id
        if account.baseline_version == version && account.security_baseline != "none" && account.security_baseline != ""
      ]
    }
    network_baseline_versions = {
      for version in distinct([for name, account in var.accounts : account.baseline_version if account.network_baseline != "none" && account.network_baseline != ""]) :
      version => [
        for name, account in var.accounts :
        aws_organizations_account.accounts[name].id
        if account.baseline_version == version && account.network_baseline != "none" && account.network_baseline != ""
      ]
    }
  }
}

# Combined filter: accounts by OU and baseline version
output "accounts_by_ou_and_baseline_version" {
  description = "Accounts grouped by organizational unit and baseline version for targeted updates"
  value = {
    for ou in distinct([for a in var.accounts : a.organizational_unit]) :
    ou => {
      for version in distinct([for name, account in var.accounts : account.baseline_version if account.organizational_unit == ou]) :
      version => [
        for name, account in var.accounts :
        aws_organizations_account.accounts[name].id
        if account.organizational_unit == ou && account.baseline_version == version
      ]
    }
  }
}
