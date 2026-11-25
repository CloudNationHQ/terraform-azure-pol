# Unit tests with a mock azurerm provider: no Azure access needed.
# Run with `make test-unit`. The deployment tests in tests/deploy_test.go use the examples instead.

mock_provider "azurerm" {}

variables {
  policy_exemptions = {
    mg = {
      scope_type           = "management_group"
      scope                = "/providers/Microsoft.Management/managementGroups/mg-demo"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-demo/providers/Microsoft.Authorization/policyAssignments/a1"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
      metadata             = { owner = "team", ticket = "T-1" }
    }
    sub = {
      name                            = "exempt-sub"
      scope_type                      = "subscription"
      scope                           = "/subscriptions/00000000-0000-0000-0000-000000000000"
      policy_assignment_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category              = "Mitigated"
      expires_on                      = "2099-01-01T00:00:00Z"
      policy_definition_reference_ids = ["ref1"]
    }
    rg = {
      scope_type           = "resource_group"
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    }
    res = {
      scope_type           = "resource"
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.Storage/storageAccounts/stdemo"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    }
    subres = {
      scope_type           = "resource"
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/pricings/VirtualMachines"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    }
    rgcase = {
      scope_type           = "resource_group"
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/RG-Lower"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
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
    condition     = jsondecode(azurerm_management_group_policy_exemption.this["mg"].metadata).ticket == "T-1"
    error_message = "metadata"
  }
  assert {
    condition     = length(output.policy_exemptions) == 6
    error_message = "outputs"
  }
}

# scope IDs of resources created in the same deployment are unknown at plan time;
# routing must not depend on them
run "unknown_scope_plans" {
  command = plan

  providers = {
    azurerm = azurerm
  }

  module {
    source = "./tests/fixtures/unknown_scope"
  }

  assert {
    condition     = toset(output.exemption_keys) == toset(["rg", "res"])
    error_message = "exemption keys must be known at plan time even when the scope is not"
  }
}

run "reject_bad_scope_type" {
  command = plan
  variables {
    policy_exemptions = { x = { scope_type = "tenant", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_scope_type_mismatch" {
  command = plan
  variables {
    policy_exemptions = { x = { scope_type = "subscription", scope = "/subscriptions/s/resourceGroups/rg", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_mg_child_resource" {
  command = plan
  variables {
    policy_exemptions = { x = {
      scope_type           = "resource"
      scope                = "/providers/Microsoft.Management/managementGroups/mg/providers/Microsoft.Foo/bars/b"
      policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2099-01-01T00:00:00Z"
    } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_bad_category" {
  command = plan
  variables {
    policy_exemptions = { x = { scope_type = "subscription", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "waiver", expires_on = "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_long_name" {
  command = plan
  variables {
    policy_exemptions = { x = { name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", scope_type = "subscription", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_bad_chars" {
  command = plan
  variables {
    policy_exemptions = { x = { name = "bad:name", scope_type = "subscription", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_trailing_period" {
  command = plan
  variables {
    policy_exemptions = { x = { name = "name.", scope_type = "subscription", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2099-01-01T00:00:00Z" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "reject_date_only" {
  command = plan
  variables {
    policy_exemptions = { x = { scope_type = "subscription", scope = "/subscriptions/s", policy_assignment_id = "a", exemption_category = "Waiver", expires_on = "2027-03-31" } }
  }
  expect_failures = [var.policy_exemptions]
}

run "warn_expired" {
  command = plan
  variables {
    policy_exemptions = { old = { scope_type = "subscription", scope = "/subscriptions/00000000-0000-0000-0000-000000000000", policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2", exemption_category = "Waiver", expires_on = "2020-01-01T00:00:00Z" } }
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
      scope_type           = "subscription"
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
      scope_type           = "subscription"
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/a2"
      exemption_category   = "Waiver"
      expires_on           = "2099-01-01T00:00:00Z"
    } }
  }
}
