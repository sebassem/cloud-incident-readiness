targetScope = 'managementGroup'

@description('Subscription display name.')
param subscriptionName string = 'HRphoneix'


module subscription 'br/public:avm/ptn/lz/sub-vending:0.2.4' = {
  name: '${subscriptionName}-sub-deployment'
  params: {
    existingSubscriptionId: '218de717-3c21-4660-b84b-abd493dc085d'
    resourceProviders: {}
    subscriptionDisplayName: subscriptionName
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: 'alz-corp'
  }
}

