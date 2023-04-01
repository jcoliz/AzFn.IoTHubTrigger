//
// Deploys Function App with associated storage account
//

@description('Unique suffix for all resources in this deployment')
param suffix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    suffix: suffix
    location: location
  }
}

module fn 'fn.bicep' = {
  name: 'iotHub'
  params: {
    storage: storage.outputs.result
    suffix: suffix
    location: location
  }  
}
