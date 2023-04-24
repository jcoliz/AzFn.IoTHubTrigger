@description('Unique suffix for all resources in this deployment')
param suffix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Optional principal that will be given data owner permission for the Digital Twins and Blob Storage resources')
param principalId string = ''

@description('Optional type of the given principal id, if supplied')
param principalType string = 'User'

@description('Short name of the input consumer group.')
param cgName string = 'cg-twin'

module twins '../../.azure/deploy/AzDeploy.Bicep/DigitalTwins/digitaltwins.bicep' = {
  name: 'twins'
  params: {
    suffix: suffix
    location: location
  }
}

module dataowner '../../.azure/deploy/AzDeploy.Bicep/DigitalTwins/dataownerrole.bicep' = if (!empty(principalId)) {
  name: 'dataowner'
  params: {
    digitalTwinsName: twins.outputs.result.name
    principalId: principalId
    principalType: principalType
  }
}

module storage '../../.azure/deploy/AzDeploy.Bicep/Storage/storage.bicep' = {
  name: 'storage'
  params: {
    suffix: suffix
    location: location
  }
}

module blobs '../../.azure/deploy/AzDeploy.Bicep/DigitalTwins/storageblobservicecors.bicep' = {
  name: 'blobs'
  params: {
    account: storage.outputs.result.name
  }
}

var containername = 'scenes'
module container '../../.azure/deploy/AzDeploy.Bicep/Storage/storcontainer.bicep' = {
  name: containername
  params: {
    name: containername
    account: storage.outputs.result.name
  }
}

module blobcontributor '../../.azure/deploy/AzDeploy.Bicep/Storage/blobdatacontribrole.bicep' = if (!empty(principalId)) {
  name: 'blobcontributor'
  params: {
    containerFullName: container.outputs.result.name
    principalId: principalId
    principalType: principalType
  }
}

module iotHub '../../.azure/deploy/AzDeploy.Bicep/Devices/iothub.bicep' = {
  name: 'iotHub'
  params: {
    suffix: suffix
    location: location
    routes: [
      {
        name: 'TwinChangeEvents'
        source: 'TwinChangeEvents'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    ]
  }  
}

module cgInput '../../.azure/deploy/AzDeploy.Bicep/Devices/iothubcg.bicep' = {
  name: cgName
  params: {
    name: cgName
    ehub: iotHub.outputs.result.name
  }
}

module dps '../../.azure/deploy/AzDeploy.Bicep/Devices/dps.bicep' = {
  name: 'dps'
  params: {
    suffix: suffix
    location: location
    iotHubName: iotHub.outputs.result.name
  }
}

module fnthis 'fn-this.bicep' = {
  name: 'fnthis'
  params: {
    storageName: storage.outputs.result.name
    iotHubName: iotHub.outputs.result.name
    twinsName: twins.outputs.result.name
    cgInput: cgName
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
output TWINSNAME string = twins.outputs.result.name
output TWINSURL string = 'https://${twins.outputs.result.host}'
output EVENTPATH string = iotHub.outputs.result.eventpath

// WARNING: This value contains a secret. Remove this before using in any production deployment
output EVENTCSTR string = fnthis.outputs.eventcstr
