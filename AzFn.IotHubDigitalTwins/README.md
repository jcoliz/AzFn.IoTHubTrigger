# Map IoT device data to digital twin models and relationships

![Architecture](../docs/images/Architecture-twins.png)

This is a complete end-to-end example of how to set up an Azure Digital Twins
instance, then map telemetry and property data coming from an IoT device
via IoT Hub.

## What's Here?

* **Complete ARM Template**: Deploys an IoT Hub, DPS, Storage, Function App, and Digital Twins instance
* **Azure Function Code Example**: Maps the device telemetry and properties coming from IoT Hub into the Digital Twins instance.
* **Azure Dev Ops Pipeline Definitions**: Ready-to-use pipelines to deploy the filter from your ADO project pipeline, into the function app deployed by the ARM Template.

## Steps to Set Up (Overview)

1. Find your User Principal ID
2. Deploy Azure Resources
3. Create models, twins, and relationships
4. Set up 3D Scenes Studio (optional, but very cool)
5. Send data from device client
6. Run the Azure Function locally
7. View twins in Digital Twins Explorer
8. View twins in 3D Scenes Studio (optional)
9. Set up Continuous Deployment in Azure Pipelines  

## Find your User Principal ID

[Setting up 3D Scenes Studio](https://learn.microsoft.com/en-us/azure/digital-twins/how-to-use-3d-scenes-studio) requires
giving your Azure user access to the digitial twins instance and the blob storage container. The deployment templates
will set up the access. You just need to find your principal ID, and provide it to the deployment. 
The [Permission Requirements](https://learn.microsoft.com/en-us/azure/digital-twins/how-to-set-up-instance-cli#prerequisites-permission-requirements)
article is a good guide to finding this principal ID. Once you have, you'll supply it to the deployment steps below.

> TODO: Separate principal ID deployment, such that the whole deployment could be done WITHOUT a principal ID, and then the principal ID could later be added when we want to work with 3D Scenes Studio. Then we can move the whole principal ID stuff to that article.

## Deploy Azure Resources

The included [ARM Template](./deploy/azuredeploy.bicep) deploys all of the resources described in the architecture diagram above.
It also wires up the connections between services so everything is ready to go. Be sure to clone this repo with submodules, as the 
deployment template uses modules from the [AzDeploy.Bicep](https://github.com/jcoliz/AzDeploy.Bicep) project.

Here's what you do...

1. Open Powershell
3. Change to the `deploy` directory
4. Create a deployment parameters file containing your user principal ID, perhaps using the `azuredeploy.parameters.template.json` as an example.
5. Set `$env:RESOURCEGROUP` to the name of a resource group you'd like to create and deploy into.
6. Run the `BringUp.ps1` script. This creates the resource group, and starts a deployment.
7. Save the values of all `outputs` shown into evnvironment variables, perhaps in an `.env.ps1` file. For easy reference, you can start with the `.env.template.ps1` as an example for what to save.

## Create Models, Twins, and Relationships

This example sets up 6 'device' digital twins, each reporting Temperature and Humidity. These are all contained within
a 'factory' digial twin, which has a relationship containing each device.

1. Change to the `twins` directory
2. Ensure `$env:TWINSNAME` is set to the name of your Digital Twins instance
3. Run the `CreateTwins.ps1` script, which will set up models, twins, and relationships

Here's a snippet

```pwsh
$DeviceModel = "dtmi:azdevice:i2ctemphumiditymonitor;1"
az dt model create -n $env:TWINSNAME --models .\devicemodels.json
az dt model create -n $env:TWINSNAME --models .\factoryfloor.json
az dt twin create -n $env:TWINSNAME --dtmi $DeviceModel --twin-id 'adt-device1' --properties '@initialstate.json'
az dt twin create -n $env:TWINSNAME --dtmi "dtmi:com:aztwins:example_factory;1" --twin-id 'factory'
az dt twin relationship create -n $env:TWINSNAME --relationship-id has_device1 --relationship rel_has_devices --twin-id factory --target adt-device1
```

Once this is done, load up the [Azure Digital Twins Explorer](https://explorer.digitaltwins.azure.net/). Once the application is loaded, click "Run Query", which will load up a model of the twins to date.

![Twins Graph](../docs/images/twins-explorer.png)

## Set up 3D Scenes Studio

> TODO: Move all the 3D Scenes Studio stuff out to its own article

### Steps overview

At a high level, here's what we'll need to do to set up 3D Scenes Studio for our example

1. Import a 3D model
2. Associate a unique 3D model mesh to each individual twins
3. Choose what to display for each twin
4. Apply the Behavior to all elements

### Add the example model

The key feature of 3D Scenes Studio is to visualize your Digital Twins environment in 3D form. You can import a model in [glTF](https://github.com/KhronosGroup/glTF). Blender works great to create and export these models. For our purpose, we can use the Robot Arms file provided in the documentation. Download it here: [Robot Arms glTF](https://cardboardresources.blob.core.windows.net/public/RobotArms.glb).

1. Download the sample model locally
2. From the main page of [3D Scenes Studio](https://explorer.digitaltwins.azure.net/3DScenes/), pick `Add new`.
3. Give the scene a name, e.g. "Robot Arms". Pick the sample model from your local machine, and pick `Create`.

### Create Elements for each robot arm

The first step in working with a model here is to associate a unique mesh to each individual twin in your system.

There are six robot arms in the model, so this example created six digital twins. For each one, you'll click on 
a mesh in one of the robot arms, pick `Create new element` from the presented menu, choose of of the six twins from
the list, and click `Create Element`. Now there is one visual display Element for each of the device twins in our
system. 

### Create a Behavior to display twin information 

The Behavior for each twin describes what we want to show. We will create one behavior, applied to each of our elements.

Here's what we want:

1. A dashboard for each element showing the important information
2. The current temperature displayed as a simple number on the dashboard 
3. The current humidity shown as a gauge with green/yellow/red gradations
4. A visual rule to set the overall element color based on the current humidity

![Create a Behavior](../docs/images/twin-3d-behavior.png)

First, we'll create the dashboard

1. Click the `Behaviors` tab atop the editing pane on the left
2. Click `New behavior`
3. Give it a name, e.g. "Dashboard"
4. Select all the elements from the `Elements` list. This will apply the behavior to all elements.

Now, add the temperature 

1. Click `Widgets`, then `Add Widgets`
2. Pick a `Value` widget. 
3. Assign to it the PrimaryTwin.Sensor_1.Temperature property. 
4. Name it, and click Create Widget.

![Temp Widget](../docs/images/twin-3d-temp-widget.png)

Next, the humidity

1. Again, click `Widgets`, then `Add Widgets`
2. This time, pick a `Gauge` widget. 
3. Choose the Sensor_1.Humidity property. 
4. Add three ranges. Set the 0-0.5 range to Green color, 0.5-0.75 to Yellow, and 0.75 to infinity as Red. 
5. Name it, and click Create Widget.

![Humidity Widget](../docs/images/twin-3d-humidity-widget.png)

Finally, the visual rules

1. Click `Visual rules`, then `Add rule`
2. Name it, e.g. "Status Color"
3. Choose the Sensor_1.Humidity property.
4. Add three conditions
5. Match the values and color to the humidity gauge: 0-0.5 range to Green, 0.5-0.75 to Yellow, and 0.75 to infinity as Red.

![Status Color](../docs/images/twin-3d-statuscolor.png)

## Send data from the device client

This example is set up to use the [I2CTemperatureHumidityMonitor](https://github.com/jcoliz/AzDevice.IoTHubWorker/tree/main/examples/I2cTempHumidityMonitor) example client from the [AzDevice.IoTHubWorker](https://github.com/jcoliz/AzDevice.IoTHubWorker) project.
Note that this example will send simulated data by default, so there's no need to build out the whole Raspberry Pi
physical setup. However, if you DO build that out, it will work great with this example as well.

1. Clone the [AzDevice.IoTHubWorker](https://github.com/jcoliz/AzDevice.IoTHubWorker) project.
2. Ensure you have environment variables set correcly from the `Deploy Azure Resources` step above.
3. Follow the instructions there to [Create an Enrollment Group](https://github.com/jcoliz/AzDevice.IoTHubWorker/blob/main/docs/GettingStarted.md#create-an-enrollment-group).
4. Then, [Enroll a Device](https://github.com/jcoliz/AzDevice.IoTHubWorker/blob/main/docs/GettingStarted.md#enroll-a-device) named `adt-device1`. It's important that the device name match one of the digital twins created in the `Create Twins` step above.
5. Finally, [Build & Run the Device Software](https://github.com/jcoliz/AzDevice.IoTHubWorker/blob/main/docs/GettingStarted.md#buildrun-device-software), in this case, the `I2CTemperatureHumidityMonitor` example.

This will start sending data up to your IoT Hub, matching the `dtmi:azdevice:i2ctemphumiditymonitor;1` DTMI.

## Run the Azure Function locally

Azure Digital Twins rely on separate compute resources to injest data into them. Ergo, for this example, we will
use an Azure Function to injest this data. The Azure Function will listen to the Event Hub exposed by IoT Hub,
then translate those telemetry and property update messages into a form that Digital Twins can handle. 

The Azure Functions extension for Visual Studio is a great way to test out our function before deploying it.
As long as the environment is set up correctly, the locally-running function can contact both the IoT Hub
and Digital Twins instances we deployed earlier.

1. Install the [Visual Studio Extension for Azure Functions](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)
2. Open the `AzFn.IoTHubDigitalTwins` folder from this project in Visual Studio Code.
5. Create a `local.settings.json` file, based on the `local.settings.template.json` file.
3. Fill in the details for your deployment, using values you previously saved during the "Deploy Azure Resources" step, above. 
4. Launch the function with `F5`

Keep an eye on the logs coming up in the terminal window. You'll see the output from the function when it's called:

```
[2023-04-24T17:18:37.059Z] OK. EventHubToDigitalTwin function received message #3, enqueued at 4/24/2023 5:13:56 PM +00:00
[2023-04-24T17:18:37.065Z] Temperature: 1713.57
[2023-04-24T17:18:37.066Z] Humidity: 0.7139875
[2023-04-24T17:18:37.067Z] SP.user-id: System.ReadOnlyMemory<Byte>[0]
[2023-04-24T17:18:37.068Z] SP.content-type: application/json
[2023-04-24T17:18:37.069Z] SP.content-encoding: utf-8
[2023-04-24T17:18:37.069Z] SP.iothub-connection-device-id: adt-device1
[2023-04-24T17:18:37.070Z] SP.iothub-connection-auth-method: {"scope":"device","type":"sas","issuer":"iothub","acceptingIpFilterRule":null}
[2023-04-24T17:18:37.071Z] SP.iothub-connection-auth-generation-id: 1234567890
[2023-04-24T17:18:37.072Z] SP.iothub-enqueuedtime: 4/24/2023 5:13:56 PM
[2023-04-24T17:18:37.072Z] SP.iothub-message-source: Telemetry
[2023-04-24T17:18:37.073Z] SP.dt-subject: Sensor_1
[2023-04-24T17:18:37.074Z] SP.dt-dataschema: dtmi:azdevice:i2ctemphumiditymonitor;1
[2023-04-24T17:18:37.075Z] SP.x-opt-sequence-number: 3
[2023-04-24T17:18:37.076Z] SP.x-opt-offset: 3344
[2023-04-24T17:18:37.076Z] SP.x-opt-enqueued-time: 4/24/2023 5:13:56 PM +00:00
[2023-04-24T17:19:06.005Z] Sending to Digital Twin for Device:adt-device1 Patch:[{"op":"replace","path":"/Sensor_1/CurrentTemperature","value":1713.57},{"op":"replace","path":"/Sensor_1/CurrentHumidity","value":0.7139875}]
[2023-04-24T17:19:20.081Z] OK. Sent update to digital twin
```

This function does three things:
1. Prints the complete contents of the message to help us understand what's happening
2. Translates telemetry messages to corresponding twin properties.
3. Translates device twin updates containing reported properties into corresponding digital twin properties

### Print message contents

```c#
                    var body = eventData.EventBody.ToObjectFromJson<Dictionary<string, object>>();
                    foreach (var kvp in body)
                        log.LogInformation($"{kvp.Key}: {kvp.Value}");

                    foreach (var kvp in eventData.Properties)
                        log.LogInformation($"P.{kvp.Key}: {kvp.Value}");

                    foreach (var kvp in eventData.SystemProperties)
                        log.LogInformation($"SP.{kvp.Key}: {kvp.Value}");
```

### Translate telemetry messages

Digital twins only store properties, not telemetry values. Thus, my standard practice is to translate
telemetry values into a corresponding `Current{Value}` property. Of course, this requires the model
to have these properties.

```c#
    var source = eventData.SystemProperties["iothub-message-source"] as string;
    if (source == "Telemetry")
    {
        updateTwinData = new JsonPatchDocument();
        string objectpath = "/";
        if (eventData.SystemProperties.ContainsKey("dt-subject"))
            objectpath += (eventData.SystemProperties["dt-subject"] as string) + "/";

        foreach (var kvp in body)
        {
            JsonElement? el = kvp.Value as JsonElement?;
            if (el.HasValue && el.Value.ValueKind == JsonValueKind.Number)
            {
                double value = el.Value.GetDouble();
                updateTwinData.AppendReplace($"{objectpath}Current{kvp.Key}", value);
            }
        }
    }
```

### Translate reported properties directly

The device code reports the current state of all properties regularly. When IoT Hub receives this update,
it generates a device twin change event. The IoT Hub deployment in this example included a route to forward
such events to the `events` endpoint. That's what the Azure Function is listening to, so we'll get those
events in our function as well.

```yaml
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
```

Because the device is using the same model as the digital twin, we can simply pass along all the
valid properties directly to the Digital Twin without modification.

```c#
    else if (source == "twinChangeEvents")
    {
        updateTwinData = new JsonPatchDocument();
        JsonElement? properties = body["properties"] as JsonElement?;
        JsonElement reported = properties.Value.GetProperty("reported");
        updateTwinData.Add("/",reported);
    }
```

## View twins in Digital Twins Explorer

Once there is data flowing through, you can return to the Digital Twins Explorer to view the properties
of your device. Click "Run Query" to refresh the twins, then click on "adt-device1" to see a panel of
info for this device.

![Twin Properties](../docs/images/twin-properties.png)

## View twins in 3D Scenes Studio

Now that data is flowing, you can use 3D Scenes Studio to get an overall status view of your whole
system. In the picture below, we can quickly see that one machine is in a critical state, while the
other five are all OK. Clicking on the one machine brings up my dashboard, where I can see that
the humidity in this case is too high. The "All Properties" tab is available as well, if I want
to dig into the details

![Twin Properties](../docs/images/twin-3d-overview.png)
