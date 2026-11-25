module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 3.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

# built-in audit policy, harmless to assign
resource "azurerm_resource_group_policy_assignment" "audit" {
  name                 = "pa-audit-custom-rbac"
  resource_group_id    = module.rg.groups.demo.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a451c1ef-c6ca-483d-87ed-f49761e3ffb5"
}

module "policy" {
  source  = "cloudnationhq/pol/azure"
  version = "~> 0.1"

  policy_exemptions = {
    demo = {
      scope_type           = "resource_group"
      scope                = module.rg.groups.demo.id
      policy_assignment_id = azurerm_resource_group_policy_assignment.audit.id
      exemption_category   = "Waiver"
      display_name         = "Demo - temporary waiver"
      description          = "Example waiver on a resource group, with an expiry date and metadata."
      expires_on           = "2099-12-31T23:59:59Z"
      metadata = {
        requestedBy = "platform-team"
        ticket      = "DEMO-1"
      }
    }
  }
}
