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

resource "azurerm_policy_set_definition" "demo" {
  name         = "psd-${module.naming.resource_group.name_unique}"
  policy_type  = "Custom"
  display_name = "Demo initiative"

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a451c1ef-c6ca-483d-87ed-f49761e3ffb5"
    reference_id         = "audit-custom-rbac"
  }

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
    reference_id         = "audit-unmanaged-disks"
  }
}

resource "azurerm_resource_group_policy_assignment" "demo" {
  name                 = "pa-demo-initiative"
  resource_group_id    = module.rg.groups.demo.id
  policy_definition_id = azurerm_policy_set_definition.demo.id
}

module "policy" {
  source  = "cloudnationhq/pol/azure"
  version = "~> 0.1"

  policy_exemptions = {
    unmanaged-disks = {
      scope                           = module.rg.groups.demo.id
      policy_assignment_id            = azurerm_resource_group_policy_assignment.demo.id
      policy_definition_reference_ids = ["audit-unmanaged-disks"]
      exemption_category              = "Mitigated"
      description                     = "Only this initiative member is exempted; every other member keeps applying."
    }
  }
}
