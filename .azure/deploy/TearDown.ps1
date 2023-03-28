if (-not (Test-Path env:RESOURCEGROUP)) 
{ 
    Write-Output "Please set env:RESOURCEGROUP to name of resource group to create and deploy into"
    Exit 
}

az group delete --name $env:RESOURCEGROUP --yes
