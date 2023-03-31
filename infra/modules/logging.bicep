param location string
param resourceToken string
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'log-${resourceToken}'
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
      immediatePurgeDataOn30Days: true
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

output logAnalyticsWorkspace object = logAnalyticsWorkspace
