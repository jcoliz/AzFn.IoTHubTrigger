//
// Deploys the complete solution
//
// See README.md for details
//

@description('Unique suffix for all resources in this deployment')
param suffix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Short name of the input consumer group.')
param cgName string = 'cg-azfn'

module iotHub './AzDeploy.Bicep/Devices/iothub.bicep' = {
  name: 'iotHub'
  params: {
    suffix: suffix
    location: location
  }  
}

module cgInput './AzDeploy.Bicep/Devices/iothubcg.bicep' = {
  name: cgName
  params: {
    name: cgName
    ehub: iotHub.outputs.result.name
  }
}

module dps './AzDeploy.Bicep/Devices/dps.bicep' = {
  name: 'dps'
  params: {
    suffix: suffix
    location: location
    iotHubName: iotHub.outputs.result.name
  }
}

module storage './AzDeploy.Bicep/Storage/storage.bicep' = {
  name: 'storage'
  params: {
    suffix: suffix
    location: location
  }
}

module ehubOutput './AzDeploy.Bicep/EventHub/ehub.bicep' = {
  name: 'ehubOutput'
  params: {
    suffix: suffix
    location: location
  }
}

module fnthis 'fn-this.bicep' = {
  name: 'fnthis'
  params: {
    storageName: storage.outputs.result.name
    iotHubName: iotHub.outputs.result.name
    cgInput: cgName
    ehubOutput: ehubOutput.outputs.result
    suffix: suffix
    location: location
  }
}

output _env_HUBNAME string = iotHub.outputs.result.name
output _env_HUBCG string = cgName
output _env_DPSNAME string = dps.outputs.result.name
output _env_IDSCOPE string = dps.outputs.result.scope
output _env_FNNAME string = fnthis.outputs.result.name
output _env_STORNAME string = storage.outputs.result.name
output _env_EHOUTPATH string = ehubOutput.outputs.result.hub
output _env_EVENTPATH string = iotHub.outputs.result.eventpath
output _evv_EVENTENDP string = iotHub.outputs.result.endpoint
