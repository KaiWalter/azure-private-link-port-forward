param name string
param location string = resourceGroup().location
param tags object
param subnetId string
param image string = 'bash'

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          command: [
            'tail'
            '-f'
            '/dev/null'
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    subnetIds: [
      {
        id: subnetId
      }
    ]
  }
}

output containerGroupName string = containerGroup.name
