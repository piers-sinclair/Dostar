targetScope = 'subscription'

@description('Short workload identifier (e.g. dostar).')
param workload string = 'dostar'

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param env string = 'dev'

@description('Short region code (e.g. aue for australiaeast).')
param region string = 'aue'

@description('Three-digit instance number.')
param instance string = '001'

@description('Azure region used for all resources.')
param location string

@description('GitHub repository URL for automatic Static Web App deployments.')
param repositoryUrl string = 'https://github.com/piers-sinclair/Dostar'

@description('Branch to auto-deploy from.')
param branch string = 'main'

@description('Azure region for the Static Web App. Must be one of the regions that support Static Web Apps: eastus2, westus2, centralus, westeurope, eastasia.')
@allowed(['eastus2', 'westus2', 'centralus', 'westeurope', 'eastasia'])
param staticWebAppLocation string = 'eastus2'

@description('Administrator username for the PostgreSQL Flexible Server.')
param postgresAdminUsername string = 'dostaradmin'

@description('Admin password for the PostgreSQL Flexible Server. Must be supplied by the CI workflow (read from Key Vault, or generated on first deploy). Never hardcode this value.')
@secure()
param postgresAdminPassword string

@description('Client ID of the Entra app registration used for Easy Auth on the Container App. Leave empty (or omit the secret) to deploy without authentication.')
param entraClientId string = ''

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

func resourceName(abbr string, workloadName string, environment string, regionCode string, instanceNumber string) string =>
  '${abbr}-${workloadName}-${environment}-${regionCode}-${instanceNumber}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceName(abbrev.resourceGroup, workload, env, region, instance)
  location: location
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    postgresAdminPassword: postgresAdminPassword
    postgresServerFqdn: postgres.outputs.serverFqdn
    postgresDatabaseName: postgres.outputs.databaseName
    postgresAdminUsername: postgresAdminUsername
    swaDeploymentToken: staticWebApp.outputs.deploymentToken
  }
}

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

module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
  }
}

module appinsights 'modules/appinsights.bicep' = {
  name: 'appinsights'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
  }
}

// AcrPull role assignment is inside containerapp.bicep to avoid a circular dependency
// (acr.id → containerapp.principalId → acr)
module containerapp 'modules/containerapp.bicep' = {
  name: 'containerapp'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    containerAppSubnetId: vnet.outputs.containerAppSubnetId
    appInsightsConnectionString: appinsights.outputs.connectionString
    postgresConnectionString: 'Host=${postgres.outputs.serverFqdn};Port=5432;Database=${postgres.outputs.databaseName};Username=${postgresAdminUsername};Password=${postgresAdminPassword};Ssl Mode=Require;Trust Server Certificate=true'
    entraClientId: entraClientId
  }
}

module postgres 'modules/postgres.bicep' = {
  name: 'postgres'
  scope: rg
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    adminUsername: postgresAdminUsername
    adminPassword: postgresAdminPassword
    postgresSubnetId: vnet.outputs.postgresSubnetId
    vnetId: vnet.outputs.vnetId
  }
}

module staticWebApp 'modules/staticwebapp.bicep' = {
  name: 'staticwebapp'
  scope: rg
  params: {
    location: staticWebAppLocation
    workload: workload
    env: env
    region: region
    instance: instance
    repositoryUrl: repositoryUrl
    branch: branch
  }
}

@description('The URI of the Key Vault.')
output keyVaultUri string = keyvault.outputs.keyVaultUri

@description('Resource ID of the Container Apps subnet.')
output containerAppSubnetId string = vnet.outputs.containerAppSubnetId

@description('Resource ID of the PostgreSQL subnet.')
output postgresSubnetId string = vnet.outputs.postgresSubnetId

@description('Default hostname of the Static Web App hosting the React frontend.')
output staticWebAppHostname string = staticWebApp.outputs.hostname

@description('ACR login server hostname.')
output acrLoginServer string = acr.outputs.loginServer

@description('FQDN of the Container App (backend API ingress).')
output containerAppFqdn string = containerapp.outputs.fqdn

@description('Principal ID of the Container App system-assigned managed identity.')
output containerAppPrincipalId string = containerapp.outputs.principalId

@description('Fully qualified domain name of the PostgreSQL Flexible Server.')
output postgresServerFqdn string = postgres.outputs.serverFqdn

@description('Name of the initial PostgreSQL database.')
output postgresDatabaseName string = postgres.outputs.databaseName

@description('Application Insights connection string. Set as APPLICATIONINSIGHTS_CONNECTION_STRING in the app runtime environment.')
output appInsightsConnectionString string = appinsights.outputs.connectionString

@description('Application Insights instrumentation key (legacy — prefer connectionString for new workloads).')
output appInsightsInstrumentationKey string = appinsights.outputs.instrumentationKey

@description('Resource group name. Used to scope subsequent operations.')
output AZURE_RESOURCE_GROUP string = rg.name

@description('ACR login server endpoint. Used to push and pull container images.')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer

@description('Container image name for the API service. Used to tag and deploy the built image.')
output SERVICE_API_IMAGE_NAME string = 'api'
