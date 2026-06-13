targetScope = 'subscription'

@description('Azure region used for the resource group.')
param location string

@description('Name of the resource group.')
param name string

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: name
  location: location
}

@description('Name of the resource group.')
output name string = rg.name
