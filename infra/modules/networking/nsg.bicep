targetScope = 'resourceGroup'

@description('Name of the network security group.')
param name string

@description('Azure region used for this resource.')
param location string

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: name
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

@description('Resource ID of the network security group.')
output id string = nsg.id
