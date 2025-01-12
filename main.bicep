@description('Virtual machine windows admin username')
param adminUsername string = 'cloudAdmin'

@description('Virtual machine windows admin password')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The object id of the Phoenix Admin group.')
param phoeinxAdminGroupObjectId string = 'a9d32637-e42f-4e20-808c-83a6ed3d2874'

module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: {
    location: location
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
    upgradePolicyMode: 'Manual'
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
                id: networking.outputs.virtualNetworkSubnetResourceId
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
    deploymentScriptMSIPrinicipalId: networking.outputs.deploymentScriptMSIPrincipalId
    deploymentScriptMSIId: networking.outputs.deploymentScriptMSIId
    deploymentScriptStorageAccountResourceId: networking.outputs.deploymentScriptStorageAccountResourceId
    deploymentScriptSubnetResourceId: networking.outputs.deploymentScriptSubnetResourceId
  }
}

output frontendIpAddress string = networking.outputs.loadBalancerIpAddress
