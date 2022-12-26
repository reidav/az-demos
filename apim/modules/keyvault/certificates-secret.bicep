targetScope = 'resourceGroup'

param keyVaultName string

param keyVaultCertificates array

resource kvCertificates 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = [for cert in keyVaultCertificates: {
  name: '${keyVaultName}/${cert.secretName}'
}]

output certificates array = [for (cert, i) in keyVaultCertificates: {
  name: kvCertificates[i].name
  id: kvCertificates[i].id
  secretName: cert.secretName
  secretUriWithVersion: kvCertificates[i].properties.secretUriWithVersion
}]
