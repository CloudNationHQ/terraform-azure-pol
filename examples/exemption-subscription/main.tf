module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

data "azurerm_subscription" "current" {}

resource "azurerm_subscription_policy_assignment" "audit" {
  name                 = "pa-${module.naming.resource_group.name_unique}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a451c1ef-c6ca-483d-87ed-f49761e3ffb5"
}

module "policy" {
  source  = "cloudnationhq/pol/azure"
  version = "~> 0.1"

  policy_exemptions = {
    subscription = {
      scope_type           = "subscription"
      scope                = data.azurerm_subscription.current.id
      policy_assignment_id = azurerm_subscription_policy_assignment.audit.id
      exemption_category   = "Waiver"
      expires_on           = "2099-12-31T23:59:59Z"
    }
    # a resource directly under the subscription, without a resource group
    defender-pricing = {
      scope_type           = "resource"
      scope                = "${data.azurerm_subscription.current.id}/providers/Microsoft.Security/pricings/VirtualMachines"
      policy_assignment_id = azurerm_subscription_policy_assignment.audit.id
      exemption_category   = "Mitigated"
      expires_on           = "2099-12-31T23:59:59Z"
    }
  }
}
