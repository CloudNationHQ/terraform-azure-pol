# wrapper used by policy_exemptions.tftest.hcl: feeds the module scope IDs that are only known
# after apply, e.g. a resource group created in the same deployment
resource "terraform_data" "rg" {
  input = "rg"
}

module "policy" {
  source = "../../.."

  policy_exemptions = {
    rg = {
      scope_type           = "resource_group"
      scope                = terraform_data.rg.id
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    }
    res = {
      scope_type           = "resource"
      scope                = terraform_data.rg.id
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    }
  }
}

output "exemption_keys" {
  value = keys(module.policy.policy_exemptions)
}
