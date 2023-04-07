param resourceToken string
param location string = resourceGroup().location
param tags object

resource publicip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'nat-pip-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource natgw 'Microsoft.Network/natGateways@2022-09-01' = {
  name: 'nat-gw-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicip.id
      }
    ]
  }
}

// spoke virtual network where the isolated compute resources are deployed
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'vnet-spoke-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/19'
      ]
    }
    subnets: [
      {
        name: 'cp'
        properties: {
          addressPrefix: '10.1.0.0/21'
        }
      }
      {
        name: 'apps'
        properties: {
          addressPrefix: '10.1.8.0/21'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'jump'
        properties: {
          addressPrefix: '10.1.16.0/24'
          delegations: [
            {
              name: 'Microsoft.ContainerInstance'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: 'linked'
        properties: {
          addressPrefix: '10.1.17.0/24'
        }
      }
    ]
  }
}

// hub virtual network where the shared resources are deployed
resource vnetHub 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'vnet-hub-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'shared'
        properties: {
          addressPrefix: '10.0.1.0/26'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          natGateway: {
            id: natgw.id
          }
        }
      }
      {
        name: 'jump'
        properties: {
          addressPrefix: '10.0.1.64/26'
          delegations: [
            {
              name: 'Microsoft.ContainerInstance'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: 'appgw'
        properties: {
          addressPrefix: '10.0.1.128/26'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// a virtual network simulating a corporate network
resource vnetCorporate 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'vnet-corp-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.42.0/24'
      ]
    }
    subnets: [
      {
        name: 'onprem'
        properties: {
          addressPrefix: '192.168.42.0/24'
        }
      }
    ]
  }
}

// hub virtual network and corporate virtual network are peered
resource peerHubCorporate 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'hub-to-corp'
  parent: vnetHub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetCorporate.id
    }
  }
}

resource peerCorporateHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'corp-to-hub'
  parent: vnetCorporate
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

output vnetSpokeId string = vnetSpoke.id
output vnetSpokeJumpSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetSpoke.name, 'jump')
output vnetSpokeLinkedSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetSpoke.name, 'linked')
output vnetHubId string = vnetHub.id
output vnetHubJumpSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHub.name, 'jump')
output vnetHubSharedSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHub.name, 'shared')
output vnetCorporateId string = vnetCorporate.id
output vnetOnPremSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetCorporate.name, 'onprem')
