param resourceToken string
param location string = resourceGroup().location
param tags object

param port int = 8000
param sharedSubnetId string
param vnetHubId string
param logAnalyticsWorkspaceId string

@allowed([
  'Basic'
  'Standard'
])
param ilbSku string = 'Standard'

@description('Availability zone numbers e.g. 1,2,3.')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

var ilbName = 'ilb-${resourceToken}'

resource ilb 'Microsoft.Network/loadBalancers@2022-05-01' = {
  name: ilbName
  location: location
  tags: tags
  sku: {
    name: ilbSku
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: sharedSubnetId
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'direct'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'server65'
              properties: {
                ipAddress: '192.168.42.65'
                virtualNetwork: {
                  id: vnetHubId
                }
              }
            }
            {
              name: 'server66'
              properties: {
                ipAddress: '192.168.42.66'
                virtualNetwork: {
                  id: vnetHubId
                }
              }
            }
          ]
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'direct'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', ilbName, 'loadBalancerFrontEnd')
          }
          frontendPort: port
          backendPort: port
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', ilbName, 'direct')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', ilbName, 'server-port')
          }
        }
      }
    ]
    probes: [
      {
        name: 'server-port'
        properties: {
          protocol: 'Tcp'
          port: port
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag'
  scope: ilb
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 2
          enabled: true
        }
      }
    ]
  }
}
