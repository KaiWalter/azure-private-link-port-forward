param pepNicId string

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' existing = {
  name: substring(pepNicId, lastIndexOf(pepNicId, '/') + 1)
}

output nicPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
