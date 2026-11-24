output "policy_exemptions" {
  description = "Contains all policy exemptions, keyed by the caller key"
  value = merge(
    azurerm_management_group_policy_exemption.this,
    azurerm_subscription_policy_exemption.this,
    azurerm_resource_group_policy_exemption.this,
    azurerm_resource_policy_exemption.this,
  )
}

output "policy_exemption_ids" {
  description = "Contains the ID of each policy exemption, keyed by the caller key"
  value = merge(
    { for k, v in azurerm_management_group_policy_exemption.this : k => v.id },
    { for k, v in azurerm_subscription_policy_exemption.this : k => v.id },
    { for k, v in azurerm_resource_group_policy_exemption.this : k => v.id },
    { for k, v in azurerm_resource_policy_exemption.this : k => v.id },
  )
}

output "policy_exemptions_summary" {
  description = "Contains a summary of each policy exemption for compliance reporting, keyed by the caller key"
  value = {
    for k, v in local.policy_exemptions : k => {
      name                 = v.name
      scope_type           = v.scope_type
      scope                = v.scope
      policy_assignment_id = v.policy_assignment_id
      exemption_category   = v.exemption_category
      expires_on           = v.expires_on
    }
  }
}
