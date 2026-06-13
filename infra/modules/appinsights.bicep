targetScope = 'resourceGroup'

@description('Azure region used for this resource.')
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

var lawName = 'log-${workload}-${env}-${region}-${instance}'
var appiName = 'appi-${workload}-${env}-${region}-${instance}'
var retentionDays = env == 'prod' ? 90 : 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  properties: {
    retentionInDays: retentionDays
    sku: {
      name: 'PerGB2018'
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: retentionDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module workbook 'observability-workbook.bicep' = {
  name: 'observability-workbook'
  params: {
    location: location
    appInsightsId: appInsights.id
  }
}

@description('Application Insights connection string. Pass to APPLICATIONINSIGHTS_CONNECTION_STRING in the app runtime environment.')
@secure()
output connectionString string = appInsights.properties.ConnectionString

@description('Application Insights instrumentation key (legacy — prefer connectionString for new workloads).')
@secure()
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Resource ID of the Log Analytics Workspace.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
