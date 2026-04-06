targetScope = 'resourceGroup'

@description('Azure region used for this resource. Must be one of the regions that support Static Web Apps: eastus2, westus2, centralus, westeurope, eastasia.')
@allowed(['eastus2', 'westus2', 'centralus', 'westeurope', 'eastasia'])
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

@description('GitHub repository URL to connect for automatic deployments.')
param repositoryUrl string

@description('Branch to auto-deploy from.')
param branch string

var abbrev = 'stapp'
var resourceNameValue = '${abbrev}-${workload}-${env}-${region}-${instance}'

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: resourceNameValue
  location: location
  sku: {
    name: env == 'prod' ? 'Standard' : 'Free'
    tier: env == 'prod' ? 'Standard' : 'Free'
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    buildProperties: {
      appLocation: 'frontend'
      outputLocation: 'dist'
      apiLocation: ''
    }
  }
}

@description('Default hostname of the Static Web App.')
output hostname string = staticWebApp.properties.defaultHostname

@description('Deployment token used by CI/CD to publish the frontend.')
@secure()
output deploymentToken string = staticWebApp.listSecrets().properties.apiKey
