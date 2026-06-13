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

@description('Administrator username for the PostgreSQL Flexible Server.')
param adminUsername string

@description('Administrator password for the PostgreSQL Flexible Server. Sourced from Key Vault.')
@secure()
param adminPassword string

@description('Resource ID of the delegated PostgreSQL subnet for VNet integration.')
param postgresSubnetId string

@description('Resource ID of the VNet (used for private DNS zone VNet link).')
param vnetId string

@description('''
PostgreSQL Flexible Server SKU name. The tier is derived automatically from the SKU prefix:
  Standard_B* → Burstable    (e.g. Standard_B1ms, Standard_B2ms)
  Standard_D* → GeneralPurpose  (e.g. Standard_D2ds_v5, Standard_D4ds_v5)
  Standard_E* → MemoryOptimized (e.g. Standard_E2ds_v5, Standard_E4ds_v5)
''')
param skuName string = 'Standard_B1ms'

@description('Storage size in GB.')
@minValue(32)
param storageSizeGB int = 32

@description('Enable SameZone High Availability. Requires a General Purpose or Memory Optimized SKU (Standard_D* or Standard_E*). Burstable SKUs (Standard_B*) do not support HA.')
param enableHa bool = false

var serverName = 'psql-${workload}-${env}-${region}-${instance}'
var databaseName = workload

var skuTier = startsWith(skuName, 'Standard_B')
  ? 'Burstable'
  : startsWith(skuName, 'Standard_E') ? 'MemoryOptimized' : 'GeneralPurpose'

// Required by PostgreSQL Flexible Server VNet integration.
// Name must follow the pattern: <serverName>.private.postgres.database.azure.com
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${serverName}.private.postgres.database.azure.com'
  location: 'global'
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-vnet'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: '16'
    administratorLogin: adminUsername
    // administratorLoginPassword is write-only (masked on GET), so ARM always detects a diff
    // and re-PUTs the server on every deploy. Setting the same password is a no-op in Azure
    // and completes in seconds — accepted trade-off over a more complex conditional approach.
    administratorLoginPassword: adminPassword
    network: {
      delegatedSubnetResourceId: postgresSubnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
    highAvailability: {
      mode: enableHa ? 'SameZone' : 'Disabled'
    }
    backup: {
      backupRetentionDays: env == 'prod' ? 14 : 7
      geoRedundantBackup: 'Disabled'
    }
    storage: {
      storageSizeGB: storageSizeGB
    }
  }
  dependsOn: [privateDnsZoneVnetLink]
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  name: databaseName
  parent: postgresServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

@description('Fully qualified domain name of the PostgreSQL Flexible Server.')
output serverFqdn string = postgresServer.properties.fullyQualifiedDomainName

@description('Name of the initial database.')
output databaseName string = database.name
