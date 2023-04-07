param location string = resourceGroup().location
param resourceToken string
param tags object

param capacity int = 3
param adminUsername string = 'azureuser'
param cloudInit string = ''
param sshPublicKey string
param port int = 8000

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

param vnetSpokeId string
param sharedSubnetId string
param linkedSubnetId string

var vmssName = 'vmss-fwd-${resourceToken}'
var computerNamePrefix = 'vm-fwd-${resourceToken}-'
var ilbName = 'ilb-fwd-${resourceToken}'

resource ilb 'Microsoft.Network/loadBalancers@2022-09-01' = {
  name: ilbName
  location: location
  tags: tags
  sku: {
    name: ilbSku
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
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
        name: 'portfwd'
        properties: {
          loadBalancerBackendAddresses: []
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'forwarded-port'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', ilbName, 'LoadBalancerFrontEnd')
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', ilbName, 'portfwd')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', ilbName, 'forwarded-port')
          }
        }
      }
    ]
    probes: [
      {
        name: 'forwarded-port'
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

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: vmssName
  location: location
  tags: tags
  dependsOn: [
    ilb
  ]
  sku: {
    name: 'Standard_B1s'
    tier: 'Standard'
    capacity: capacity
  }
  properties: {
    singlePlacementGroup: ilbSku == 'Basic'
    upgradePolicy: {
      mode: 'Automatic'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 20
        maxUnhealthyInstancePercent: 20
        maxUnhealthyUpgradedInstancePercent: 20
        pauseTimeBetweenBatches: 'PT0S'
      }
      automaticOSUpgradePolicy: {
        enableAutomaticOSUpgrade: true
        disableAutomaticRollback: false
      }
    }
    scaleInPolicy: {
      rules: [
        'Default'
      ]
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: computerNamePrefix
        adminUsername: adminUsername
        customData: cloudInit
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 32
        }
        imageReference: {
          publisher: 'MicrosoftCBLMariner'
          offer: 'cbl-mariner'
          sku: 'cbl-mariner-2-gen2'
          version: 'latest'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${computerNamePrefix}nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: '${computerNamePrefix}ip'
                  properties: {
                    primary: true
                    subnet: {
                      id: sharedSubnetId
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', ilbName, 'portfwd')
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'HealthExtension'
            properties: {
              autoUpgradeMinorVersion: false
              publisher: 'Microsoft.ManagedServices'
              type: 'ApplicationHealthLinux'
              typeHandlerVersion: '1.0'
              settings: {
                protocol: 'tcp'
                port: port
              }
            }
          }
        ]
      }
      priority: 'Regular'
    }
    overprovision: true
    doNotRunExtensionsOnOverprovisionedVMs: false
    platformFaultDomainCount: 1
    automaticRepairsPolicy: {
      enabled: true
      gracePeriod: 'PT30M'
    }
  }
  zones: availabilityZones
}

module plComputeForwarder 'forwarder-spoke-privatelink.bicep' = {
  name: 'plComputeForwarder'
  params: {
    location: location
    vnetSpokeId: vnetSpokeId
    sharedSubnetId: sharedSubnetId
    linkedSubnetId: linkedSubnetId
    loadBalancerFrontendIpConfigurationId: ilb.properties.frontendIPConfigurations[0].id
  }
}
