@description('Name of the KeyVault to provision')
param keyVaultPrefixName string

param keyVaultUaiPrefixName string

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param keyVaultSkuName string = 'standard'

@description('The base64 encoded SSL certificate in PFX format to be stored in Key Vault. CN and SAN must match the custom hostname of API Management Service.')
@secure()
param sslCertValue string

@description('Location for all resources.')
param location string = resourceGroup().location

var keyVaultName = '${keyVaultPrefixName}-${uniqueString(resourceGroup().id)}'
var keyVaultUaiName = '${keyVaultUaiPrefixName}-${uniqueString(resourceGroup().id)}'
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: keyVaultUaiName
  location: location
 }

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: keyVaultSkuName
      family: 'A'
    }
    tenantId: userIdentity.properties.tenantId
    enableRbacAuthorization: true
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: 7
  }
}

resource sslCertSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${kv.name}/sslCert'
  properties: {
    value: sslCertValue
    contentType: 'application/x-pkcs12'
    attributes: {
      enabled: true
    }
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultSecretsUserRoleDefinitionId,userIdentity.id,kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output kvName string = kv.name
output kvUserIdentityName string = userIdentity.name
