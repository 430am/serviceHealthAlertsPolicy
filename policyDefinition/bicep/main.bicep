targetScope = 'subscription'

@description('Full resource ID of an existing Action Group created by either Action Group example.')
@minLength(1)
param actionGroupResourceId string

@description('Azure region for the policy assignment identity and the resource group created by remediation.')
@minLength(1)
param location string = 'centralus'

var policyDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', '98903777-a9f6-47f5-90a9-acaf62ab01a8')
var monitoringPolicyContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '47be4a87-7950-4631-9daf-b664a405f074')

resource serviceHealthPolicyAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'service-health-alerts'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Configure subscriptions to enable service health alert monitoring rule'
    description: 'Deploy a Service Health alert rule using an existing Action Group.'
    policyDefinitionId: policyDefinitionId
    enforcementMode: 'Default'
    parameters: {
      effect: {
        value: 'DeployIfNotExists'
      }
      enableAlertRule: {
        value: 'true'
      }
      actionGroups: {
        value: [
          actionGroupResourceId
        ]
      }
      createNewActionGroup: {
        value: 'false'
      }
      resourceGroupLocation: {
        value: location
      }
    }
  }
}

resource monitoringPolicyContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, serviceHealthPolicyAssignment.name, monitoringPolicyContributorRoleDefinitionId)
  properties: {
    roleDefinitionId: monitoringPolicyContributorRoleDefinitionId
    principalId: serviceHealthPolicyAssignment.identity!.principalId
    principalType: 'ServicePrincipal'
  }
}

output policyAssignmentId string = serviceHealthPolicyAssignment.id
output policyAssignmentPrincipalId string = serviceHealthPolicyAssignment.identity!.principalId
