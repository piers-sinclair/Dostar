targetScope = 'resourceGroup'

@description('Azure region used for all resources.')
param location string

@description('Short workload identifier (e.g. dostar).')
param workload string

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param env string

@description('Short region code (e.g. aue for australiaeast).')
param region string

@description('Three-digit instance number.')
param instance string

@description('Resource ID of the Application Insights component.')
param appInsightsId string

@description('FQDN of the Container App (used for the availability ping test). Leave empty to skip.')
param containerAppFqdn string = ''

@description('Email address for P1 alert notifications. Leave empty to skip email notifications.')
param alertEmailAddress string = ''

var actionGroupName = 'ag-${workload}-${env}-${region}-${instance}'
var availabilityTestName = 'webtest-healthz-${workload}-${env}-${region}-${instance}'

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
    emailReceivers: !empty(alertEmailAddress)
      ? [
          {
            name: 'On-call'
            emailAddress: alertEmailAddress
            useCommonAlertSchema: true
          }
        ]
      : []
  }
}

resource errorRateAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-error-rate-${workload}-${env}'
  location: location
  properties: {
    displayName: '[P1] High Error Rate'
    description: 'Fires when the API error rate exceeds 10% over a 5-minute window. Skipped when fewer than 10 requests arrive in the window to suppress cold-start noise.'
    severity: 0
    enabled: true
    scopes: [appInsightsId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
requests
| where timestamp > ago(5m)
| summarize Total = count(), Failed = countif(success == false)
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
      actionGroups: [actionGroup.id]
    }
    autoMitigate: true
  }
}

resource latencyAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-latency-${workload}-${env}'
  location: location
  properties: {
    displayName: '[P1] High P99 Latency'
    description: 'Fires when P99 request latency exceeds 2000 ms over a 5-minute window.'
    severity: 0
    enabled: true
    scopes: [appInsightsId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
requests
| where timestamp > ago(5m)
| summarize P99 = percentile(duration, 99)
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
      actionGroups: [actionGroup.id]
    }
    autoMitigate: true
  }
}

resource availabilityTest 'microsoft.insights/webtests@2022-06-15' = if (!empty(containerAppFqdn)) {
  name: availabilityTestName
  location: location
  kind: 'standard'
  tags: {
    'hidden-link:${appInsightsId}': 'Resource'
  }
  properties: {
    Name: 'Healthz live'
    Description: 'Pings /healthz/live from 3 Azure regions every 5 minutes.'
    Enabled: true
    Frequency: pingFrequencySeconds
    Timeout: pingTimeoutSeconds
    Kind: 'standard'
    RetryEnabled: false
    Locations: [
      { Id: 'us-va-ash-azr' }
      { Id: 'us-il-ch1-azr' }
      { Id: 'emea-nl-ams-azr' }
    ]
    Request: {
      RequestUrl: 'https://${containerAppFqdn}/healthz/live'
      HttpVerb: 'GET'
      ParseDependentRequests: false
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
    description: 'Fires when 2 or more probe locations fail to reach /healthz/live.'
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
      { actionGroupId: actionGroup.id }
    ]
  }
}
