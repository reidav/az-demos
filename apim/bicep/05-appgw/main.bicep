
param appGwServiceNamePrefixName string
param appGwSkuName string
param appGwVnetPrefixName string
param appGwSubnetName string
param pipAppGatewayPrefixName string

param lawPrefixName string
param keyVaultUaiPrefixName string

@description('Location for all resources.')
param location string = resourceGroup().location

var appGwServiceName = '${appGwServiceNamePrefixName}-${uniqueString(resourceGroup().id)}'
var appGwVnetName = '${appGwVnetPrefixName}-${uniqueString(resourceGroup().id)}'
var pipAppGatewayName = '${pipAppGatewayPrefixName}-${uniqueString(resourceGroup().id)}'

// var keyVaultName = '${keyVaultPrefixName}-${uniqueString(resourceGroup().id)}'
var keyVaultUaiName = '${keyVaultUaiPrefixName}-${uniqueString(resourceGroup().id)}'
var lawName = '${lawPrefixName}-${uniqueString(resourceGroup().id)}'
// var gatewayCustomHostname = '${gatewayCustomHostnamePrefix}-${uniqueString(resourceGroup().id)}.${gatewayCustomHostnameDomain}'

resource keyVaultUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: keyVaultUaiName
}

resource applicationGateWay 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: appGwServiceName
  location: location
  identity:{
    type:'UserAssigned'
    userAssignedIdentities:{
      '${keyVaultUai.id}' : {}
    }
  }
  properties: {
    sku: {
      name: appGwSkuName
      tier: appGwSkuName
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', appGwVnetName, appGwSubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${pipAppGatewayName}')
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'myBackendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'myHTTPSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'myListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwServiceName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwServiceName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwServiceName, 'myListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwServiceName, 'myBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwServiceName, 'myHTTPSetting')
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
}

resource diagSettings 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'writeToLogAnalytics'
  scope: applicationGateWay
  properties:{
   workspaceId : resourceId('Microsoft.OperationalInsights/workspaces', lawName)
    logs:[
      {
        category: 'ApplicationGatewayAccessLog'
        enabled:true
        retentionPolicy:{
          enabled:true
          days: 20
        }
      }
      {
       category: 'ApplicationGatewayPerformanceLog'
       enabled:true
       retentionPolicy:{
         enabled:true
         days: 20
       }
     }  
     {
       category: 'ApplicationGatewayFirewallLog'
       enabled:true
       retentionPolicy:{
         enabled:true
         days: 20
       }
     }           
    ]
    metrics:[
      {
        enabled:true
        timeGrain: 'PT1M'
        retentionPolicy:{
         enabled:true
         days: 20
       }
      }
    ]
  }
 }
