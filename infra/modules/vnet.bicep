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

var vnetName = 'vnet-${workload}-${env}-${region}-${instance}'

module nsgContainerApp 'networking/nsg.bicep' = {
  name: 'nsg-containerapp'
  params: {
    name: 'nsg-${workload}-${env}-${region}-${instance}-containerapp'
    location: location
  }
}

module nsgPostgres 'networking/nsg.bicep' = {
  name: 'nsg-postgres'
  params: {
    name: 'nsg-${workload}-${env}-${region}-${instance}-postgres'
    location: location
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        // /23 minimum required for Container Apps Consumption environment VNet integration
        name: 'snet-containerapp'
        properties: {
          addressPrefix: '10.0.0.0/23'
          networkSecurityGroup: {
            id: nsgContainerApp.outputs.id
          }
          delegations: [
            {
              name: 'Microsoft.App-environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: 'snet-postgres'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsgPostgres.outputs.id
          }
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL-flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

@description('Resource ID of the virtual network.')
output vnetId string = vnet.id

@description('Resource ID of the Container Apps subnet.')
output containerAppSubnetId string = vnet.properties.subnets[0].id

@description('Resource ID of the PostgreSQL subnet.')
output postgresSubnetId string = vnet.properties.subnets[1].id
