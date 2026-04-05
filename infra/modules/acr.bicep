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

// ACR names must be alphanumeric only, 5–50 chars — strip hyphens and truncate
var acrNameRaw = 'cr${workload}${env}${region}${instance}'
var acrName = length(acrNameRaw) <= 50 ? acrNameRaw : substring(acrNameRaw, 0, 50)

// Basic for dev (cheaper), Standard for prod (geo-replication, larger storage)
var acrSku = env == 'prod' ? 'Standard' : 'Basic'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('The name of the Azure Container Registry.')
output acrName string = acr.name

@description('The login server hostname of the ACR (e.g. crdostardevaue001.azurecr.io).')
output loginServer string = acr.properties.loginServer

@description('The resource ID of the ACR (used to scope the AcrPull role assignment in the Container App module).')
output acrId string = acr.id
