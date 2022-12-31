param location string = resourceGroup().location

resource jumpboxNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'jumpbox-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow all - inbound'
        properties: {
          priority: 2000
          sourceAddressPrefix: '*'
          protocol: '*'
          destinationPortRange: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow all - outbound'
        properties: {
          priority: 2010
          sourceAddressPrefix: '*'
          protocol: '*'
          destinationPortRange: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output nsgId string = jumpboxNsg.id
