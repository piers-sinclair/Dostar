targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

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

@description('Resource ID of the ACR. Used to scope the AcrPull role assignment.')
param acrId string

@description('Application Insights connection string (optional — leave empty to skip wiring).')
param appInsightsConnectionString string = ''

@description('Container image to deploy. Defaults to a public placeholder on first deploy before CI pushes a real image to ACR. CI should pass the real ACR image tag on every deploy.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var caeName = 'cae-${workload}-${env}-${region}-${instance}'
var caName = 'ca-${workload}-${env}-${region}-${instance}'

// ACR name uses the same deterministic formula as acr.bicep — no cross-resource
// reference needed, so the image string resolves at compile time.
var acrNameRaw = 'cr${workload}${env}${region}${instance}'
var acrName = length(acrNameRaw) <= 50 ? acrNameRaw : substring(acrNameRaw, 0, 50)
var acrLoginServer = '${acrName}.azurecr.io'

// Scale-to-zero in dev saves cost; keep warm in prod to avoid cold starts
var minReplicas = env == 'prod' ? 1 : 0
var maxReplicas = env == 'prod' ? 10 : 3

// Built-in role: AcrPull
// https://learn.microsoft.com/azure/container-registry/container-registry-roles
var acrPullRoleId = tenantResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

// ---------------------------------------------------------------------------
// Container Apps Environment (Consumption plan + VNet integration)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Container App
// ---------------------------------------------------------------------------

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: caName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: cae.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
      }
      // Only configure ACR registry when the image is actually from ACR.
      // On first deploy the placeholder image (mcr.microsoft.com) is used and the
      // AcrPull role hasn't been assigned yet (it depends on the Container App's
      // principalId). Configuring the registry before the role exists causes Azure
      // to fail with "Operation expired" while trying to validate ACR access.
      registries: startsWith(containerImage, acrLoginServer)
        ? [
            {
              server: acrLoginServer
              identity: 'system'
            }
          ]
        : []
    }
    template: {
      containers: [
        {
          name: workload
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: concat(
            [
              {
                name: 'ASPNETCORE_URLS'
                value: 'http://+:8080'
              }
            ],
            !empty(appInsightsConnectionString)
              ? [
                  {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: appInsightsConnectionString
                  }
                ]
              : []
          )
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

// Reference the ACR by its resource ID so we can scope the role assignment to it
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(acrId, '/'))!
}

// AcrPull role — lets the Container App pull images via its system-assigned identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Use the Container App resource ID + raw role GUID so the name is stable
  // regardless of how the role definition resource ID is formatted.
  name: guid(acr.id, containerApp.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('The system-assigned managed identity principal ID of the Container App.')
output principalId string = containerApp.identity.principalId

@description('The FQDN (ingress hostname) of the Container App.')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('The name of the Container App.')
output containerAppName string = containerApp.name
