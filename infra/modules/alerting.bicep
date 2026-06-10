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

// P1: error rate spike — fires when >10% of requests fail over a 5-minute window
resource errorRateAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-error-rate-${workload}-${env}'
  location: location
  properties: {
    displayName: '[P1] High Error Rate'
    description: 'Fires when the API error rate exceeds 10% over a 5-minute window.'
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
          threshold: 10
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

// P1: latency breach — fires when P99 request latency exceeds 2 seconds
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
          threshold: 2000
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

// Standard ping test targeting /healthz/live — only provisioned when containerAppFqdn is known
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
    Frequency: 300
    Timeout: 30
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

// P1: health check failure — fires when 2+ regions report unavailability
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
      failedLocationCount: 2
      webTestId: availabilityTest.id
    }
    actions: [
      { actionGroupId: actionGroup.id }
    ]
  }
}
