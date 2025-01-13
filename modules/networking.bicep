@description('Location for all resources.')
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-hrphoenix'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'subnet001'
  parent: vnet
  properties: {
    addressPrefix: '10.0.1.0/24'
    networkSecurityGroup: {
      id: nsg.outputs.resourceId
    }
    natGateway: {
      id: natGateway.outputs.resourceId
    }
  }
}

resource dsSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'dssubnet'
  parent: vnet
  dependsOn: [
    subnet
  ]
  properties: {
    addressPrefix: '10.0.2.0/24'
    networkSecurityGroup: {
      id: nsg.outputs.resourceId
    }
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
    delegations: [
      {
        name: 'containerDelegation'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
      }
    ]
  }
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'peSubnet'
  parent: vnet
  dependsOn: [
    subnet
    dsSubnet
  ]
  properties: {
    addressPrefix: '10.0.3.0/24'
    networkSecurityGroup: {
      id: nsg.outputs.resourceId
    }
  }
}

module deploymentScriptMSI 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'deploymentScriptMSI'
  params: {
    name: 'msi-deployment-script'
  }
}

module storageFileSharePermissions 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'storageFileSharePermissions'
  params: {
    principalId: deploymentScriptMSI.outputs.principalId
    resourceId: dsStorageAccount.outputs.resourceId
    roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
    principalType: 'ServicePrincipal'
  }
}

module dsStorageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'dsStorageAccount'
  dependsOn: [
    dsSubnet
    peSubnet
  ]
  params: {
    name: 'stg${uniqueString(resourceGroup().id,location)}'
    location: location
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    publicNetworkAccess: 'Disabled'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    networkAcls: {
      bypass:'AzureServices'
      defaultAction: 'Deny'
    }
    privateEndpoints: [
      {
        service: 'file'
        subnetResourceId: filter(vnet.properties.subnets, subnet => subnet.name == 'peSubnet')[0].id
        privateDnsZoneGroup: {
          name: 'default'
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateFileDNSZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

module privateFileDNSZone 'br/public:avm/res/network/private-dns-zone:0.5.0' = {
  name: 'fileDnsZone'
  params: {
    name: 'privatelink.file.${environment().suffixes.storage}'
    location: 'global'
    virtualNetworkLinks: [
      {
        name: '${vnet.name}-storageaccount-link'
        virtualNetworkResourceId: vnet.id
        registrationEnabled: false
      }
    ]
  }
}
module natGatewayPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.7.1' = {
  name: 'natGwPublicIpAddress'
  params: {
    name: 'natip001'
    location: location
    skuName: 'Standard'
  }
}

module natGateway 'br/public:avm/res/network/nat-gateway:1.2.1' = {
  name: 'natGateway'
  params: {
    name: 'natgw001'
    zone: 0
    location: location
    publicIpResourceIds: [
      natGatewayPublicIpAddress.outputs.resourceId
    ]
  }
}

module nsg 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsg'
  params: {
    name: 'nsg001'
    location: location
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 200
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

module lbPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.7.1' = {
  name: 'lbPublicIpAddress'
  params: {
    name: 'lbip001'
    location: location
    skuName: 'Standard'
  }
}

module loadBalancer 'br/public:avm/res/network/load-balancer:0.4.1' = {
  name: 'loadBalancer'
  params: {
    name: 'lb001'
    frontendIPConfigurations: [
      {
        name: 'publicIPConfig1'
        publicIPAddressId: lbPublicIpAddress.outputs.resourceId
      }
    ]
    backendAddressPools: [
      {
        name: 'vmssBackendPool'
      }
    ]
    loadBalancingRules: [
      {
        backendAddressPoolName: 'vmssBackendPool'
        backendPort: 80
        frontendIPConfigurationName: 'publicIPConfig1'
        frontendPort: 80
        idleTimeoutInMinutes: 5
        loadDistribution: 'Default'
        name: 'publicIPLBRule1'
        probeName: 'probe1'
        protocol: 'Tcp'
      }
    ]
    probes: [
      {
        intervalInSeconds: 10
        name: 'probe1'
        numberOfProbes: 5
        port: 80
        protocol: 'Http'
        requestPath: '/'
      }
    ]
  }
}



output nsgId string = nsg.outputs.resourceId
output natGatewayId string = natGateway.outputs.resourceId
output virtualNetworkId string = vnet.id
output virtualNetworkSubnetResourceId string = filter(vnet.properties.subnets, subnet => subnet.name == 'subnet001')[0].id
output deploymentScriptSubnetResourceId string = filter(vnet.properties.subnets, subnet => subnet.name == 'dssubnet')[0].id
output loadBalancerIpAddress string = lbPublicIpAddress.outputs.ipAddress
output lbResourceId string = loadBalancer.outputs.resourceId
output backendpools array = loadBalancer.outputs.backendpools
output deploymentScriptMSIId string = deploymentScriptMSI.outputs.resourceId
output deploymentScriptMSIPrincipalId string = deploymentScriptMSI.outputs.principalId
output deploymentScriptStorageAccountResourceId string = dsStorageAccount.outputs.resourceId