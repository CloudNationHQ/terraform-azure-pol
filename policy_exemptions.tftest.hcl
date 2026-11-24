# Unit tests with a mock azurerm provider: no Azure access needed.
# Run with `make test-unit`. The deployment tests in tests/deploy_test.go use the examples instead.


mock_provider "azurerm" {}

variables {
  policy_exemptions = {
    mg = {
      scope                = "/providers/Microsoft.Management/managementGroups/mg-demo"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-demo/providers/Microsoft.Authorization/policyAssignments/a1"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
      metadata             = { owner = "team", ticket = "T-1" }
    }
    sub = {
      name                            = "exempt-sub"
      scope                           = "/subscriptions/00000000-0000-0000-0000-000000000000"
      policy_assignment_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category              = "Mitigated"
      policy_definition_reference_ids = ["ref1"]
    }
    rg = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
    }
    res = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.Storage/storageAccounts/stdemo"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
    }
    subres = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/pricings/VirtualMachines"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
    }
    rgcase = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/RG-Lower"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
    }
  }
}

run "routing" {
  command = apply
  assert {
    condition     = keys(azurerm_management_group_policy_exemption.this) == ["mg"]
    error_message = "mg routing"
  }
  assert {
    condition     = keys(azurerm_subscription_policy_exemption.this) == ["sub"]
    error_message = "sub routing"
  }
  assert {
    condition     = toset(keys(azurerm_resource_group_policy_exemption.this)) == toset(["rg", "rgcase"])
    error_message = "rg routing"
  }
  assert {
    condition     = toset(keys(azurerm_resource_policy_exemption.this)) == toset(["res", "subres"])
    error_message = "resource routing"
  }
  assert {
    condition     = azurerm_management_group_policy_exemption.this["mg"].name == "mg" && azurerm_subscription_policy_exemption.this["sub"].name == "exempt-sub"
    error_message = "name default"
  }
  assert {
    condition     = jsondecode(azurerm_management_group_policy_exemption.this["mg"].metadata).ticket == "T-1" && local.policy_exemptions["rg"].metadata == null
    error_message = "metadata"
  }
  assert {
    condition     = length(output.policy_exemptions) == 6 && length(output.policy_exemption_ids) == 6 && output.policy_exemptions_summary["subres"].scope_type == "resource"
    error_message = "outputs"
  }
}

run "reject_mg_child_resource" {
  command = plan
  variables {
    policy_exemptions = { x = {
      scope = "/providers/Microsoft.Management/managementGroups/mg/providers/Microsoft.Foo/bars/b"
    policy_assignment_id = "a", exemption_category = "Waiver" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_bad_category" {
  command = plan
  variables {
    policy_exemptions = { x = { scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "waiver" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_long_name" {
  command = plan
  variables {
    policy_exemptions = { x = { name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_bad_chars" {
  command = plan
  variables {
    policy_exemptions = { x = { name = "bad:name", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_trailing_period" {
  command = plan
  variables {
    policy_exemptions = { x = { name = "name.", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_date_only" {
  command = plan
  variables {
    policy_exemptions = { x = { scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2027-03-31" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "warn_expired" {
  command = plan
  variables {
    policy_exemptions = { old = { scope = "/subscriptions/00000000-0000-0000-0000-000000000000", policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2", exemption_category = "Waiver", expires_on = "2020-01-01T00:00:00Z" } }
  }
  expect_failures = [check.policy_exemptions_expiry]
}

run "empty" {
  command = apply
  variables { policy_exemptions = {} }
  assert {
    condition     = length(output.policy_exemptions) == 0
    error_message = "empty"
  }
}

run "warn_expiring_soon" {
  command = plan
  variables {
    policy_exemptions = { soon = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = timeadd(timestamp(), "240h")
    } }
  }
  expect_failures = [check.policy_exemptions_expiry]
}

run "no_warning_far_future" {
  command = plan
  variables {
    policy_exemptions = { later = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    } }
  }
}
