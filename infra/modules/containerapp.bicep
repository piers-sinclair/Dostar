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

@description('Application Insights connection string (optional — leave empty to skip wiring).')
param appInsightsConnectionString string = ''

@description('Frontend origin allowed by the production CORS policy (e.g. https://stapp-dostar-dev-aue-001.azurestaticapps.net). Leave empty to disable cross-origin access.')
param frontendOrigin string = ''

@description('Unversioned Key Vault secret URI for the PostgreSQL connection string (e.g. https://<vault>.vault.azure.net/secrets/postgres-connection-string). Container App reads the latest version at runtime via managed identity.')
param postgresConnectionStringSecretUri string

@description('Name of the Key Vault that holds the PostgreSQL connection string secret. Used to grant the Container App managed identity Key Vault Secrets User access.')
param keyVaultName string

@description('Container image to deploy. Defaults to a public placeholder on first deploy before CI pushes a real image to ACR. CI should pass the real ACR image tag on every deploy.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('vCPU cores allocated to each container replica (e.g. "0.5", "1.0", "2.0").')
param containerCpu string = '0.5'

@description('Memory allocated to each container replica (e.g. "1Gi", "2Gi").')
param containerMemory string = '1Gi'

@description('Minimum number of replicas. Use 0 to allow scale-to-zero.')
@minValue(0)
param minReplicas int = 0

@description('Maximum number of replicas.')
@minValue(1)
param maxReplicas int = 3

// Key Vault Secrets User — built-in role that allows reading secret values
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

var caeName = 'cae-${workload}-${env}-${region}-${instance}'
var caName = 'ca-${workload}-${env}-${region}-${instance}'

// ACR name uses the same deterministic formula as acr.bicep — no cross-module reference needed
var acrNameRaw = 'cr${workload}${env}${region}${instance}'
var acrName = length(acrNameRaw) <= 50 ? acrNameRaw : substring(acrNameRaw, 0, 50)
var acrLoginServer = '${acrName}.azurecr.io'

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
        allowInsecure: false
      }
      // Use Key Vault URI reference instead of inline value — secret values are write-only in
      // Container Apps ARM (masked on GET), so an inline value would cause ARM to detect a diff
      // and re-PUT the app on every deploy. A keyVaultUrl reference stores a stable URI string
      // that ARM can read back, making the secret config fully idempotent.
      secrets: [
        {
          name: 'connectionstrings--default'
          keyVaultUrl: postgresConnectionStringSecretUri
          identity: 'system'
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
            cpu: json(containerCpu)
            memory: containerMemory
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
              {
                name: 'Logging__Console__FormatterName'
                value: 'json'
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
          probes: [
            {
              type: 'Startup'
              httpGet: {
                path: '/healthz/live'
                port: 8080
                scheme: 'HTTP'
              }
              initialDelaySeconds: 0
              periodSeconds: 10
              timeoutSeconds: 5
              failureThreshold: 18
            }
            {
              type: 'Liveness'
              httpGet: {
                path: '/healthz/live'
                port: 8080
                scheme: 'HTTP'
              }
              initialDelaySeconds: 0
              periodSeconds: 30
              timeoutSeconds: 5
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/healthz/ready'
                port: 8080
                scheme: 'HTTP'
              }
              initialDelaySeconds: 0
              periodSeconds: 10
              timeoutSeconds: 5
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

// Grant the Container App managed identity permission to read Key Vault secrets at runtime.
// Role assignment name is a stable GUID derived from the three inputs — idempotent across deploys.
resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultRef.id, containerApp.id, keyVaultSecretsUserRoleId)
  scope: keyVaultRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The system-assigned managed identity principal ID of the Container App.')
output principalId string = containerApp.identity.principalId

@description('The FQDN (ingress hostname) of the Container App.')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('The name of the Container App.')
output containerAppName string = containerApp.name
