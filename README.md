# Process and filter IoT data by using Azure Functions

This is a complete end-to-end example of how to use Azure Functions to receive data
from an Azure IoT Hub, filter them, and output the results to a separate Event Hub.

## What's Here?

* **Complete ARM Template**: Deploys an IoT Hub, DPS, Storage, Function App, plus a separate Event Hub for output
* **Code Examples**: Two code examples, which can be run locally using VS Code, or deployed to an Azure Function App. `IoTHubTrigger` shows how to use the trigger only, and `IoTHubOutput` adds in output bindings and some filtering logic.
* **Azure Dev Ops Pipeline Definitions**: Ready-to-use pipelines to deploy the filter from your ADO project pipeline, into the function app deployed by the ARM Template.

## Deploy Resources

1. Using Powershell...
2. In .azure/deploy directory
3. Create $env:RESOURCEGROUP
4. Run `BringUp.ps1`
5. Review the `outputs` shown. Record all of these!

## Start sending data to your IoTHub

If you already know how to do this using your own tooling, great! Go ahead and start regularly sending
data up to the IoT Hub deployed above.

The deployment is also ready to use with the `Temperature Controller` example from the `AzDevice.IoTHubWorker`
project. You could follow the Getting Started guide there to generate a `config.toml` file for
connecting to this IoT Hub, then run the `Temperature Controller` example to generate data.

## Run IoTHubTrigger example in VS Code

1. Ensure you have the Azure Functions VS Code extension installed
2. Launch VS Code from within the IoTHubTrigger directory
3. Create a local.settings.json, using the local.settings.template. Fill in the correct values from the deployment outputs as described in the template.

This will dump out the message in detail for you to review in the logs.

## Run IoTHubOutput example in VS Code

Same steps as above, but do this from the `IoTHubOutput` directory. This will require a few more settings
in the `local.settings.json` file.

Note that if you are sending up data from your own tooling, the output filter uses the following logic to decide which messages to allow through the filter. You'll need to ensure your data follows this pattern,
or change the filter logic. If you're using `TemperatureController`, the data is already in this format.

```c#
    if (body.ContainsKey("temperature") && eventData.SystemProperties.ContainsKey("dt-subject"))
```

You can log onto the portal, and verify that the output event hub 'ehout' is getting message traffic.

## References

You may find it helpful to refer to these sources along the way

* [Azure IoT Hub trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-iot-trigger)
* [ADO Azure Functions Sample](https://github.com/microsoft/devops-project-samples/tree/master/dotnet/aspnetcore/functionApp/Application)
* [Azure Functions: Continuous delivery with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-azure-devops)
* [Microsoft.Azure.WebJobs.Extensions.EventHubs package README](https://www.nuget.org/packages/Microsoft.Azure.WebJobs.Extensions.EventHubs#readme-body-tab)
* [Tutorial for creating Azure Functions triggered by IoT Hub](https://learn.microsoft.com/en-us/answers/questions/1166602/tutorial-for-creating-iot-hub-triggered-azure-func)
