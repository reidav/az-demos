param lawPrefixName string
param lawSku string

@description('Location for all resources.')
param location string = resourceGroup().location

var lawName = '${lawPrefixName}-${uniqueString(resourceGroup().id)}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: lawName
  location: location
  properties:{
    sku:{
      name: lawSku
    }
    retentionInDays: 30
  }
}
