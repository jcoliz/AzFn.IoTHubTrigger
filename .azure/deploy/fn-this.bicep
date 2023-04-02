//
// Deploys an Azure Functions app
//    with configuration parameters specific to this solution
//

@description('Unique suffix for all resources in this deployment')
param suffix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Details for required storage resource (name/id)')
param storage object

@description('Details for required IoTHub resource (name/id/host)')
param iotHub object

@description('Name of required input Consumer Group resource ')
param cgInput string

@description('Details for required output EventHub resource (name/id)')
param ehubOutput object

@description('Details for required output EventHub namespace key (name/id)')
param ehubKey object

var configuration = [
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
    value: cgInput
  }
  {
    name: 'EHOUTCSTR'
    value: listKeys(ehubKey.id, '2022-10-01-preview').primaryConnectionString
  }
  {
    name: 'EHOUTPATH'
    value: ehubOutput.name
  }
]

module fn 'fn.bicep' = {
  name: 'fn'
  params: {
    storage: storage
    suffix: suffix
    location: location
    configuration: configuration
  }
}

output result object = fn.outputs.result
