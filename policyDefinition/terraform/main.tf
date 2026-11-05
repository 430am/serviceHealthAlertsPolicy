terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "action_group_resource_id" {
  description = "Full resource ID of an existing Action Group created by either Action Group example"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Insights/actionGroups/[^/]+$", var.action_group_resource_id))
    error_message = "Provide a full Azure resource ID for a Microsoft.Insights/actionGroups resource."
  }
}

variable "location" {
  description = "Azure region for the policy assignment identity and the resource group created by remediation"
  type        = string
  default     = "centralus"
  nullable    = false

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "Provide a non-empty Azure region."
  }
}

data "azurerm_subscription" "current" {}

resource "azurerm_subscription_policy_assignment" "service_health" {
  name                 = "service-health-alerts"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/98903777-a9f6-47f5-90a9-acaf62ab01a8"
  display_name         = "Configure subscriptions to enable service health alert monitoring rule"
  description          = "Deploy a Service Health alert rule using an existing Action Group."
  location             = var.location
  enforce              = true

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect = {
      value = "DeployIfNotExists"
    }
    enableAlertRule = {
      value = "true"
    }
    actionGroups = {
      value = [var.action_group_resource_id]
    }
    createNewActionGroup = {
      value = "false"
    }
    resourceGroupLocation = {
      value = var.location
    }
  })
}

resource "azurerm_role_assignment" "monitoring_policy_contributor" {
  scope                            = data.azurerm_subscription.current.id
  role_definition_id               = "${data.azurerm_subscription.current.id}/providers/Microsoft.Authorization/roleDefinitions/47be4a87-7950-4631-9daf-b664a405f074"
  principal_id                     = azurerm_subscription_policy_assignment.service_health.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

output "policy_assignment_id" {
  description = "The full Azure resource ID of the Service Health policy assignment"
  value       = azurerm_subscription_policy_assignment.service_health.id
}

output "policy_assignment_principal_id" {
  description = "The principal ID of the policy assignment's system-assigned managed identity"
  value       = azurerm_subscription_policy_assignment.service_health.identity[0].principal_id
}
