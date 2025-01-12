targetScope = 'managementGroup'

@description('Optional. The location to deploy resources to.')
param resourceLocation string = deployment().location

@description('Optional. The subscription billing scope.')
param subscriptionBillingScope string = 'providers/Microsoft.Billing/billingAccounts/7690848/enrollmentAccounts/350580'

module subscriptionVending 'br/public:avm/ptn/lz/sub-vending:0.2.4' = {
  name: uniqueString(deployment().name, resourceLocation)
  params: {
    subscriptionAliasName: 'HR-ProjectPhoenix'
    subscriptionDisplayName: 'HR-ProjectPhoenix'
    subscriptionAliasEnabled: true
    subscriptionBillingScope: subscriptionBillingScope
    subscriptionWorkload: 'Production'
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: 'alz-corp'
    virtualNetworkEnabled: true
    virtualNetworkResourceGroupName: 'rg-hrphoenix'
    virtualNetworkAddressSpace: [
      '10.0.0.0/16'
    ]
    resourceProviders: {
        'Microsoft.AVS': ['AzureServicesVm']
    }
    roleAssignmentEnabled: true
    roleAssignments: [
      {
        definition: 'Contributor'
        principalId: 'a9d32637-e42f-4e20-808c-83a6ed3d2874'
        relativeScope: ''
      }
    ]
  }
}
