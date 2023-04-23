$ResourceGroup = "adt"
#az group create --name $ResourceGroup --location "West US 2"
az deployment group create --name "Adt-$(Get-Random)" --resource-group $ResourceGroup --template-file "azuredeploy.bicep" --parameters '@azuredeploy.parameters.json'
