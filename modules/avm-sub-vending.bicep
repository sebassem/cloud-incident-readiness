targetScope = 'managementGroup'

@description('Optional. The location to deploy resources to.')
param resourceLocation string = deployment().location

@description('Optional. The subscription billing scope.')
param subscriptionBillingScope string = 'providers/Microsoft.Billing/billingAccounts/7690848/enrollmentAccounts/350580'

module subscriptionVending 'br/public:avm/ptn/lz/sub-vending:0.2.4' = {
  name: uniqueString(deployment().name, resourceLocation)
  params: {
    subscriptionAliasEnabled: true
    subscriptionBillingScope: subscriptionBillingScope
    subscriptionAliasName: 'HR-ProjectPhoenix'
    subscriptionDisplayName: 'HR-ProjectPhoenix'
    subscriptionWorkload: 'Production'
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: 'alz-corp'
    virtualNetworkEnabled: true
    virtualNetworkResourceGroupName: 'rg-hrphoenix'
    virtualNetworkAddressSpace: [
      '10.0.0.0/16'
    ]
    resourceProviders: {}
  }
}
