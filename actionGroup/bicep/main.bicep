@description('bicep template for creating service health alerts Action Group in Azure')
param actionGroupName string = 'ag-serviceHealth'

@description('Short name shown in SMS. Max 12 characters.')
@maxLength(12)
param actionGroupShortName string = 'svcHlth'

@description('Array of email addresses for the Action Group')
param emailRecivers array = [
  {
    name: 'OpsDL'
    emailAddress: 'azure-alerts@example.com'
    useCommonAlertSchema: true
  }
  {
    name: 'SupportDL'
    emailAddress: 'support@example.com'
    useCommonAlertSchema: true
  }
]

@description('Array of ARM role receivers (roleId is role definition GUID, e.g., Contributor)')
param armRoleReceivers array = [
  {
    name: 'SubContributors'
    roleId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor role definition GUID
    useCommonAlertSchema: true
  }
  {
    name: 'SubOwners'
    roleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner role definition GUID
    useCommonAlertSchema: true
  }
]

resource serviceHealthActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: emailRecivers
    armRoleReceivers: armRoleReceivers
  }
}

output actionGroupResourceId string = serviceHealthActionGroup.id
