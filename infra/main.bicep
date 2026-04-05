targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Short workload identifier (e.g. dostar).')
param workload string

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param env string

@description('Short region code (e.g. aue for australiaeast).')
param region string

@description('Three-digit instance number.')
param instance string = '001'

@description('Azure region used for all resources.')
param location string

@description('Principal ID of the Container App managed identity. Leave empty until the Container App module is added (#27).')
param appServicePrincipalId string = ''

@description('GitHub repository URL for automatic Static Web App deployments.')
param repositoryUrl string

@description('Branch to auto-deploy from.')
param branch string = 'main'

// ---------------------------------------------------------------------------
// Abbreviations (following Azure CAF conventions — see modules/abbreviations.bicep)
// ---------------------------------------------------------------------------

var abbrev = {
  resourceGroup: 'rg'
  appServicePlan: 'asp'
  appService: 'app'
  staticWebApp: 'stapp'
  postgresFlexibleServer: 'psql'
  keyVault: 'kv'
  storageAccount: 'st'
  logAnalyticsWorkspace: 'log'
  applicationInsights: 'appi'
  containerRegistry: 'cr'
  managedIdentity: 'id'
  virtualNetwork: 'vnet'
  subnet: 'snet'
}

// ---------------------------------------------------------------------------
// Naming convention: {abbrev}-{workload}-{env}-{region}-{instance}
// Example: app-dostar-prod-aue-001
// ---------------------------------------------------------------------------

func resourceName(abbr string, workloadName string, environment string, regionCode string, instanceNumber string) string =>
  '${abbr}-${workloadName}-${environment}-${regionCode}-${instanceNumber}'

// ---------------------------------------------------------------------------
// Resource group
// ---------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceName(abbrev.resourceGroup, workload, env, region, instance)
  location: location
}

// ---------------------------------------------------------------------------
// Key Vault — RBAC mode, soft-delete 90 days, purge protection in prod
// appServicePrincipalId is wired once the Container App module (#27) is added
// ---------------------------------------------------------------------------

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    appServicePrincipalId: appServicePrincipalId
  }
}

// ---------------------------------------------------------------------------
// VNet — always provisioned in both dev and prod for security consistency
// Subnet IDs are consumed by:
//   - Container Apps Environment module (#27): containerAppSubnetId
//   - PostgreSQL Flexible Server module (#29): postgresSubnetId
// ---------------------------------------------------------------------------

module vnet 'modules/vnet.bicep' = {
  name: 'vnet'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
  }
}

// ---------------------------------------------------------------------------
// Static Web App (React frontend)
// ---------------------------------------------------------------------------

module staticWebApp 'modules/staticwebapp.bicep' = {
  name: 'staticwebapp'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    repositoryUrl: repositoryUrl
    branch: branch
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('The URI of the Key Vault.')
output keyVaultUri string = keyvault.outputs.keyVaultUri

@description('Resource ID of the Container Apps subnet.')
output containerAppSubnetId string = vnet.outputs.containerAppSubnetId

@description('Resource ID of the PostgreSQL subnet.')
output postgresSubnetId string = vnet.outputs.postgresSubnetId

@description('Default hostname of the Static Web App hosting the React frontend.')
output staticWebAppHostname string = staticWebApp.outputs.hostname
