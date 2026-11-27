variable "policy_exemptions" {
  description = "Contains all policy exemption configuration, keyed by a stable caller key"
  type = map(object({
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
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions :
      contains(["management_group", "subscription", "resource_group", "resource"], v.scope_type)
    ])
    error_message = "Each scope_type must be one of: management_group, subscription, resource_group, resource."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : (
        v.scope_type == "management_group" ? can(regex("(?i)^/providers/Microsoft\\.Management/managementGroups/[^/]+$", v.scope)) :
        v.scope_type == "subscription" ? can(regex("(?i)^/subscriptions/[^/]+$", v.scope)) :
        v.scope_type == "resource_group" ? can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+$", v.scope)) :
        (
          can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/.+[^/]$", v.scope)) ||
          can(regex("(?i)^/subscriptions/[^/]+/providers/[^/]+/.+[^/]$", v.scope))
        )
      )
    ])
    error_message = "Each scope must be an ID of the type set in scope_type. Resources directly under a management group are not supported."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions :
      length(coalesce(v.name, k)) <= 64
    ])
    error_message = "Each policy exemption name (or the map key when name is not set) must be at most 64 characters."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : (
        !can(regex("[#<>%&:\\\\?/\\x00-\\x1f\\x7f]", coalesce(v.name, k))) &&
        !endswith(coalesce(v.name, k), ".") &&
        !endswith(coalesce(v.name, k), " ")
      )
    ])
    error_message = "Each policy exemption name must not contain #<>%&:\\?/ or control characters, and must not end with a period or space."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions :
      contains(["Waiver", "Mitigated"], v.exemption_category)
    ])
    error_message = "Each exemption_category must be one of: Waiver, Mitigated."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions :
      can(timecmp(v.expires_on, "2000-01-01T00:00:00Z"))
    ])
    error_message = "Each expires_on must be an RFC 3339 timestamp, for example 2027-03-31T23:59:59Z."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : (
        length(coalesce(v.display_name, " ")) <= 128 &&
        length(coalesce(v.description, " ")) <= 512
      )
    ])
    error_message = "Each display_name must be at most 128 characters and each description at most 512 characters."
  }
}
