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

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-07-01' = {
  name: 'vmss'
  location: location
  sku: {
    capacity: 3
    name: 'Standard_D2s_v5'
  }
  properties: {
    virtualMachineProfile: {
      osProfile: {
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      storageProfile: {
        imageReference: {
          offer: 'WindowsServer'
          publisher: 'MicrosoftWindowsServer'
          sku: '2022-datacenter-azure-edition'
          version: 'latest'
        }
        osDisk: {
          createOption: 'fromImage'
          diskSizeGB: 128
          osType: 'Windows'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      }
      securityProfile: {
        encryptionAtHost: false
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic01'
            properties: {
              enableAcceleratedNetworking: false
              networkSecurityGroup: {
                id: networking.outputs.nsgId
              }
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
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'customScriptExtension'
            properties: {
              protectedSettings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File deploy-webapp.ps1'
              }
              settings: [
                {
                  fileData: 'https://raw.githubusercontent.com/sebassem/cloud-incident-readiness/main/scripts/deploy-webapp.ps1'
                  uri: 'https://raw.githubusercontent.com/sebassem/cloud-incident-readiness/main/scripts/deploy-webapp.ps1'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

resource vmssRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'vmssRoleAssignment'
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'User'
  }
}