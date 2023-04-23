# Set $env:TWINSNAME to name of twins instance before calling

$DeviceModel = "dtmi:azdevice:i2ctemphumiditymonitor;1"
az dt model create -n $env:TWINSNAME --models .\devicemodels.json
az dt model create -n $env:TWINSNAME --models .\factoryfloormodel.json
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device1' --properties $Properties
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device2' --properties $Properties
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device3' --properties $Properties
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device4' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi "dtmi:com:aztwins:example_factory;1" --twin-id 'factory'
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device1 --relationship rel_has_sensors --twin-id factory --target adt-device1
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device2 --relationship rel_has_sensors --twin-id factory --target adt-device2
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device3 --relationship rel_has_sensors --twin-id factory --target adt-device3
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device4 --relationship rel_has_sensors --twin-id factory --target adt-device4
