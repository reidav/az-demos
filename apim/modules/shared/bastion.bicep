targetScope = 'resourceGroup'

param bastionName string
param bastionPublicIpName string
param subnetResourceId string

param location string = resourceGroup().location

// Public IP 
// resource pip 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
//   name: publicIPAddressName
//   location: location
//   properties: {
//     publicIPAllocationMethod: 'Dynamic'
//   }
// }

// Mind the PIP for bastion being Standard SKU, Static IP
resource pipBastion 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-07-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipBastion.id             
          }
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
  }
} 
