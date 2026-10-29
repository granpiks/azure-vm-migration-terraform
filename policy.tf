# Governance is deployed with the landing zone, not assigned by hand in the portal afterwards.

data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

resource "azurerm_policy_definition" "require_tags" {
  name         = "${local.name_prefix}-require-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require mandatory tags (project, environment, owner)"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['project']", exists = "false" },
        { field = "tags['environment']", exists = "false" },
        { field = "tags['owner']", exists = "false" },
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "${local.name_prefix}-require-tags"
  resource_group_id    = data.azurerm_resource_group.target.id
  policy_definition_id = azurerm_policy_definition.require_tags.id
}

# Prefer a built-in policy when Azure provides one: "Allowed locations".
resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "${local.name_prefix}-allowed-locations"
  resource_group_id    = data.azurerm_resource_group.target.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = [var.location]
    }
  })
}
