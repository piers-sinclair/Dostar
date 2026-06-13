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

@description('Resource ID of the subnet delegated to Container Apps.')
param containerAppSubnetId string

@description('Resource ID of the Log Analytics workspace used for container log ingestion.')
param logAnalyticsWorkspaceId string

var caeName = 'cae-${workload}-${env}-${region}-${instance}'

resource cae 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: caeName
  location: location
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: containerAppSubnetId
      internal: false
    }
    zoneRedundant: false
  }
}

// Diagnostic settings route CAE logs to Log Analytics without listKeys().
// listKeys() returns a write-only value that ARM can never read back, so inline
// appLogsConfiguration triggers a CAE update on every deploy — slow with VNet integration.
resource caeDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'cae-to-log-analytics'
  scope: cae
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'ContainerAppConsoleLogs', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
      { category: 'ContainerAppSystemLogs', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
    ]
    metrics: []
  }
}

@description('Resource ID of the Container Apps managed environment.')
output managedEnvironmentId string = cae.id
