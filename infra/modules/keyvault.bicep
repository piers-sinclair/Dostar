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

@description('Fully qualified domain name of the PostgreSQL Flexible Server.')
param postgresServerFqdn string

@description('Name of the PostgreSQL database.')
param postgresDatabaseName string

@description('Administrator username for the PostgreSQL Flexible Server.')
param postgresAdminUsername string

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
    value: 'Host=${postgresServerFqdn};Port=5432;Database=${postgresDatabaseName};Username=${postgresAdminUsername};Password=${postgresAdminPassword};Ssl Mode=Require;Trust Server Certificate=true'
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
