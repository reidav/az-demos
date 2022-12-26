targetScope = 'subscription'
param location string = deployment().location

@description('Environment name')
param env string

@description('Monitor settings')
param monitor object

@description('keyvault settings')
param keyvault object

@description('Virtual network settings')
param virtualNetwork object

@description('api management settings')
param apim object

@description('app gateway settings')
param appgw object

// Resource Groups ---------------------------------------------------------

var suffix = uniqueString(env)
var networkingResourceGroupName = 'rg-${env}-nw'
var apimResourceGroupName = 'rg-${env}-apim'
var backendResourceGroupName = 'rg-${env}-backend'
var sharedResourceGroupName = 'rg-${env}-shared'

resource rgNetworking 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingResourceGroupName
  location: location
}

resource rgBackend 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: backendResourceGroupName
  location: location
}

resource rgShared 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: sharedResourceGroupName
  location: location
}

resource rgApim 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: apimResourceGroupName
  location: location
}

// Networking ---------------------------------------------------------

var vnetName = '${virtualNetwork.name}-${suffix}'
var apimName = '${apim.name}-${suffix}'
var appGatewayPipName = '${appgw.name}-${suffix}'

module networking './modules/layers/networking.bicep' = {
  scope: rgNetworking
  name: vnetName
  params: {
    name: vnetName
    addressPrefix: virtualNetwork.addressPrefix
    subnets: virtualNetwork.subnets
    location: location
  }
}

// Shared ---------------------------------------------------------

var lawName = '${monitor.lawName}-${suffix}'
var kvName = '${keyvault.name}-${suffix}'
var kvUserAssignedIdentityName = '${keyvault.userAssignedIdentityName}-${suffix}'
var appInsightName = '${monitor.appInsightName}-${suffix}'

module azMonitor './modules/shared/monitor.bicep' = {
  scope: rgShared
  name: 'azMonitor'
  params: {
    location: location
    appInsightName: appInsightName
    lawName: lawName
    lawSku: monitor.lawSku
  }
}

module key './modules/keyvault/keyvault.bicep' = {
  scope: rgShared 
  name: kvName
  params: {
    name: kvName
    sku: keyvault.sku
    location: location
    userAssignedIdentityName: kvUserAssignedIdentityName
    certificates: keyvault.certificates
  }
}

// API Management / App Gateway --------------------------------------

module apiManagement './modules/apim/apim.bicep' = {
  scope: rgApim
  name: apimName
  dependsOn: [
    networking
    key
  ]
  params: {
    name: apimName
    sku: apim.sku
    location: location
    publisherEmail: apim.publisherEmail
    subnetResourceId: '${networking.outputs.vnetId}/subnets/${apim.subnetName}'
    keyVaultUserAssignedIdentity: key.outputs.userIdentityId
  }
}

module dnsZoneModule './modules/shared/dnszone.bicep'  = {
  name: 'apimDnsZoneDeploy'
  scope: rgShared
  dependsOn: [
    apiManagement
  ]
  params: {
    vnetName: vnetName
    vnetRG: rgNetworking.name
    apimName: apimName
    apimRG: rgApim.name
  }
}

module appgwModule './modules/gateway/appgw.bicep' = {
  name: 'appgwDeploy'
  scope: rgApim
  dependsOn: [
    apiManagement
    dnsZoneModule
  ]
  params: {
    location:                  location
    appGatewayName:            appgw.name
    appGatewayFQDN:            appgw.fqdn
    appGatewaySubnetId:        '${networking.outputs.vnetId}/subnets/${appgw.subnetName}'
    primaryBackendEndFQDN:     '${apimName}.azure-api.net'
    keyVaultName:              key.name
    keyVaultResourceGroupName: rgShared.name
    appGatewayCerts: appgw.certificates
    appGatewayPipName: appGatewayPipName
    keyVaultUserAssignedIdentity: key.outputs.userIdentityId
  }
}
