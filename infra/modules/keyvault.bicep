targetScope = 'resourceGroup'

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

@description('Auto-generated admin password for the PostgreSQL Flexible Server. Stored as a secret so operators can retrieve it.')
@secure()
param postgresAdminPassword string

var keyVaultName = 'kv-${workload}-${env}-${region}-${instance}'

// https://learn.microsoft.com/azure/key-vault/general/rbac-guide#azure-built-in-roles-for-key-vault-data-plane-operations
var keyVaultSecretsUserRoleId = tenantResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)

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
    // Purge protection can never be disabled once enabled — omit in dev rather than set false
    enablePurgeProtection: env == 'prod' ? true : null
    publicNetworkAccess: 'Enabled'
  }
}

resource secretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(appServicePrincipalId)) {
  // Raw role GUID keeps the assignment name stable regardless of role definition ID format
  name: guid(keyVault.id, appServicePrincipalId, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleId
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource postgresPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'postgres-admin-password'
  parent: keyVault
  properties: {
    value: postgresAdminPassword
  }
}

@description('The URI of the Key Vault.')
output keyVaultUri string = keyVault.properties.vaultUri

@description('The name of the Key Vault.')
output keyVaultName string = keyVault.name
