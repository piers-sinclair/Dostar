targetScope = 'resourceGroup'

@description('Azure region used for this resource.')
param location string

@description('Short workload identifier (e.g. dostar).')
param workload string

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param env string

@description('Resource ID of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('Resource ID of the action group to notify on alert.')
param actionGroupId string

resource dbConnectivityAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-db-connectivity-${workload}-${env}'
  location: location
  properties: {
    displayName: '[P1] Database Connectivity Failure'
    description: 'Fires when failed PostgreSQL dependency calls are detected. Check the PostgreSQL server health in Azure Portal and verify the connection string secret in Key Vault.'
    severity: 0
    enabled: true
    scopes: [logAnalyticsWorkspaceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
AppDependencies
| where TimeGenerated > ago(5m)
| where Type =~ "postgresql" and Success == false
| summarize FailedCalls = count()
| project FailedCalls
'''
          timeAggregation: 'Total'
          metricMeasureColumn: 'FailedCalls'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [actionGroupId]
    }
    autoMitigate: true
  }
}
