targetScope = 'subscription'

param rgName string

@description('Location for all resources.')
param location string = deployment().location

module rg '../shared/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}
