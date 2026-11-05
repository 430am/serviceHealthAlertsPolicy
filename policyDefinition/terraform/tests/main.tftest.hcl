mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001"
    }
  }
}

variables {
  action_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-alerts/providers/Microsoft.Insights/actionGroups/ag-serviceHealth"
  location                 = "centralus"
}

run "existing_action_group" {
  command = plan

  assert {
    condition     = azurerm_subscription_policy_assignment.service_health.policy_definition_id == "/providers/Microsoft.Authorization/policyDefinitions/98903777-a9f6-47f5-90a9-acaf62ab01a8"
    error_message = "The assignment must use the built-in Service Health policy."
  }

  assert {
    condition = (
      jsondecode(azurerm_subscription_policy_assignment.service_health.parameters).actionGroups.value == [var.action_group_resource_id] &&
      jsondecode(azurerm_subscription_policy_assignment.service_health.parameters).createNewActionGroup.value == "false" &&
      jsondecode(azurerm_subscription_policy_assignment.service_health.parameters).enableAlertRule.value == "true" &&
      jsondecode(azurerm_subscription_policy_assignment.service_health.parameters).effect.value == "DeployIfNotExists" &&
      jsondecode(azurerm_subscription_policy_assignment.service_health.parameters).resourceGroupLocation.value == var.location
    )
    error_message = "The policy must deploy an enabled alert using only the supplied existing Action Group."
  }

  assert {
    condition = (
      azurerm_subscription_policy_assignment.service_health.enforce &&
      azurerm_subscription_policy_assignment.service_health.identity[0].type == "SystemAssigned" &&
      azurerm_role_assignment.monitoring_policy_contributor.scope == data.azurerm_subscription.current.id &&
      azurerm_role_assignment.monitoring_policy_contributor.role_definition_id == "${data.azurerm_subscription.current.id}/providers/Microsoft.Authorization/roleDefinitions/47be4a87-7950-4631-9daf-b664a405f074" &&
      azurerm_role_assignment.monitoring_policy_contributor.principal_type == "ServicePrincipal"
    )
    error_message = "An enforced assignment must have a managed identity with the required subscription-scoped remediation role."
  }
}

run "reject_action_group_name" {
  command = plan

  variables {
    action_group_resource_id = "ag-serviceHealth"
  }

  expect_failures = [var.action_group_resource_id]
}

run "reject_empty_location" {
  command = plan

  variables {
    location = " "
  }

  expect_failures = [var.location]
}
