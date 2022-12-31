param storageAccountName string
param appInsightsName string
param hostingPlanName string
param functionAppName string
param functionName string

param vnetId string
param vnetName string
param networkingResourceGroupName string

param backendResourceGroupName string

param backendSubnetId string
param peSubnetId string

param suffix string

param location string = resourceGroup().location

resource rgNetworking 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: networkingResourceGroupName
}

// Storage Account ------------------------------------------------------------

var pepSaQueue = 'pep-sa-queue-${suffix}'
var pepSaBlob = 'pep-sa-blob-${suffix}'
var pepSaFile = 'pep-sa-file-${suffix}'
var pepSaTable = 'pep-sa-table-${suffix}'
var functionContentShareName = 'func-contents'

module storageAccount 'lib/storage-account.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup(backendResourceGroupName)
  params: {
    name: storageAccountName
    location: location
  }
}

module queueStoragePrivateEndpoint './lib/pe-dns.bicep' = {
  name: pepSaQueue
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    location: location
    privateEndpointName: pepSaQueue
    groupId: 'queue'
    storageAccountId: storageAccount.outputs.id
    vnetName: vnetName
    vnetRG: rgNetworking.name
    subnetId: peSubnetId
    storageName: storageAccountName
  }
  dependsOn: [
    storageAccount
  ]
}

module blobStoragePrivateEndpoint './lib/pe-dns.bicep' = {
  name: pepSaBlob
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    location: location
    privateEndpointName: pepSaBlob
    groupId: 'blob'
    storageAccountId: storageAccount.outputs.id
    vnetName: vnetName
    vnetRG: rgNetworking.name
    subnetId: peSubnetId
    storageName: storageAccountName
  }
  dependsOn: [
    storageAccount
  ]
}

module tableStoragePrivateEndpoint './lib/pe-dns.bicep' = {
  name: pepSaTable
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    location: location
    privateEndpointName: pepSaTable
    groupId: 'table'
    storageAccountId: storageAccount.outputs.id
    vnetName: vnetName
    vnetRG: rgNetworking.name
    subnetId: peSubnetId
    storageName: storageAccountName
  }
  dependsOn: [
    storageAccount
  ]
}

module fileStoragePrivateEndpoint './lib/pe-dns.bicep' = {
  name: pepSaFile
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    location: location
    privateEndpointName: pepSaFile
    groupId: 'file'
    storageAccountId: storageAccount.outputs.id
    vnetName: vnetName
    vnetRG: rgNetworking.name
    subnetId: peSubnetId
    storageName: storageAccountName
  }
  dependsOn: [
    storageAccount
  ]
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccountName}/default/${functionContentShareName}'
  dependsOn: [
    storageAccount
  ]
}

// Monitoring -----------------------------------------------------------------

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Hosting Plan ----------------------------------------------------------------

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    family: 'EP'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
    reserved: true
  }
}

// Function App ----------------------------------------------------------------

module functionApp './lib/function.bicep' = {
  name: functionAppName
  scope: resourceGroup(backendResourceGroupName)
  params: {
    location: location
    storageAccountName: storageAccountName
    functionContentShareName: functionContentShareName
    backendSubnetId: backendSubnetId
    suffix: suffix
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
    backendResourceGroupName: backendResourceGroupName
    functionAppName: functionAppName
    functionName: functionName
    hostingPlanId: hostingPlan.id
    networkingResourceGroupName: networkingResourceGroupName
    peSubnetId: peSubnetId
    vnetId: vnetId
    vnetName: vnetName
  }
  dependsOn: [
    storageAccount
    fileShare
    fileStoragePrivateEndpoint
    blobStoragePrivateEndpoint
    queueStoragePrivateEndpoint
    tableStoragePrivateEndpoint
  ]
}
