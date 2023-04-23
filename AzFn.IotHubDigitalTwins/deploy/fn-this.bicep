//
// Deploys an Azure Functions app
//    with configuration parameters specific to this solution
//

@description('Unique suffix for all resources in this deployment')
param suffix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of required storage resource')
param storageName string

@description('Name of required IoTHub resource')
param iotHubName string

@description('Name of required input Consumer Group resource')
param cgInput string

@description('Name of required Digital Twins instance resource')
param twinsName string

// Retrieve needed details out of IoTHub resource
resource iotHub 'Microsoft.Devices/IotHubs@2021-07-02' existing = {
  name: iotHubName
}
var iothubkey = iotHub.listkeys().value[0]
var eventcstr = 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=${iothubkey.keyName};SharedAccessKey=${iothubkey.primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'

// Retrieve needed details out of Digital Twins resource
resource digitalTwins 'Microsoft.DigitalTwins/digitalTwinsInstances@2023-01-31' existing = {
  name: twinsName
}
var adtUrl = 'https://${digitalTwins.properties.hostName}'

var configuration = [
  {
    name: 'EVENTCSTR'
    value: eventcstr
  }
  {
    name: 'EVENTPATH'
    value: iotHub.properties.eventHubEndpoints.events.path
  }
  {
    name: 'HUBCG'
    value: cgInput
  }
  {
    name: 'ADT_SERVICE_URL'
    value: adtUrl
  }
]

module fn '../../.azure/deploy/AzDeploy.Bicep/Web/fn.bicep' = {
  name: 'fn'
  params: {
    storageName: storageName
    suffix: suffix
    location: location
    configuration: configuration
  }
}

module dataowner '../../.azure/deploy/AzDeploy.Bicep/DigitalTwins/dataownerrole.bicep' = {
  name: 'dataowner'
  params: {
    digitalTwinsName: twinsName
    principalId: fn.outputs.result.principal
    principalType: 'ServicePrincipal'
  }
}

output result object = fn.outputs.result

// WARNING: This value contains a secret. Remove this before using in any production deployment
output eventcstr string = eventcstr
