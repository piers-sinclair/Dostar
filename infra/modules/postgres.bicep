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

var serverName = 'psql-${workload}-${env}-${region}-${instance}'
var databaseName = workload

// Burstable B2ms for prod; B1ms (~$12/month) for dev
var skuName = env == 'prod' ? 'Standard_B2ms' : 'Standard_B1ms'

// Required by PostgreSQL Flexible Server VNet integration.
// Name must follow the pattern: <serverName>.private.postgres.database.azure.com
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
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
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    network: {
      delegatedSubnetResourceId: postgresSubnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
    highAvailability: {
      mode: env == 'prod' ? 'SameZone' : 'Disabled'
    }
    backup: {
      backupRetentionDays: env == 'prod' ? 14 : 7
      geoRedundantBackup: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
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
