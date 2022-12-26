@description('API management instance name')
@minLength(1)
param name string

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

param networkType string = 'Internal'

@description('The instance size of this API Management service.')
param skuCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Subnet resource id')
@minLength(1)
param subnetResourceId string

@description('Keyvault user assigned identity')
@minLength(1)
param keyVaultUserAssignedIdentity string

resource apim 'Microsoft.ApiManagement/service@2021-04-01-preview' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${keyVaultUserAssignedIdentity}': {}
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
      subnetResourceId: subnetResourceId
    }
    virtualNetworkType: networkType
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }
}
