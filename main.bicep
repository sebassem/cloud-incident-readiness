@secure()
param adminPassword string

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.2.0' = {
  name: 'virtualNetwork'
  params: {
    name: 'vnet001'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'subnet001'
        addressPrefix: '10.0.1.0/24'
        networkSecurityGroupResourceId: nsg.outputs.resourceId
        natGatewayResourceId: natGatweay.outputs.resourceId
      }
    ]
  }
}

module natGatewayPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.5.1' = {
  name: 'natGwPublicIpAddress'
  params: {
    name: 'natip001'
    location: resourceGroup().location
    skuName: 'Standard'
    zones: [
      1
      2
      3
    ]
  }
}

module natGatweay 'br/public:avm/res/network/nat-gateway:1.1.0' = {
  name: 'natGatweay'
  params: {
    name: 'natgw001'
    zone: 0
    location: resourceGroup().location
    publicIpResourceIds: [
      natGatewayPublicIpAddress.outputs.resourceId
    ]
  }
}

module nsg 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: 'nsg'
  params: {
    name: 'nsg001'
    location: resourceGroup().location
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

module vmss 'br/public:avm/res/compute/virtual-machine-scale-set:0.3.0' = {
  name: 'vmss'
  params: {
    name: 'vmss'
    adminUsername: 'sebassem'
    adminPassword: adminPassword
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    skuCapacity: 1
    upgradePolicyMode: 'Automatic'
    nicConfigurations:  [
      {
        enableAcceleratedNetworking: false
        nsgId: nsg.outputs.resourceId
        ipConfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              subnet: {
                id: virtualNetwork.outputs.subnetResourceIds[0]
              }
              publicIPAddressConfiguration: {
                name: 'vmss-pip'
              }
            }
          }
        ]
        nicSuffix: '-nic01'
      }
    ]
    osDisk: {
        createOption: 'fromImage'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
    }
    extensionCustomScriptConfig: {
      enabled: true
      fileData: [
        {
          uri: 'https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis.ps1'
        }
      ]
        protectedSettings: {
          commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1'
        }
    }
    osType: 'Windows'
    skuName: 'Standard_B4ms'
  }
}

/*
module lbPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.5.1' = {
  name: 'lbPublicIpAddress'
  params: {
    name: 'lbip001'
    location: resourceGroup().location
    skuName: 'Standard'
    zones: [
      1
      2
      3
    ]
  }
}

module loadBalancer 'br/public:avm/res/network/load-balancer:0.3.0' = {
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
        disableOutboundSnat: true
        enableFloatingIP: false
        enableTcpReset: false
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
*/