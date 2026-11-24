module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

# needs permission to create management groups in the tenant
resource "azurerm_management_group" "demo" {
  name         = module.naming.resource_group.name_unique
  display_name = "Demo policy exemptions"
}

resource "azurerm_management_group_policy_assignment" "audit" {
  name                 = "pa-audit-custom-rbac" # max 24 characters at management group scope
  management_group_id  = azurerm_management_group.demo.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a451c1ef-c6ca-483d-87ed-f49761e3ffb5"
}

module "policy" {
  source  = "cloudnationhq/pol/azure"
  version = "~> 0.1"

  policy_exemptions = {
    management-group = {
      scope                = azurerm_management_group.demo.id
      policy_assignment_id = azurerm_management_group_policy_assignment.audit.id
      exemption_category   = "Waiver"
    }
  }
}
