param location string = resourceGroup().location
param vnetComputeId string
param loadBalancerFrontendIpConfigurationId string
param subnetBackendId string
param subnetComputeName string = 'jump'
var subnetComputeId = '${vnetComputeId}/subnets/${subnetComputeName}'

// link load balancer with private link service within backend subnet
resource pl 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: 'pl-compute-smtp-forwarder'
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
            id: subnetBackendId
          }
          primary: false
        }
      }
    ]
  }
}

resource pep 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'pe-compute-smtp-forwarder'
  location: location
  properties: {
    subnet: {
      id: subnetComputeId
    }
    privateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: pl.id
        }
        name: 'pl-compute-smtp-forwarder'
      }
    ]
  }
}

resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'internal-smtp.net'
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dns
  name: '${dns.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetComputeId
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
  name: 'relay'
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
