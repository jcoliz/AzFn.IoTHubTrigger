if (-not (Test-Path env:RESOURCEGROUP)) 
{ 
    Write-Output "Please set env:RESOURCEGROUP to name of resource group to create and deploy into"
    Exit 
}

az group create --name $env:RESOURCEGROUP --location "West US 2"
az deployment group create --name "AzFn-$(Get-Random)" --resource-group $env:RESOURCEGROUP --template-file "azuredeploy.bicep"
