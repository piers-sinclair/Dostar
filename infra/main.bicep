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

@description('Azure region for the Static Web App. Must be one of the regions that support Static Web Apps: eastus2, westus2, centralus, westeurope, eastasia.')
@allowed(['eastus2', 'westus2', 'centralus', 'westeurope', 'eastasia'])
param staticWebAppLocation string = 'eastus2'

@description('Administrator username for the PostgreSQL Flexible Server. Must be changed from any default — use a value unique to your deployment.')
@minLength(1)
param postgresAdminUsername string

@description('Admin password for the PostgreSQL Flexible Server. Must be supplied by the CI workflow (read from Key Vault, or generated on first deploy). Never hardcode this value.')
@secure()
param postgresAdminPassword string

@description('vCPU cores for each Container App replica (e.g. "0.5", "1.0", "2.0").')
param containerCpu string = '0.5'

@description('Memory for each Container App replica (e.g. "1Gi", "2Gi").')
param containerMemory string = '1Gi'

@description('Minimum Container App replicas. Use 0 for scale-to-zero in dev.')
@minValue(0)
param containerMinReplicas int = 0

@description('Maximum Container App replicas.')
@minValue(1)
param containerMaxReplicas int = 1

@description('PostgreSQL Flexible Server SKU (e.g. Standard_B1ms, Standard_B2ms, Standard_D2ds_v5).')
param postgresSkuName string = 'Standard_B1ms'

@description('PostgreSQL storage size in GB.')
@minValue(32)
param postgresStorageSizeGB int = 32

@description('Enable SameZone High Availability for PostgreSQL. Only supported on General Purpose (Standard_D*) or Memory Optimized (Standard_E*) SKUs — not Burstable (Standard_B*). Disabled by default to keep startup costs low; enable when uptime SLAs require it.')
param postgresEnableHa bool = false

@description('Comma or semicolon-separated email addresses for P1 alert notifications (error rate, latency, health check failure). Leave empty to skip email notifications.')
param alertEmailAddress string = ''

@description('Container image to deploy. Defaults to a public placeholder on first deploy. Subsequent infra-only deploys should pass the currently-running image so the backend is not reset to the placeholder.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var rgName = 'rg-${workload}-${env}-${region}-${instance}'

module rg 'modules/resource-group.bicep' = {
  name: 'resource-group'
  params: {
    location: location
    name: rgName
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup(rg.outputs.name)
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
  scope: resourceGroup(rg.outputs.name)
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
  scope: resourceGroup(rg.outputs.name)
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
  scope: resourceGroup(rg.outputs.name)
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
  }
}

module containerEnvironment 'modules/container-environment.bicep' = {
  name: 'container-environment'
  scope: resourceGroup(rg.outputs.name)
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    containerAppSubnetId: vnet.outputs.containerAppSubnetId
    logAnalyticsWorkspaceId: appinsights.outputs.logAnalyticsWorkspaceId
  }
}

module containerapp 'modules/containerapp.bicep' = {
  name: 'containerapp'
  scope: resourceGroup(rg.outputs.name)
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    managedEnvironmentId: containerEnvironment.outputs.managedEnvironmentId
    appInsightsConnectionString: appinsights.outputs.connectionString
    postgresConnectionString: 'Host=${postgres.outputs.serverFqdn};Port=5432;Database=${postgres.outputs.databaseName};Username=${postgresAdminUsername};Password=${postgresAdminPassword};Ssl Mode=Require;Trust Server Certificate=true'
    frontendOrigin: 'https://${staticWebApp.outputs.hostname}'
    containerCpu: containerCpu
    containerMemory: containerMemory
    containerImage: containerImage
    minReplicas: containerMinReplicas
    maxReplicas: containerMaxReplicas
  }
}

module postgres 'modules/postgres.bicep' = {
  name: 'postgres'
  scope: resourceGroup(rg.outputs.name)
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
    skuName: postgresSkuName
    storageSizeGB: postgresStorageSizeGB
    enableHa: postgresEnableHa
  }
}

module alerting 'modules/alerting.bicep' = if (env == 'prod') {
  name: 'alerting'
  scope: resourceGroup(rg.outputs.name)
  params: {
    location: location
    workload: workload
    env: env
    region: region
    instance: instance
    logAnalyticsWorkspaceId: appinsights.outputs.logAnalyticsWorkspaceId
    alertEmailAddress: alertEmailAddress
    containerAppId: containerapp.outputs.containerAppId
  }
}

module staticWebApp 'modules/staticwebapp.bicep' = {
  name: 'staticwebapp'
  scope: resourceGroup(rg.outputs.name)
  params: {
    location: staticWebAppLocation
    workload: workload
    env: env
    region: region
    instance: instance
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
output AZURE_RESOURCE_GROUP string = rg.outputs.name

@description('ACR login server endpoint. Used to push and pull container images.')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer

@description('Container image name for the API service. Used to tag and deploy the built image.')
output SERVICE_API_IMAGE_NAME string = 'api'
