targetScope = 'managementGroup'

@description('Subscription display name.')
param displayName string = 'HRphoneix'

param virtualNetworkEnabled string = 'Yes'

param virtualNetworkAddressSpace string = '10.0.0.0/16'

param virtualNetworkPeeringEnabled string = 'No'

param hubNetworkResourceId string = ''

var addressSpace = [virtualNetworkAddressSpace]

module subscription 'br/public:avm/ptn/lz/sub-vending:0.2.4' = {
  name: '${displayName}-sub-deployment'
  params: {
    existingSubscriptionId: '218de717-3c21-4660-b84b-abd493dc085d'
    resourceProviders: {}
    subscriptionDisplayName: displayName
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: 'alz-corp'
    virtualNetworkEnabled: virtualNetworkEnabled == 'No' ? false : true
    virtualNetworkName: 'vnet-${displayName}'
    virtualNetworkResourceGroupName: 'rg-${displayName}-vnet'
    virtualNetworkAddressSpace: addressSpace
    virtualNetworkPeeringEnabled: virtualNetworkPeeringEnabled == 'No' ? false : true
    hubNetworkResourceId: hubNetworkResourceId

  }
}
