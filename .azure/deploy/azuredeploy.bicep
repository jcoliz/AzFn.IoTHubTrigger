@description('Name of the IoT Hub.')
@minLength(3)
param iotHubName string = 'iothub-${uniqueString(resourceGroup().id)}'

@description('Short name of the consumer group.')
param cgName string = 'cg-azfn'

@description('Name of the provisioning service.')
param dpsName string = 'dps-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('IotHub SKU.')
param skuName string = 'S1'

@description('Number of provisioned IoT Hub units. Restricted to 1 unit for the F1 SKU. Can be set up to maximum number allowed for subscription.')
@minValue(1)
@maxValue(1)
param capacityUnits int = 1

@description('Device Provisioning Service SKU.')
param skuNameDps string = 'S1'

@description('The name of the function app that you wish to create.')
param fnName string = uniqueString(resourceGroup().id)

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
])
param fnRuntime string = 'dotnet'

@description('Name of the output Event Hubs Namespace.')
@minLength(3)
param ehoutNamespaceName string = 'ehout-${uniqueString(resourceGroup().id)}'

@description('Name of the output Event Hub.')
@minLength(3)
param ehoutHubName string = 'ehout'

var iotHubKey = 'iothubowner'
var consumerGroupFullName = '${iotHubName}/events/${cgName}'
var functionAppName = 'fn-${fnName}'
var hostingPlanName = 'farm-${fnName}'
var applicationInsightsName = 'insight-${fnName}'
var storageAccountName = 'stor000${fnName}'
var ehoutKeyName = 'SinkKey'

resource iotHub 'Microsoft.Devices/IotHubs@2021-03-31' = {
  name: iotHubName
  location: location
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 2
      }
    }
    routing: {
      endpoints: {
        serviceBusQueues: []
        serviceBusTopics: []
        eventHubs: []
        storageContainers: []
        cosmosDBSqlCollections: []
      }
      routes: []
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    cloudToDevice: {
      defaultTtlAsIso8601: 'PT1H'
      maxDeliveryCount: 10
      feedback: {
        ttlAsIso8601: 'PT1H'
        lockDurationAsIso8601: 'PT60S'
        maxDeliveryCount: 10
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        ttlAsIso8601: 'PT1H'
        lockDurationAsIso8601: 'PT1M'
        maxDeliveryCount: 10
      }
    }
  }
  sku: {
    name: skuName
    capacity: capacityUnits
  }
}

resource consumerGroupFull 'Microsoft.Devices/iotHubs/eventhubEndpoints/ConsumerGroups@2021-03-31' = {
  name: consumerGroupFullName
  properties: {
    name: cgName
  }
  dependsOn: [
    iotHub
  ]
}

resource dps 'Microsoft.Devices/provisioningServices@2022-02-05' = {
  name: dpsName
  location: location
  sku: {
    name: skuNameDps
    capacity: capacityUnits
  }
  properties: {
    iotHubs: [
      {
        connectionString: 'HostName=${reference(iotHub.id, '2021-07-02').hostName};SharedAccessKeyName=${iotHubKey};SharedAccessKey=${listkeys(iotHub.id, '2021-07-02').value[0].primaryKey}'
        location: location
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2021-08-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2021-08-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: fnRuntime
        }
        {
          name: 'EVENTCSTR'
          value: 'Endpoint=${reference(iotHub.id, '2021-07-02').eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHub.id, '2021-07-02').value[0].primaryKey};EntityPath=${reference(iotHub.id, '2021-07-02').eventHubEndpoints.events.path}'
        }
        {
          name: 'EVENTPATH'
          value: reference(iotHub.id, '2021-07-02').eventHubEndpoints.events.path
        }
        {
          name: 'HUBCG'
          value: cgName
        }
        {
          name: 'EHOUTCSTR'
          value: listKeys(ehoutNamespaceName_ehoutKey.id, '2022-10-01-preview').primaryConnectionString
        }
        {
          name: 'EHOUTPATH'
          value: ehoutHubName
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource ehoutNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
  name: ehoutNamespaceName
  location: 'West US 2'
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
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

resource ehoutNamespaceName_ehoutKey 'Microsoft.EventHub/namespaces/authorizationrules@2022-10-01-preview' = {
  parent: ehoutNamespace
  name: '${ehoutKeyName}'
  location: 'westus2'
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource ehoutNamespaceName_ehoutHub 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' = {
  parent: ehoutNamespace
  name: '${ehoutHubName}'
  location: 'westus2'
  properties: {
    retentionDescription: {
      cleanupPolicy: 'Delete'
      retentionTimeInHours: 1
    }
    messageRetentionInDays: 1
    partitionCount: 2
    status: 'Active'
  }
}

output _env_HUBNAME string = iotHubName
output _env_HUBCSTR string = 'HostName=${reference(iotHub.id, '2021-07-02').hostName};SharedAccessKeyName=${iotHubKey};SharedAccessKey=${listkeys(iotHub.id, '2021-07-02').value[0].primaryKey}'
output _env_HUBCG string = cgName
output _env_EVENTCSTR string = 'Endpoint=${reference(iotHub.id, '2021-07-02').eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHub.id, '2021-07-02').value[0].primaryKey};EntityPath=${reference(iotHub.id, '2021-07-02').eventHubEndpoints.events.path}'
output _env_EVENTPATH string = reference(iotHub.id, '2021-07-02').eventHubEndpoints.events.path
output _env_DPSNAME string = dpsName
output _env_IDSCOPE string = dps.properties.idScope
output _env_FNNAME string = functionAppName
output _env_STORNAME string = storageAccountName
output _env_STORCSTR string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2021-08-01').keys[0].value}'
output _env_EHOUTPATH string = ehoutHubName
output _env_EHOUTCSTR string = listKeys(ehoutNamespaceName_ehoutKey.id, '2022-10-01-preview').primaryConnectionString