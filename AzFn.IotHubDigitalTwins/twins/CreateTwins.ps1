if (-not (Test-Path env:TWINSNAME)) 
{ 
    Write-Output "Please set env:TWINSNAME to name of your Digital Twin instance"
    Exit 
}

$DeviceModel = "dtmi:azdevice:i2ctemphumiditymonitor;1"
az dt model create -n $env:TWINSNAME --models .\devicemodels.json
az dt model create -n $env:TWINSNAME --models .\factorymodel.json
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device1' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device2' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device3' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device4' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device5' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device6' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi "dtmi:com:aztwins:example_factory;1" --twin-id 'factory'
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device1 --relationship rel_has_devices --twin-id factory --target adt-device1
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device2 --relationship rel_has_devices --twin-id factory --target adt-device2
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device3 --relationship rel_has_devices --twin-id factory --target adt-device3
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device4 --relationship rel_has_devices --twin-id factory --target adt-device4
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device5 --relationship rel_has_devices --twin-id factory --target adt-device5
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device6 --relationship rel_has_devices --twin-id factory --target adt-device6
