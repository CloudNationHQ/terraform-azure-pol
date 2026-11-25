output "policy_exemptions" {
  description = "Contains all policy exemptions, keyed by the caller key"
  value = merge(
    azurerm_management_group_policy_exemption.this,
    azurerm_subscription_policy_exemption.this,
    azurerm_resource_group_policy_exemption.this,
    azurerm_resource_policy_exemption.this,
  )
}
