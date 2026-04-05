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

@description('Principal ID of the managed identity that needs Key Vault Secrets User access.')
param appServicePrincipalId string

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var keyVaultName = 'kv-${workload}-${env}-${region}-${instance}'

// Built-in role: Key Vault Secrets User
// https://learn.microsoft.com/azure/key-vault/general/rbac-guide#azure-built-in-roles-for-key-vault-data-plane-operations
var keyVaultSecretsUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e0'
)

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: env == 'prod' ? true : false
    publicNetworkAccess: 'Enabled'
  }
}

resource secretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(appServicePrincipalId)) {
  name: guid(keyVault.id, appServicePrincipalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleId
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('The URI of the Key Vault.')
output keyVaultUri string = keyVault.properties.vaultUri

@description('The name of the Key Vault.')
output keyVaultName string = keyVault.name
