param pipAppGatewayPrefixName string
param vnetPrefixName string
param vnetAddressPrefix string
param vnetSubnets array

var pipAppGatewayName = '${pipAppGatewayPrefixName}-${uniqueString(resourceGroup().id)}'
var vnetName = '${vnetPrefixName}-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

module publicIp '../shared/network/public-ip.bicep' = {
  name: pipAppGatewayName
  params: {
    ipName: pipAppGatewayName
    dnsName: toLower('${pipAppGatewayName}')
    tags: {}
    location: location
  }
}

module vnet '../shared/network/vnet.bicep' = {
  name: vnetName
  params: {
    vnetName: vnetName
    vnetPrefix: vnetAddressPrefix
    vnetTags: {}
    vnetSubnets: vnetSubnets
    location: location
  }
}
