targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('SSH public key to be set on the VMs')
param sshPublicKey string = ''

param cloudInitOnPrem string
param cloudInitForwarder string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
}

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {
  'azd-env-name': name
}

module resources './resources.bicep' = {
  name: 'resources-${resourceToken}'
  scope: resourceGroup
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    sshPublicKey: sshPublicKey
    cloudInitOnPrem: cloudInitOnPrem
    cloudInitForwarder: cloudInitForwarder
  }
}

output RESOURCE_GROUP_NAME string = resourceGroup.name
output RESOURCE_TOKEN string = resourceToken
output SPOKE_JUMP_NAME string = resources.outputs.containerGroupSpokeJumpName
output HUB_JUMP_NAME string = resources.outputs.containerGroupHubJumpName
