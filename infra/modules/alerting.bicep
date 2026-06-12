targetScope = 'resourceGroup'

@description('Azure region used for all resources.')
param location string

@description('Short workload identifier (e.g. dostar).')
param workload string

@description('Deployment environment.')
@allowed([
  'dev'
  'prod'
])
param env string

@description('Short region code (e.g. aue for australiaeast).')
param region string

@description('Three-digit instance number.')
param instance string

@description('Resource ID of the Application Insights component.')
param appInsightsId string

@description('Resource ID of the Log Analytics Workspace backing Application Insights.')
param logAnalyticsWorkspaceId string

@description('Comma or semicolon-separated email addresses for P1 alert notifications.')
@minLength(1)
param alertEmailAddress string

var actionGroupName = 'ag-${workload}-${env}-${region}-${instance}'

var emailAddresses = filter(
  split(replace(alertEmailAddress, ';', ','), ','),
  e => !empty(e)
)

var errorRateThresholdPct = 10
var latencyThresholdMs = 2000

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

resource errorRateAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-error-rate-${workload}-${env}'
  location: location
  properties: {
    displayName: '[P1] High Error Rate'
    description: 'Fires when API error rate exceeds 10% over 5 minutes.'
    severity: 0
    enabled: true
    scopes: [logAnalyticsWorkspaceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
AppRequests
| where TimeGenerated > ago(5m)
| summarize Total = count(), Failed = countif(Success == false)
| extend ErrorRatePct = iff(Total > 10, Failed * 100.0 / Total, 0.0)
| project ErrorRatePct
'''
          timeAggregation: 'Maximum'
          metricMeasureColumn: 'ErrorRatePct'
          operator: 'GreaterThan'
          threshold: errorRateThresholdPct
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
    autoMitigate: true
  }
}

resource latencyAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-latency-${workload}-${env}'
  location: location
  properties: {
    displayName: '[P1] High P99 Latency'
    description: 'Fires when P99 latency exceeds 2000ms over 5 minutes.'
    severity: 0
    enabled: true
    scopes: [logAnalyticsWorkspaceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
AppRequests
| where TimeGenerated > ago(5m)
| summarize P99 = percentile(DurationMs, 99)
| project P99
'''
          timeAggregation: 'Maximum'
          metricMeasureColumn: 'P99'
          operator: 'GreaterThan'
          threshold: latencyThresholdMs
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
    autoMitigate: true
  }
}

