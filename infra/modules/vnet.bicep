targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Naming convention: {abbrev}-{workload}-{env}-{region}-{instance}
// Subnet names are purpose-scoped (not per-environment) as they live inside the VNet.
// ---------------------------------------------------------------------------

var vnetName = 'vnet-${workload}-${env}-${region}-${instance}'

// NSG: Container Apps subnet — deny all inbound by default, allow VNet-internal traffic
resource nsgContainerApp 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-${workload}-${env}-${region}-${instance}-containerapp'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-VNet-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
          description: 'Allow intra-VNet traffic.'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Deny all other inbound traffic.'
        }
      }
    ]
  }
}

// NSG: PostgreSQL subnet — deny all inbound by default, allow VNet-internal traffic
resource nsgPostgres 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-${workload}-${env}-${region}-${instance}-postgres'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-VNet-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
          description: 'Allow intra-VNet traffic.'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Deny all other inbound traffic.'
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Virtual Network
// ---------------------------------------------------------------------------

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
            id: nsgContainerApp.id
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
            id: nsgPostgres.id
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

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('Resource ID of the virtual network.')
output vnetId string = vnet.id

@description('Resource ID of the Container Apps subnet (consumed by the Container Apps Environment — see issue #27).')
output containerAppSubnetId string = vnet.properties.subnets[0].id

@description('Resource ID of the PostgreSQL subnet (consumed by the PostgreSQL Flexible Server module — see issue #29).')
output postgresSubnetId string = vnet.properties.subnets[1].id
