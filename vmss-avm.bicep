@description('Virtual machine windows admin username')
param adminUsername string = 'cloudAdmin'

@description('Virtual machine windows admin password')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The object id of the Phoenix Admin group.')
param principalId string = ''

@description('The role definition id of the contributor role.')
param roleDefinitionId string = ''

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
    osType: 'Windows'
    skuName: 'Standard_D2s_v5'
    skuCapacity: 3
    upgradePolicyMode: 'Manual'
    encryptionAtHost: false
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    osDisk: {
      createOption: 'fromImage'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
  }
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
    roleAssignments: [
      {
        principalId: principalId
        roleDefinitionIdOrName: roleDefinitionId
        principalType: 'User'
      }
    ]
  }
}