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

output HUBNAME string = iotHub.outputs.result.name
output HUBCG string = cgName
output DPSNAME string = dps.outputs.result.name
output IDSCOPE string = dps.outputs.result.scope
output FNNAME string = fnthis.outputs.result.name
output STORNAME string = storage.outputs.result.name
output EHOUTPATH string = ehubOutput.outputs.result.hub
output EVENTPATH string = iotHub.outputs.result.eventpath
output EVENTENDP string = iotHub.outputs.result.endpoint

// WARNING: This is a secret. Remove before using this in production!
output EHOUTCSTR string = fnthis.outputs.ehoutcstr
