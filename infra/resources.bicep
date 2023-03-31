param location string
param resourceToken string
param tags object
param sshPublicKey string = ''
param cloudInitOnPrem string = ''

module logging 'modules/logging.bicep' = {
  name: 'logging'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

module vmOnPrem 'modules/onprem-server/vm.bicep' = [for i in range(65,2): {
  name: 'vmOnPrem${i}'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    vmNumber:i
    sshPublicKey: sshPublicKey
    cloudInit: cloudInitOnPrem
    subnetId: network.outputs.vnetOnPremSubnetId
  }
}]

module spokeJump 'modules/containergroup.bicep' = {
  name: 'spokeJump'
  params: {
    location: location
    tags: tags
    name: 'spoke-jump-${resourceToken}'
    subnetId: network.outputs.vnetSpokeJumpSubnetId
  }
}

module hubJump 'modules/containergroup.bicep' = {
  name: 'hubJump'
  params: {
    location: location
    tags: tags
    name: 'hub-jump-${resourceToken}'
    subnetId: network.outputs.vnetHubJumpSubnetId
  }
}

// module forwarder 'modules/forwarder/forwarder.bicep' = {
//   name: 'forwarder'
//   params: {
//     location: location
//     resourceToken: resourceToken
//     tags: tags
//     sharedSubnetId: network.outputs.vnetHubSharedSubnetId
//     resourceGroupNameCompute: ''
//     sshPublicKey: sshPublicKey
//   }
// }

output containerGroupSpokeJumpName string = spokeJump.outputs.containerGroupName
output containerGroupHubJumpName string = hubJump.outputs.containerGroupName
