locals {
  # The scope type decides which of the four azurerm exemption resources is used.
  policy_exemptions = {
    for k, v in var.policy_exemptions : k => merge(v, {
      name     = coalesce(v.name, k)
      metadata = v.metadata != null ? jsonencode(v.metadata) : null
      scope_type = (
        can(regex("(?i)^/providers/Microsoft\\.Management/managementGroups/[^/]+$", v.scope)) ? "management_group" :
        can(regex("(?i)^/subscriptions/[^/]+$", v.scope)) ? "subscription" :
        can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+$", v.scope)) ? "resource_group" :
        "resource"
      )
    })
  }

  expired_policy_exemptions = [
    for k, v in var.policy_exemptions : k
    if v.expires_on != null && timecmp(v.expires_on, plantimestamp()) <= 0
  ]

  expiring_policy_exemptions = [
    for k, v in var.policy_exemptions : k
    if v.expires_on != null && timecmp(v.expires_on, plantimestamp()) > 0 && timecmp(v.expires_on, timeadd(plantimestamp(), "720h")) <= 0
  ]
}

# management group exemptions
resource "azurerm_management_group_policy_exemption" "this" {
  for_each = {
    for k, v in local.policy_exemptions : k => v
    if v.scope_type == "management_group"
  }

  name                            = each.value.name
  management_group_id             = each.value.scope
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.exemption_category
  display_name                    = each.value.display_name
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
  metadata                        = each.value.metadata
}

# subscription exemptions
resource "azurerm_subscription_policy_exemption" "this" {
  for_each = {
    for k, v in local.policy_exemptions : k => v
    if v.scope_type == "subscription"
  }

  name                            = each.value.name
  subscription_id                 = each.value.scope
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.exemption_category
  display_name                    = each.value.display_name
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
  metadata                        = each.value.metadata
}

# resource group exemptions
resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = {
    for k, v in local.policy_exemptions : k => v
    if v.scope_type == "resource_group"
  }

  name                            = each.value.name
  resource_group_id               = each.value.scope
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.exemption_category
  display_name                    = each.value.display_name
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
  metadata                        = each.value.metadata
}

# resource exemptions
resource "azurerm_resource_policy_exemption" "this" {
  for_each = {
    for k, v in local.policy_exemptions : k => v
    if v.scope_type == "resource"
  }

  name                            = each.value.name
  resource_id                     = each.value.scope
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.exemption_category
  display_name                    = each.value.display_name
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
  metadata                        = each.value.metadata
}

# expiry
# Azure keeps expired exemptions until they are removed, so this warns instead of failing the plan.
check "policy_exemptions_expiry" {
  assert {
    condition     = length(local.expired_policy_exemptions) == 0
    error_message = "These policy exemptions have expired and can be removed: ${join(", ", local.expired_policy_exemptions)}."
  }

  assert {
    condition     = length(local.expiring_policy_exemptions) == 0
    error_message = "These policy exemptions expire within 30 days: ${join(", ", local.expiring_policy_exemptions)}."
  }
}
