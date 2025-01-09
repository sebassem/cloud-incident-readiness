targetScope = 'managementGroup'

@description('Subscription display name.')
param displayName string = 'HRphoneix'

param virtualNetworkEnabled string = 'No'

param virtualNetworkAddressSpace string = '[]'

param virtualNetworkPeeringEnabled string = 'No'

param hubNetworkResourceId string = ''

module subscription 'br/public:avm/ptn/lz/sub-vending:0.2.4' = {
  name: '${displayName}-sub-deployment'
  params: {
    existingSubscriptionId: '218de717-3c21-4660-b84b-abd493dc085d'
    resourceProviders: {}
    subscriptionDisplayName: displayName
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: 'alz-corp'
    virtualNetworkEnabled: virtualNetworkEnabled == 'No' ? false : true
    virtualNetworkAddressSpace: array(virtualNetworkAddressSpace)
    virtualNetworkPeeringEnabled: virtualNetworkPeeringEnabled == 'No' ? false : true
    hubNetworkResourceId: hubNetworkResourceId

  }
}