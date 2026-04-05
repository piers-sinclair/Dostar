targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var lawName = 'log-${workload}-${env}-${region}-${instance}'
var appiName = 'appi-${workload}-${env}-${region}-${instance}'

// 30-day retention for dev to keep costs low; 90 days for prod for audit/debugging
var retentionDays = env == 'prod' ? 90 : 30

// ---------------------------------------------------------------------------
// Log Analytics Workspace (backing store for workspace-based App Insights)
// ---------------------------------------------------------------------------

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
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

// ---------------------------------------------------------------------------
// Application Insights (workspace-based — not classic)
// ---------------------------------------------------------------------------

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
    RetentionInDays: retentionDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ---------------------------------------------------------------------------
// Alert rules
// ---------------------------------------------------------------------------

// TODO: Enable this alert rule once teams are ready to act on 5xx alerts.
// Example: create a Microsoft.Insights/metricAlerts resource targeting
// appInsights.id with metric 'requests/failed' filtered to resultCode >= 500.
// Set threshold, evaluation frequency, and action group (email/PagerDuty/etc.)
// to match your on-call runbook.

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Application Insights connection string. Pass to APPLICATIONINSIGHTS_CONNECTION_STRING in the app runtime environment.')
output connectionString string = appInsights.properties.ConnectionString

@description('Application Insights instrumentation key (legacy — prefer connectionString for new workloads).')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Resource ID of the Log Analytics Workspace.')
output logAnalyticsWorkspaceId string = law.id
