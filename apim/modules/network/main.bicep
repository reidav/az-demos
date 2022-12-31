param suffix string

param location string = resourceGroup().location

var bastionSubnetName = 'AzureBastionSubnet'
var bastionAddressPrefix = '30.1.14.0/29'

var apimSubnetName = 'apim-snet'
var apimAddressPrefix = '30.1.11.0/28'

var jumpboxSubnetName = 'management-snet'
var jumpboxAddressPrefix = '30.1.13.0/29'

var backendSubnetName = 'backend-snet'
var backendAddressPrefix = '30.1.15.0/29'

var peSubnetName = 'pe-snet'
var peAddressPrefix = '30.1.17.0/28'

var appGwSubnetName = 'appgw-snet'
var appGwAddressPrefix = '30.1.10.0/28'

// Network Security Groups

module bastionNsg './nsg/bastion.bicep' = {
  name: 'bastionNsg'
  params: {
    location: location
  }
}

module apimNsg './nsg/apim.bicep' = {
  name: 'apimNsg'
  params: {
    location: location
  }
}

module jumpboxNsg './nsg/jumpbox.bicep' = {
  name: 'jumpboxNsg'
  params: {
    location: location
  }
}

module backendNsg './nsg/backend.bicep' = {
  name: 'backendNsg'
  params: {
    location: location
  }
}

module peNsg './nsg/pe.bicep' = {
  name: 'peNsg'
  params: {
    location: location
  }
}

// Virtual Network

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'vnet-${suffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '30.1.0.0/16'
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionAddressPrefix
          networkSecurityGroup: {
            id: bastionNsg.outputs.nsgId
          }
        }
      }
      {
        name: jumpboxSubnetName
        properties: {
          addressPrefix: jumpboxAddressPrefix
          networkSecurityGroup: {
            id: jumpboxNsg.outputs.nsgId
          }
        } 
      }
      {
        name: apimSubnetName
        properties: {
          addressPrefix: apimAddressPrefix
          networkSecurityGroup: {
            id: apimNsg.outputs.nsgId
          }
        }
      }
      {
        name: peSubnetName
        properties: {
          addressPrefix: peAddressPrefix
          networkSecurityGroup: {
            id: peNsg.outputs.nsgId
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: backendSubnetName
        properties: {
          addressPrefix: backendAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: backendNsg.outputs.nsgId
          }
        }
      }
      {
        name: appGwSubnetName
        properties: {
          addressPrefix: appGwAddressPrefix
        } 
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name

output bastionSubnetId string = vnet.properties.subnets[0].id
output peSubnetId string = vnet.properties.subnets[3].id
