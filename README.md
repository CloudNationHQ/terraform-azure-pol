# Azure Policy

This terraform module simplifies the creation and management of azure policy resources used by workloads and accelerators. The first release covers policy exemptions at every scope, all managed through code; policy definitions, set definitions and assignments can be added later.

## Features

Capability to exempt a management group, subscription, resource group or single resource from a policy assignment, from one map of exemptions.

Uses the matching azurerm exemption resource for the scope type set on each exemption, so scope IDs of resources created in the same deployment work.

Supports exempting a whole assignment, or only specific initiative members through `policy_definition_reference_ids`.

Includes support for categories, required expiry dates, display names, descriptions and metadata as a map.

Warns, without failing the plan, about exemptions that have expired or expire within 30 days.

Utilization of terratest for robust validation.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 5.0)

## Resources

The following resources are used by this module:

- [azurerm_management_group_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_exemption) (resource)
- [azurerm_resource_group_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_exemption) (resource)
- [azurerm_resource_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_policy_exemption) (resource)
- [azurerm_subscription_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_exemption) (resource)

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_policy_exemptions"></a> [policy\_exemptions](#input\_policy\_exemptions)

Description: Contains all policy exemption configuration, keyed by a stable caller key

Type:

```hcl
map(object({
    name                            = optional(string)
    scope_type                      = string
    scope                           = string
    policy_assignment_id            = string
    exemption_category              = string
    expires_on                      = string
    display_name                    = optional(string)
    description                     = optional(string)
    policy_definition_reference_ids = optional(list(string))
    metadata                        = optional(map(string))
  }))
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_policy_exemptions"></a> [policy\_exemptions](#output\_policy\_exemptions)

Description: Contains all policy exemptions, keyed by the caller key
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Supported `scope_type` values: `management_group`, `subscription`, `resource_group` and `resource`. A `resource` scope can be a resource in a resource group or a resource directly under a subscription (for example `/subscriptions/x/providers/Microsoft.Security/pricings/VirtualMachines`). Resources directly under a management group are not supported.

Changing the `scope_type` of an exemption (for example from subscription to resource group) replaces the exemption, because each scope type is a different azurerm resource. Keep map keys stable to avoid other replacements.

Exemption names can be up to 64 characters at every scope. The 24-character limit at management group scope only applies to policy assignments.

A new exemption can take a few minutes before Azure Policy applies it to new requests.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make docs`

## Authors

Module is maintained by [these awesome contributors](https://github.com/cloudnationhq/terraform-azure-pol/graphs/contributors).

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md). <br><br>

<a href="https://github.com/cloudnationhq/terraform-azure-pol/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudnationhq/terraform-azure-pol" />
</a>

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/azure/governance/policy/concepts/exemption-structure)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/policy/)
- [Rest Api Specs](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/resources/resource-manager/Microsoft.Authorization/policy)
