@description('Name of the API Management Service to provision')
param apimServicePrefixName string

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string = 'Contoso'

@description('The pricing tier of this API Management service')
@allowed([
  'Basic'
  'Consumption'
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

param apimVnetPrefixName string
param apimSubnetName string
param apimNetworkType string

param gatewayCustomHostnamePrefix string

param gatewayCustomHostnameDomain string

@description('The instance size of this API Management service.')
param skuCount int = 1

param keyVaultPrefixName string
param keyVaultUaiPrefixName string

@description('Location for all resources.')
param location string = resourceGroup().location

var apimServiceName = '${apimServicePrefixName}-${uniqueString(resourceGroup().id)}'
var apimVnetName = '${apimVnetPrefixName}-${uniqueString(resourceGroup().id)}'

var keyVaultName = '${keyVaultPrefixName}-${uniqueString(resourceGroup().id)}'
var keyVaultUaiName = '${keyVaultUaiPrefixName}-${uniqueString(resourceGroup().id)}'
var gatewayCustomHostname = '${gatewayCustomHostnamePrefix}-${uniqueString(resourceGroup().id)}.${gatewayCustomHostnameDomain}'

resource keyVaultUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: keyVaultUaiName
}

// resource sslCertSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' existing = {
//   name: '${keyVaultName}/sslCert'
// }

resource apim 'Microsoft.ApiManagement/service@2021-04-01-preview' = {
  name: apimServiceName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${keyVaultUai.id}': {}
    }
  }
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    hostnameConfigurations: [
      // {
      //   type: 'Proxy'
      //   hostName: gatewayCustomHostname
      //   keyVaultId: 'https://kv-v74i2yr6x5viy.vault.azure.net/secrets/sslCert/5c60e2b5e2424c4580da036a32966503'
      //   identityClientId: keyVaultUai.properties.clientId
      //   defaultSslBinding: true
      //   certificatePassword: 'azerty'
      // }
    ]
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkConfiguration:{
      subnetResourceId: resourceId('Microsoft.Network/VirtualNetworks/subnets', apimVnetName, apimSubnetName)
    }
    virtualNetworkType: apimNetworkType
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }
}
