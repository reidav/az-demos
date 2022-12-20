param ipName string
param dnsName string
param tags object
param location string = resourceGroup().location

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: ipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties:{
    publicIPAllocationMethod:'Static'
    dnsSettings:{
      domainNameLabel: dnsName
    }
  }
}
