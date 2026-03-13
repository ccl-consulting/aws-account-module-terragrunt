# Local values for computed transformations

locals {
  # Merge default tags with account-specific tags
  account_tags = {
    for name, account in var.accounts : name => merge(
      var.default_tags,
      account.tags,
      {
        "AccountName" = name
        "ManagedBy"   = "AccountFactory"
      }
    )
  }

  # Determine which tag validation to use: custom schema or default required_tags
  effective_required_tags = length(var.custom_tag_schema.required_keys) > 0 ? var.custom_tag_schema.required_keys : var.required_tags

  # Validate that all required tags are present
  accounts_with_required_tags = {
    for name, account in var.accounts : name => account
    if alltrue([for tag in local.effective_required_tags : contains(keys(merge(var.default_tags, account.tags)), tag)])
  }

  # Check for accounts missing required tags and generate error
  accounts_missing_required_tags = {
    for name, account in var.accounts : name => [
      for tag in local.effective_required_tags :
      tag if !contains(keys(merge(var.default_tags, account.tags)), tag)
    ]
    if length([
      for tag in local.effective_required_tags :
      tag if !contains(keys(merge(var.default_tags, account.tags)), tag)
    ]) > 0
  }

  # Validation: Fail if any accounts are missing required tags
  validate_required_tags = length(local.accounts_missing_required_tags) == 0 ? true : tobool(
    "Validation failed: The following accounts are missing required tags: ${jsonencode(local.accounts_missing_required_tags)}"
  )

  # Custom tag schema validation: Check if tags are in allowed_keys list (if specified)
  accounts_with_disallowed_tags = length(var.custom_tag_schema.allowed_keys) > 0 ? {
    for name, account in var.accounts : name => [
      for tag_key in keys(merge(var.default_tags, account.tags)) :
      tag_key if !contains(var.custom_tag_schema.allowed_keys, tag_key)
    ]
    if length([
      for tag_key in keys(merge(var.default_tags, account.tags)) :
      tag_key if !contains(var.custom_tag_schema.allowed_keys, tag_key)
    ]) > 0
  } : {}

  # Validation: Fail if any accounts have disallowed tags
  validate_allowed_tags = length(local.accounts_with_disallowed_tags) == 0 ? true : tobool(
    "Validation failed: The following accounts have tags not in the allowed_keys list: ${jsonencode(local.accounts_with_disallowed_tags)}"
  )

  # Custom tag schema validation: Check if tag values match required patterns
  accounts_with_invalid_tag_patterns = length(var.custom_tag_schema.key_patterns) > 0 ? {
    for name, account in var.accounts : name => {
      for tag_key, pattern in var.custom_tag_schema.key_patterns :
      tag_key => lookup(merge(var.default_tags, account.tags), tag_key, "")
      if contains(keys(merge(var.default_tags, account.tags)), tag_key) &&
      !can(regex(pattern, lookup(merge(var.default_tags, account.tags), tag_key, "")))
    }
    if length({
      for tag_key, pattern in var.custom_tag_schema.key_patterns :
      tag_key => lookup(merge(var.default_tags, account.tags), tag_key, "")
      if contains(keys(merge(var.default_tags, account.tags)), tag_key) &&
      !can(regex(pattern, lookup(merge(var.default_tags, account.tags), tag_key, "")))
    }) > 0
  } : {}

  # Validation: Fail if any tag values don't match required patterns
  validate_tag_patterns = length(local.accounts_with_invalid_tag_patterns) == 0 ? true : tobool(
    "Validation failed: The following accounts have tag values that don't match required patterns: ${jsonencode(local.accounts_with_invalid_tag_patterns)}"
  )

  # Baseline resource tags: Merge account tags with baseline default tags
  # Account-specific tags take precedence over baseline defaults
  baseline_resource_tags = {
    for name, account in var.accounts : name => merge(
      var.baseline_default_tags,
      var.default_tags,
      account.tags,
      {
        "AccountName" = name
        "ManagedBy"   = "AccountFactory"
      }
    )
  }

  # Validate baseline references exist in baseline configurations
  invalid_security_baselines = {
    for name, account in var.accounts : name => account.security_baseline
    if account.security_baseline != "none" &&
    account.security_baseline != "" &&
    !contains(keys(var.security_baselines), account.security_baseline)
  }

  invalid_network_baselines = {
    for name, account in var.accounts : name => account.network_baseline
    if account.network_baseline != "none" &&
    account.network_baseline != "" &&
    !contains(keys(var.network_baselines), account.network_baseline)
  }

  # Validation: Fail if any accounts reference non-existent baselines
  validate_security_baseline_refs = length(local.invalid_security_baselines) == 0 ? true : tobool(
    "Validation failed: The following accounts reference non-existent security baselines: ${jsonencode(local.invalid_security_baselines)}"
  )

  validate_network_baseline_refs = length(local.invalid_network_baselines) == 0 ? true : tobool(
    "Validation failed: The following accounts reference non-existent network baselines: ${jsonencode(local.invalid_network_baselines)}"
  )

  # Validate OU references when using OU names (not IDs)
  invalid_ou_references = {
    for name, account in var.accounts : name => account.organizational_unit
    if !can(regex("^ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", account.organizational_unit)) &&
    !can(regex("^r-[a-z0-9]{4,32}$", account.organizational_unit)) &&
    !contains(keys(var.existing_ou_ids), account.organizational_unit)
  }

  # Validation: Fail if any accounts reference non-existent OUs
  validate_ou_references = length(local.invalid_ou_references) == 0 ? true : tobool(
    "Validation failed: The following accounts reference organizational units that don't exist in existing_ou_ids: ${jsonencode(local.invalid_ou_references)}"
  )

  # Map account names to organizational unit IDs
  account_ou_mapping = {
    for name, account in var.accounts : name => (
      contains(keys(var.existing_ou_ids), account.organizational_unit)
      ? var.existing_ou_ids[account.organizational_unit]
      : account.organizational_unit
    )
  }

  # Accounts requiring security baseline deployment
  accounts_with_security_baseline = {
    for name, account in var.accounts : name => account
    if account.security_baseline != "none" && account.security_baseline != ""
  }

  # Accounts requiring network baseline deployment
  accounts_with_network_baseline = {
    for name, account in var.accounts : name => account
    if account.network_baseline != "none" && account.network_baseline != ""
  }

  # Validate email uniqueness within the accounts map
  account_emails = [for name, account in var.accounts : account.email]
  duplicate_emails = [
    for email in local.account_emails :
    email if length([for e in local.account_emails : e if e == email]) > 1
  ]

  # Map of accounts by environment for grouping
  accounts_by_env = {
    for env in distinct([for a in var.accounts : lookup(a.tags, "Environment", "unknown")]) :
    env => {
      for name, account in var.accounts :
      name => account if lookup(account.tags, "Environment", "unknown") == env
    }
  }

  # Map of accounts by organizational unit
  accounts_by_ou_local = {
    for ou in distinct([for a in var.accounts : a.organizational_unit]) :
    ou => {
      for name, account in var.accounts :
      name => account if account.organizational_unit == ou
    }
  }

  # Baseline version tracking
  baseline_versions = {
    for name, account in var.accounts : name => {
      security_baseline_version = account.baseline_version
      network_baseline_version  = account.baseline_version
      security_baseline_name    = account.security_baseline
      network_baseline_name     = account.network_baseline
    }
  }

  # Baseline update detection - identify accounts requiring updates
  # Accounts need updates when their baseline_version is "latest" and the baseline template version changes
  # or when their pinned version differs from the deployed version

  # Security baseline update detection
  accounts_requiring_security_baseline_update = {
    for name, account in local.accounts_with_security_baseline : name => {
      current_version = account.baseline_version
      target_version  = var.security_baselines[account.security_baseline].version
      needs_update    = account.baseline_version == "latest" || account.baseline_version != var.security_baselines[account.security_baseline].version
      baseline_name   = account.security_baseline
    }
    if account.baseline_version == "latest" ||
    (account.baseline_version != "latest" && account.baseline_version != var.security_baselines[account.security_baseline].version)
  }

  # Network baseline update detection
  accounts_requiring_network_baseline_update = {
    for name, account in local.accounts_with_network_baseline : name => {
      current_version = account.baseline_version
      target_version  = var.network_baselines[account.network_baseline].version
      needs_update    = account.baseline_version == "latest" || account.baseline_version != var.network_baselines[account.network_baseline].version
      baseline_name   = account.network_baseline
    }
    if account.baseline_version == "latest" ||
    (account.baseline_version != "latest" && account.baseline_version != var.network_baselines[account.network_baseline].version)
  }

  # Accounts with pinned baseline versions (not "latest")
  accounts_with_pinned_security_baseline = {
    for name, account in local.accounts_with_security_baseline : name => account
    if account.baseline_version != "latest"
  }

  accounts_with_pinned_network_baseline = {
    for name, account in local.accounts_with_network_baseline : name => account
    if account.baseline_version != "latest"
  }

  # Accounts using deprecated baseline versions
  # A version is considered deprecated if it's not the latest version and not explicitly pinned
  deprecated_security_baseline_accounts = {
    for name, account in local.accounts_with_security_baseline : name => {
      current_version = account.baseline_version
      latest_version  = var.security_baselines[account.security_baseline].version
      baseline_name   = account.security_baseline
    }
    if account.baseline_version != "latest" &&
    account.baseline_version != var.security_baselines[account.security_baseline].version
  }

  deprecated_network_baseline_accounts = {
    for name, account in local.accounts_with_network_baseline : name => {
      current_version = account.baseline_version
      latest_version  = var.network_baselines[account.network_baseline].version
      baseline_name   = account.network_baseline
    }
    if account.baseline_version != "latest" &&
    account.baseline_version != var.network_baselines[account.network_baseline].version
  }

  # Selective update lists - accounts to update based on scope
  # Can be filtered by OU, environment, or specific account list
  security_baseline_update_scope = {
    for name, update_info in local.accounts_requiring_security_baseline_update : name => update_info
    # Additional filtering can be applied here based on variables for selective updates
  }

  network_baseline_update_scope = {
    for name, update_info in local.accounts_requiring_network_baseline_update : name => update_info
    # Additional filtering can be applied here based on variables for selective updates
  }

  # Regions for baseline deployment per account
  account_regions = {
    for name, account in var.accounts : name => (
      length(account.regions) > 0 ? account.regions : var.governed_regions
    )
  }

  # Delegated administrator mapping
  delegated_admin_services = flatten([
    for name, account in var.accounts : [
      for service in account.delegated_services : {
        account_name = name
        service      = service
      }
    ]
  ])

  # Account lifecycle management
  # Identify production accounts that require additional deletion protection
  production_accounts = {
    for name, account in var.accounts : name => account
    if var.enable_production_account_protection && (
      # Check if account is in a production OU
      contains(var.production_ou_ids, local.account_ou_mapping[name]) ||
      # Check if account has Environment=production tag
      lookup(account.tags, "Environment", "") == "production" ||
      lookup(account.tags, "Environment", "") == "prod"
    )
  }

  # Validation: Prevent deletion of production accounts without explicit close_on_deletion flag
  production_accounts_without_close_flag = {
    for name, account in local.production_accounts : name => account
    if !account.close_on_deletion
  }

  # This validation ensures production accounts can only be removed if close_on_deletion is explicitly set
  validate_production_account_deletion = var.enable_production_account_protection ? (
    length(local.production_accounts_without_close_flag) == length(local.production_accounts) ? true : tobool(
      "Validation warning: Production accounts require close_on_deletion=true for removal. Accounts: ${jsonencode(keys(local.production_accounts_without_close_flag))}"
    )
  ) : true

  # Accounts that should be suspended (moved to Suspended OU) when removed
  # These are accounts that exist in state but not in configuration
  # Note: This logic is primarily for documentation; actual suspension happens via lifecycle rules
  accounts_for_suspension = {
    for name, account in var.accounts : name => account
    if !account.close_on_deletion && var.suspended_ou_id != ""
  }

  # Accounts that should be closed when removed
  accounts_for_closure = {
    for name, account in var.accounts : name => account
    if account.close_on_deletion
  }

  # Integration with existing Landing Zone resources
  # Use existing Transit Gateway ID if specified, otherwise empty
  transit_gateway_id = var.existing_transit_gateway_id != "" ? var.existing_transit_gateway_id : ""

  # Use existing CloudTrail bucket if specified
  cloudtrail_bucket_name = var.existing_cloudtrail_bucket_name != "" ? var.existing_cloudtrail_bucket_name : ""

  # Use existing Flow Logs bucket if specified
  flow_logs_bucket_name = var.existing_flow_logs_bucket_name != "" ? var.existing_flow_logs_bucket_name : ""

  # Use existing CloudWatch Log Group if specified
  log_group_name = var.existing_log_group_name != "" ? var.existing_log_group_name : ""
}
