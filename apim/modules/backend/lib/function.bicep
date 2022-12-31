param storageAccountName string
param functionAppName string
param functionName string

param hostingPlanId string
param appInsightsInstrumentationKey string
param functionContentShareName string

param vnetId string
param vnetName string
param networkingResourceGroupName string

param backendResourceGroupName string

param backendSubnetId string
param peSubnetId string

param suffix string

param location string = resourceGroup().location

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = { 
  name: storageAccountName
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    reserved: true
    vnetRouteAllEnabled: true
    virtualNetworkSubnetId: backendSubnetId
    serverFarmId: hostingPlanId
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'node|14'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};AccountKey=${existingStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};AccountKey=${existingStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: functionContentShareName
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
      ]
    }
  }
  dependsOn: [
    existingStorageAccount
  ]
}

resource function 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: functionName
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          type: 'httpTrigger'
          direction: 'in'
          authLevel: 'anonymous' // The function is configured to use anonymous authentication (i.e. no function key required), since the Azure Functions infrastructure will verify that the request has come through Front Door.
          methods: [
            'get'
          ]
        }
        {
          name: '$return'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('../scripts/run.js')
    }
  }
}

// resource functionHostNameBindings 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
//   parent: functionApp
//   name: '${functionName}.azurewebsites.net'
//   properties: {
//     siteName: 'funccodebe${functionName}'
//     hostNameType: 'Verified'
//   }
// }

resource planNetworkConfig 'Microsoft.Web/sites/networkConfig@2021-01-01' = {
  parent: functionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: backendSubnetId
    swiftSupported: true
  }
}

resource functionHostNameBindings 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
  parent: functionApp
  name: '${functionApp.name}.azurewebsites.net'
  properties: {
    siteName: functionApp.name
    hostNameType: 'Verified'
  }
}

var pepFunc = 'pep-func-01-${suffix}'
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: pepFunc
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: pepFunc
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

var privateDNSZoneName = 'privatelink.azurewebsites.net'

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDNSZoneName}/${uniqueString(vnetId)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  dependsOn: [
    privateDnsZones
    privateEndpoint
  ]
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: '${pepFunc}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'demofn-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
  dependsOn: [
    privateDnsZoneLink
  ]
}
