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

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "action_group_name" {
  description = "The name of the action group"
  type        = string
  default     = "ag-serviceHealth"
}

variable "action_group_short_name" {
  description = "The short name for the action group (max 12 characters)"
  type        = string
  default     = "svcHlth"
}

variable "email_receivers" {
  description = "Array of email addresses for the Action Group"
  type = list(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = bool
  }))
  default = [
    {
      name                    = "OpsDL"
      email_address           = "azure-alerts@example.com"
      use_common_alert_schema = true
    },
    {
      name                    = "SupportDL"
      email_address           = "support@example.com"
      use_common_alert_schema = true
    }
  ]
}

variable "arm_role_receivers" {
  description = "Array of ARM role receivers (roleId is role definition GUID, e.g., Contributor)"
  type = list(object({
    name                    = string
    role_id                 = string
    use_common_alert_schema = bool
  }))
  default = [
    {
      name                    = "SubContributors"
      role_id                 = "b24988ac-6180-42a0-ab88-20f7382dd24c" // Contributor role definition GUID
      use_common_alert_schema = true
    },
    {
      name                    = "SubOwners"
      role_id                 = "8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // Owner role definition GUID
      use_common_alert_schema = true
    }
  ]
}

resource "azurerm_monitor_action_group" "serviceHealth" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "arm_role_receiver" {
    for_each = var.arm_role_receivers
    content {
      name                    = arm_role_receiver.value.name
      role_id                 = arm_role_receiver.value.role_id
      use_common_alert_schema = arm_role_receiver.value.use_common_alert_schema
    }
  }
}

output "action_group_id" {
  description = "The full Azure resource ID of the Action Group"
  value       = azurerm_monitor_action_group.serviceHealth.id
}