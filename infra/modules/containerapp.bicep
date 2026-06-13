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

@description('Resource ID of the Container Apps managed environment.')
param managedEnvironmentId string

@description('Application Insights connection string (optional — leave empty to skip wiring).')
param appInsightsConnectionString string = ''

@description('Frontend origin allowed by the production CORS policy (e.g. https://stapp-dostar-dev-aue-001.azurestaticapps.net). Leave empty to disable cross-origin access.')
param frontendOrigin string = ''

@description('PostgreSQL connection string. Passed as a secure param so ARM encrypts it in transit and in deployment history.')
@secure()
param postgresConnectionString string

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

var caName = 'ca-${workload}-${env}-${region}-${instance}'

// ACR name uses the same deterministic formula as acr.bicep — no cross-module reference needed
// to avoid a circular dependency (containerApp.principalId → acrPullRoleAssignment → acr.id → containerApp).
var acrNameRaw = 'cr${workload}${env}${region}${instance}'
var acrName = length(acrNameRaw) <= 50 ? acrNameRaw : substring(acrNameRaw, 0, 50)
var acrLoginServer = '${acrName}.azurecr.io'

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: caName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: managedEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
      // secrets.value is write-only in the Container Apps ARM API (masked on GET), so ARM always
      // detects a diff and re-PUTs the Container App on every deploy. This is an accepted
      // trade-off: the re-PUT is fast (~30 s, creates a new revision) and causes no downtime.
      // The alternative (Key Vault URI reference + managed-identity RBAC) would be fully
      // idempotent but introduces an RBAC propagation race on first deploy that breaks the
      // template's "just works" promise for new users.
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

@description('The system-assigned managed identity principal ID of the Container App.')
output principalId string = containerApp.identity.principalId

@description('The FQDN (ingress hostname) of the Container App.')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('The name of the Container App.')
output containerAppName string = containerApp.name

@description('The resource ID of the Container App.')
output containerAppId string = containerApp.id
