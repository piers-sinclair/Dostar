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


@description('Application Insights connection string (optional — leave empty to skip wiring).')
param appInsightsConnectionString string = ''

@description('Frontend origin allowed by the production CORS policy (e.g. https://stapp-dostar-dev-aue-001.azurestaticapps.net). Leave empty to disable cross-origin access.')
param frontendOrigin string = ''

@description('PostgreSQL connection string. Passed as a secure param so ARM encrypts it in transit and in deployment history.')
@secure()
param postgresConnectionString string

@description('Container image to deploy. Defaults to a public placeholder on first deploy before CI pushes a real image to ACR. CI should pass the real ACR image tag on every deploy.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var caeName = 'cae-${workload}-${env}-${region}-${instance}'
var caName = 'ca-${workload}-${env}-${region}-${instance}'

// ACR name uses the same deterministic formula as acr.bicep — no cross-module reference needed
var acrNameRaw = 'cr${workload}${env}${region}${instance}'
var acrName = length(acrNameRaw) <= 50 ? acrNameRaw : substring(acrNameRaw, 0, 50)
var acrLoginServer = '${acrName}.azurecr.io'

// Scale-to-zero in dev saves cost; keep warm in prod to avoid cold starts
var minReplicas = env == 'prod' ? 1 : 0
var maxReplicas = env == 'prod' ? 10 : 3

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
      secrets: [
        {
          name: 'connectionstrings--default'
          value: postgresConnectionString
        }
      ]
      // ACR registry config is conditional: on first deploy the placeholder MCR image is used
      // before the AcrPull role exists (it depends on this app's principalId). Configuring the
      // registry without the role causes Azure to fail with "Operation expired".
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
              {
                name: 'ASPNETCORE_ENVIRONMENT'
                value: env == 'prod' ? 'Production' : 'Development'
              }
              {
                name: 'ConnectionStrings__Default'
                secretRef: 'connectionstrings--default'
              }
            ],
            !empty(appInsightsConnectionString)
              ? [
                  {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: appInsightsConnectionString
                  }
                ]
              : [],
            !empty(frontendOrigin)
              ? [
                  {
                    name: 'Cors__AllowedOrigins__0'
                    value: frontendOrigin
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

@description('The system-assigned managed identity principal ID of the Container App.')
output principalId string = containerApp.identity.principalId

@description('The FQDN (ingress hostname) of the Container App.')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('The name of the Container App.')
output containerAppName string = containerApp.name
