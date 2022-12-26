param name string
param addressPrefix string
param subnets array

param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    enableDdosProtection: false
    subnets: [for subnet in subnets: {
      name: subnet.Name
      properties: {
        addressPrefix: subnet.AddressSpace
      }
    }]
  }
}

output vnetId string = vnet.id
