param location string = resourceGroup().location
param vnetSpokeId string
param loadBalancerFrontendIpConfigurationId string
param sharedSubnetId string
param linkedSubnetId string

// link load balancer with private link service within shared subnet
resource pl 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: 'pl-linked-forwarder'
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: loadBalancerFrontendIpConfigurationId
      }
    ]
    ipConfigurations: [
      {
        name: 'backend-forwarder'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: sharedSubnetId
          }
          primary: false
        }
      }
    ]
  }
}

resource pep 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'pe-linked-forwarder'
  location: location
  properties: {
    subnet: {
      id: linkedSubnetId
    }
    privateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: pl.id
        }
        name: 'pl-linked-forwarder'
      }
    ]
  }
}

resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'internal.net'
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dns
  name: '${dns.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetSpokeId
    }
  }
}

module nic2pip 'forwarder-private-nic-to-ip.bicep' = {
  name: 'nic2pip'
  params: {
    pepNicId: pep.properties.networkInterfaces[0].id
  }
}

resource privateDnsZoneEntry 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'onprem-server'
  parent: dns
  properties: {
    aRecords: [
      {
        ipv4Address: nic2pip.outputs.nicPrivateIp
      }
    ]
    ttl: 3600
  }
}
