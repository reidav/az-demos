targetScope = 'subscription'
param location string = deployment().location

@description('Environment name')
param env string

@description('Monitor settings')
param monitor object

@description('keyvault settings')
param keyvault object

@description('api management settings')
param apim object

@description('vm settings')
param vm object

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
var apimName = '${apim.name}-${suffix}'
// var appGatewayPipName = '${appgw.name}-${suffix}'

module networking './modules/network/main.bicep' = {
  name: 'networking'
  scope: rgNetworking
  params: {
    location: location
    suffix: suffix
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

module key './modules/shared/keyvault/keyvault.bicep' = {
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

// Management --------------------------------------------------------

module bastion 'modules/shared/bastion.bicep' = {
  scope: rgShared
  name: 'bastion'
  params: {
    subnetResourceId: '${networking.outputs.vnetId}/subnets/AzureBastionSubnet'
    location: location
    bastionName: 'bastion-${suffix}'
    bastionPublicIpName: 'pip-bastion-${suffix}'
  }
}


module virtualMachine 'modules/shared/vm.bicep' = {
  scope: rgShared
  name: 'vm'
  params: {
    username: vm.username
    password: vm.password
    subnetResourceId: '${networking.outputs.vnetId}/subnets/${vm.subnetName}'
    vmName: vm.name
    location: location
    osDiskType: vm.osDiskType
    vmSize: vm.vmSize
    windowsOSVersion: vm.windowsOSVersion
  }
}

// Backend -----------------------------------------------------------

module backend './modules/backend/main.bicep' = {
  scope: rgBackend 
  name: 'backend'
  params: {
    appInsightsName: 'ai-backend-${suffix}'
    functionAppName: 'fa-backend-${suffix}'
    functionName: 'f-backend-${suffix}'
    hostingPlanName: 'hpn-backend-${suffix}'
    storageAccountName: 'sanbackend${suffix}'
    location: location
    backendSubnetId: '${networking.outputs.vnetId}/subnets/backend-snet'
    backendResourceGroupName: backendResourceGroupName
    networkingResourceGroupName: networkingResourceGroupName
    suffix: suffix
    vnetName: networking.outputs.vnetName
    peSubnetId: networking.outputs.peSubnetId
    vnetId: networking.outputs.vnetId
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
    vnetName: networking.outputs.vnetName
    vnetRG: rgNetworking.name
    apimName: apimName
    apimRG: rgApim.name
  }
}

// module appgwModule './modules/gateway/appgw.bicep' = {
//   name: 'appgwDeploy'
//   scope: rgApim
//   dependsOn: [
//     apiManagement
//     dnsZoneModule
//   ]
//   params: {
//     location:                  location
//     appGatewayName:            appgw.name
//     appGatewayFQDN:            appgw.fqdn
//     appGatewaySubnetId:        '${networking.outputs.vnetId}/subnets/${appgw.subnetName}'
//     primaryBackendEndFQDN:     '${apimName}.azure-api.net'
//     keyVaultName:              key.name
//     keyVaultResourceGroupName: rgShared.name
//     appGatewayCerts: appgw.certificates
//     appGatewayPipName: appGatewayPipName
//     keyVaultUserAssignedIdentity: key.outputs.userIdentityId
//   }
// }
