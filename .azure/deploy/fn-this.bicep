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

@description('Name of required input Consumer Group resource ')
param cgInput string

@description('Details for required output EventHub resource(s) (namespace/key/hub names)')
param ehubOutput object

// Retrieve needed details out of IoTHub resource
resource iotHub 'Microsoft.Devices/IotHubs@2021-07-02' existing = {
  name: iotHubName
}
var iothubkey = iotHub.listkeys().value[0]

// Retrieve needed details out of EventHub resource
resource ehubKey 'Microsoft.EventHub/namespaces/authorizationrules@2022-10-01-preview' existing = {
  name: '${ehubOutput.namespace}/${ehubOutput.key}'
}
var EHOUTCSTR = ehubKey.listKeys().primaryConnectionString

var configuration = [
  {
    name: 'EVENTCSTR'
    value: 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=${iothubkey.keyName};SharedAccessKey=${iothubkey.primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'
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
    name: 'EHOUTCSTR'
    value: EHOUTCSTR
  }
  {
    name: 'EHOUTPATH'
    value: ehubOutput.hub
  }
]

module fn './AzDeploy.Bicep/Web/fn.bicep' = {
  name: 'fn'
  params: {
    storageName: storageName
    suffix: suffix
    location: location
    configuration: configuration
  }
}

output result object = fn.outputs.result
output ehoutcstr string = EHOUTCSTR
