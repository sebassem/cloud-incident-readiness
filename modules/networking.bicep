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
output virtualNetworkSubnetResourceId string = vnet.properties.subnets[0].id
output loadBalancerIpAddress string = lbPublicIpAddress.outputs.ipAddress
output lbResourceId string = loadBalancer.outputs.resourceId
output backendpools array = loadBalancer.outputs.backendpools