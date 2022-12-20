param vnetName string
param vnetPrefix string
param vnetSubnets array
param vnetTags object

param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    enableDdosProtection: false
    subnets: [for subnet in vnetSubnets: {
      name: subnet.Name
      properties: {
        addressPrefix: subnet.AddressSpace
      }
    }]
  }
}
