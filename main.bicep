@description('Virtual machine windows admin username')
param adminUsername string = 'cloudAdmin'

@description('Virtual machine windows admin password')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual network name')
param virtualNetworkName string = 'vnet001'

@description('Virtual network address prefix')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: {
    location: location
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkName: virtualNetworkName
  }
}
module vmss 'br/public:avm/res/compute/virtual-machine-scale-set:0.5.0' = {
  name: 'vmss'
  params: {
    name: 'vmss'
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    skuCapacity: 3
    upgradePolicyMode: 'Automatic'
    encryptionAtHost: false
    nicConfigurations:  [
      {
        enableAcceleratedNetworking: false
        nsgId: networking.outputs.nsgId
        ipConfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              subnet: {
                id: networking.outputs.virtualNetworkSubnets[0].id
              }
              loadBalancerBackendAddressPools: [
                {
                  id: networking.outputs.backendpools[0].id
                }
            ]
            }
          }
        ]
        nicSuffix: '-nic01'
      }
    ]
    osDisk: {
        createOption: 'fromImage'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
    }
    extensionCustomScriptConfig: {
      enabled: true
      fileData: [
        {
          uri: 'https://raw.githubusercontent.com/sebassem/cloud-incident-readiness/main/scripts/deploy-webapp.ps1'
        }
      ]
        protectedSettings: {
          commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File deploy-webapp.ps1'
        }
    }
    osType: 'Windows'
    skuName: 'Standard_D2s_v5'
  }
}

module utilities 'modules/utilities.bicep' = {
  name: 'utilities'
  params: {
    vmssResourceId: vmss.outputs.resourceId
    vmssName: vmss.outputs.name
    vnetResourceId: networking.outputs.virtualNetworkId
    lbResourceId: networking.outputs.lbResourceId
    nsgResourceId: networking.outputs.nsgId
    location: location
  }
}

output frontendIpAddress string = networking.outputs.loadBalancerIpAddress
