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

@description('Auto-generated admin password for the PostgreSQL Flexible Server. Stored as a secret so operators can retrieve it.')
@secure()
param postgresAdminPassword string

@description('PostgreSQL connection string assembled in main.bicep. Stored as a secret so operators can use it directly.')
@secure()
param postgresConnectionString string

@description('SWA deployment token. Pass from staticWebApp.outputs.deploymentToken. Leave empty to skip.')
@secure()
param swaDeploymentToken string = ''

var keyVaultName = 'kv-${workload}-${env}-${region}-${instance}'

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
    // Purge protection is irreversible once enabled — omit entirely in dev rather than set to false,
    // because setting false on an existing vault that had it enabled would fail.
    enablePurgeProtection: env == 'prod' ? true : null
    publicNetworkAccess: 'Enabled'
  }
}

// secret.value is write-only in the Key Vault ARM API — ARM always detects a diff and re-PUTs
// secrets on every deploy. The re-PUT is idempotent (same value = no change in vault) and fast.
resource postgresPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'postgres-admin-password'
  parent: keyVault
  properties: {
    value: postgresAdminPassword
  }
}

resource postgresConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'postgres-connection-string'
  parent: keyVault
  properties: {
    value: postgresConnectionString
  }
}

resource swaDeploymentTokenSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(swaDeploymentToken)) {
  name: 'swa-deployment-token'
  parent: keyVault
  properties: {
    value: swaDeploymentToken
  }
}

@description('The URI of the Key Vault.')
output keyVaultUri string = keyVault.properties.vaultUri

@description('The name of the Key Vault.')
output keyVaultName string = keyVault.name

@description('The versioned URI of the postgres-connection-string secret.')
output connectionStringSecretUri string = postgresConnectionStringSecret.properties.secretUri
