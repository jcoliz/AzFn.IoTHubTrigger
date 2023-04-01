@description('Descriptor for this resource')
param prefix string = 'ehub'

@description('Name of sending key')
param keyname string = 'SendKey'

@description('Unique suffix for all resources in this deployment')
param suffix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SKU name.')
param sku string = 'Basic'

@description('Number of provisioned units.')
param capacity int = 1

resource ehub 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
  name: '${prefix}-${suffix}'
  location: location
  sku: {
    name: sku
    tier: sku
    capacity: capacity
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: true
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: false
  }
}

resource key 'Microsoft.EventHub/namespaces/authorizationrules@2022-10-01-preview' = {
  parent: ehub
  name: keyname
  properties: {
    rights: [
      'Send'
    ]
  }
}

output keyid string = key.id
output okey object = key
