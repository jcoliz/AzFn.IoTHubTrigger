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

module iotHub 'iothub.bicep' = {
  name: 'iotHub'
  params: {
    suffix: suffix
    location: location
  }  
}

module cgInput 'ehubcg.bicep' = {
  name: cgName
  params: {
    name: cgName
    ehub: iotHub.outputs.result.name
  }
}

module dps 'dps.bicep' = {
  name: 'dps'
  params: {
    suffix: suffix
    location: location
    iotHub: iotHub.outputs.result
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    suffix: suffix
    location: location
  }
}

module ehubOutput 'ehub.bicep' = {
  name: 'ehubOutput'
  params: {
    suffix: suffix
    location: location
  }
}

module fnthis 'fn-this.bicep' = {
  name: 'fnthis'
  params: {
    storage: storage.outputs.result
    iotHub: iotHub.outputs.result
    cgInput: cgName
    ehubOutput: ehubOutput.outputs.ehub
    ehubKey: ehubOutput.outputs.key    
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
output _env_EHOUTPATH string = ehubOutput.outputs.namespace.name
