targetScope = 'resourceGroup'

param privateEndpointName string
param groupId string
param location string
param vnetName string
param vnetRG string
param subnetId string
param storageAccountId string
param storageName string 
param standardDomain string = 'windows.net'
param domain string = 'privatelink.${groupId}.core.${standardDomain}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRG)
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: domain
  location: 'global'
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${domain}/${uniqueString(vnet.id)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
  dependsOn: [
    dnsZone
  ]
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {      
        name: '${storageName}-${groupId}-core-windows-net'
        properties: {
          privateDnsZoneId: dnsZone.id          
        }
      }
    ]
  }
  dependsOn: [
    vnetLinks
  ]
}

// output privateEndpointId string = privateEndpoint.id
// output dnsZoneId string = dnsZone.outputs.dnsZoneId
// output dnsZoneGroupId string = dnsZone.outputs.dnsZoneGroupId
// output vnetLinksId string = dnsZone.outputs.vnetLinksLink
