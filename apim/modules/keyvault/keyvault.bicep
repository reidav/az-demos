param name string
param sku string
param userAssignedIdentityName string
param certificates array

param location string = resourceGroup().location

var keyVaultAdministratorRoleDefinitionId = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
 }

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: name
  location: location
  properties: {
    sku: {
      name: sku
      family: 'A'
    }
    tenantId: userIdentity.properties.tenantId
    enableRbacAuthorization: true
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: 7
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultAdministratorRoleDefinitionId, userIdentity.id, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultAdministratorRoleDefinitionId)
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvCertificate 'Microsoft.Resources/deploymentScripts@2020-10-01' = [for cert in certificates: {
  name: 'certificate-${cert.name}'
  dependsOn: [
    kv
    kvRoleAssignment
  ]
  location: location 
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.6'
    arguments: ' -certificateName ${cert.name} -vaultName ${name} -certDataString ${cert.data} -certPwd ${cert.password}'
    scriptContent: '''
      param(
      [string] [Parameter(Mandatory=$true)] $certificateName,
      [string] [Parameter(Mandatory=$true)] $vaultName,
      [string] [Parameter(Mandatory=$true)] $certDataString,
      [string] [Parameter(Mandatory=$true)] $certPwd
      )

      $ErrorActionPreference = 'Stop'
      $DeploymentScriptOutputs = @{}
      $ss = Convertto-SecureString -String $certPwd -AsPlainText -Force; 
      Import-AzKeyVaultCertificate -Name $certificateName -VaultName $vaultName -CertificateString $certDataString -Password $ss
      '''
    retentionInterval: 'P1D'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
}]


output userIdentityId string = userIdentity.id
