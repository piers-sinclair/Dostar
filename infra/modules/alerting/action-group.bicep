targetScope = 'resourceGroup'

@description('Short workload identifier (e.g. dostar).')
param workload string

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param env string

@description('Short region code (e.g. aue for australiaeast).')
param region string

@description('Three-digit instance number.')
param instance string

@description('Comma or semicolon-separated email addresses for P1 alert notifications.')
@minLength(1)
param alertEmailAddress string

var actionGroupName = 'ag-${workload}-${env}-${region}-${instance}'

var emailAddresses = filter(
  split(replace(alertEmailAddress, ';', ','), ','),
  e => !empty(e)
)

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'DostarOps'
    enabled: true
    emailReceivers: [
      for email in emailAddresses: {
        name: 'email-${uniqueString(email)}'
        emailAddress: email
        useCommonAlertSchema: true
      }
    ]
  }
}

@description('Resource ID of the action group.')
output actionGroupId string = actionGroup.id
