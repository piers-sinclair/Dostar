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

@description('FQDN of the Container App (used for the availability ping test). Leave empty to skip.')
param containerAppFqdn string = ''

@description('Comma or semicolon-separated email addresses for P1 alert notifications.')
@minLength(1)
param alertEmailAddress string

var actionGroupName = 'ag-${workload}-${env}-${region}-${instance}'
var availabilityTestName = 'webtest-healthz-${workload}-${env}-${region}-${instance}'

var emailAddresses = filter(
  split(replace(alertEmailAddress, ';', ','), ','),
  e => !empty(e)
)

var errorRateThresholdPct = 10
var latencyThresholdMs = 2000
var availabilityFailedLocations = 2
var pingFrequencySeconds = 300
var pingTimeoutSeconds = 30

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

resource availabilityTest 'microsoft.insights/webtests@2018-05-01-preview' = if (!empty(containerAppFqdn)) {
  name: availabilityTestName
  location: location
  kind: 'standard'
  tags: {
    'hidden-link:${appInsightsId}': 'Resource'
  }
  properties: {
    Name: 'Healthz live'
    Description: 'Pings /healthz/live from multiple regions.'
    Enabled: true
    Frequency: pingFrequencySeconds
    Timeout: pingTimeoutSeconds
    RetryEnabled: false
    Locations: [
      { Id: 'us-va-ash-azr' }
      { Id: 'us-il-ch1-azr' }
      { Id: 'emea-nl-ams-azr' }
    ]
    Request: {
      RequestUrl: 'https://${containerAppFqdn}/healthz/live'
      HttpVerb: 'GET'
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      SSLCheck: true
    }
    SyntheticMonitorId: availabilityTestName
  }
}

resource availabilityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(containerAppFqdn)) {
  name: 'alert-availability-${workload}-${env}'
  location: 'global'
  properties: {
    description: 'Fires when 2+ regions fail health checks.'
    severity: 0
    enabled: true
    scopes: [
      appInsightsId
      availabilityTest.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      componentId: appInsightsId
      failedLocationCount: availabilityFailedLocations
      webTestId: availabilityTest.id
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
