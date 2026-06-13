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

@description('Resource ID of the Log Analytics Workspace backing Application Insights.')
param logAnalyticsWorkspaceId string

@description('Comma or semicolon-separated email addresses for P1 alert notifications.')
@minLength(1)
param alertEmailAddress string

@description('Resource ID of the Container App to monitor for restarts.')
param containerAppId string

module actionGroup 'alerting/action-group.bicep' = {
  name: 'alerting-action-group'
  params: {
    workload: workload
    env: env
    region: region
    instance: instance
    alertEmailAddress: alertEmailAddress
  }
}

module errorRateAlert 'alerting/error-rate.bicep' = {
  name: 'alerting-error-rate'
  params: {
    location: location
    workload: workload
    env: env
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

module latencyAlert 'alerting/latency.bicep' = {
  name: 'alerting-latency'
  params: {
    location: location
    workload: workload
    env: env
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

module dbConnectivityAlert 'alerting/db-connectivity.bicep' = {
  name: 'alerting-db-connectivity'
  params: {
    location: location
    workload: workload
    env: env
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

module containerRestartAlert 'alerting/container-restarts.bicep' = {
  name: 'alerting-container-restarts'
  params: {
    workload: workload
    env: env
    containerAppId: containerAppId
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}
