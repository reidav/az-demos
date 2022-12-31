targetScope = 'resourceGroup'

param vmName string
param subnetResourceId string

param osDiskType string
param vmSize string 
param windowsOSVersion string

param username string

@secure()
param password string

param location string = resourceGroup().location


module nic '../network/lib/vm-nic.bicep' = {
  name: '${vmName}-nic'
  params: {
    location: location
    subnetId: subnetResourceId
    nicName: '${vmName}-nic'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: vmName
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.outputs.nicId
        }
      ]
    }
  }
}
