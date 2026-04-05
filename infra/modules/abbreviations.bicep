// Resource type abbreviations following the Azure Cloud Adoption Framework naming conventions.
// Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

@description('Map of resource type to its abbreviation.')
output abbreviations object = {
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
