@description('The resource Id of the virtual machine scale set.')
param vmssResourceId string

@description('The name of the virtual machine scale set.')
param vmssName string

param location string = resourceGroup().location

@description('The resource Id of the virtual network.')
param vnetResourceId string

@description('The resource Id of the load balancer.')
param lbResourceId string

@description('The resource Id of the network security group.')
param nsgResourceId string

@description('The principal Id of the deployment script managed identity.')
param deploymentScriptMSIPrinicipalId string

@description('The resource Id of the deployment script managed identity.')
param deploymentScriptMSIId string

@description('The resource Id of the deployment script storage account.')
param deploymentScriptStorageAccountResourceId string

@description('Resource Id of the deployment script subnet.')
param deploymentScriptSubnetResourceId string

module msiRoleAssignmentScaleSet 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'msiRoleAssignmentScaleSet'
  params: {
    principalId: deploymentScriptMSIPrinicipalId
    resourceId: vmssResourceId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
}

module msiRoleAssignmentVnet 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'msiRoleAssignmentVnet'
  params: {
    principalId: deploymentScriptMSIPrinicipalId
    resourceId: vnetResourceId
    roleDefinitionId: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  }
}


module msiRoleAssignmentLB 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'msiRoleAssignmentVnetLb'
  params: {
    principalId: deploymentScriptMSIPrinicipalId
    resourceId: lbResourceId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
}

module msiRoleAssignmentNsg 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'msiRoleAssignmentVnetNsg'
  params: {
    principalId: deploymentScriptMSIPrinicipalId
    resourceId: nsgResourceId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
}


module updateVMSS 'br/public:avm/res/resources/deployment-script:0.5.1' = {
  name: 'updateVMSS'
  params: {
    name: 'update-vmss'
    kind: 'AzureCLI'
    azCliVersion: '2.64.0'
    managedIdentities: {
      userAssignedResourceIds: [
        deploymentScriptMSIId
      ]
    }
    environmentVariables: [
      {
        name: 'resourceGroup'
        value: resourceGroup().name
      }
      {
        name: 'vmssName'
        value: vmssName
      }
    ]
    storageAccountResourceId: deploymentScriptStorageAccountResourceId
    containerGroupName: 'update-vmss'
    subnetResourceIds: [
      deploymentScriptSubnetResourceId
    ]
    cleanupPreference: 'OnSuccess'
    location: location
    timeout: 'P1D'
    scriptContent: '''
      az login --identity
      az vmss update-instances --resource-group $resourceGroup --name $vmssName --instance-ids "*" --only-show-errors --no-wait
    '''
  }
}