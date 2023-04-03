# Process and filter IoT data by using Azure Functions

![Architecture](/docs/images/Architecture.png)

This is a complete end-to-end example of how to use Azure Functions to receive data
from an Azure IoT Hub, filter them, and output the results to a separate Event Hub.

## What's Here?

* **Complete ARM Template**: Deploys an IoT Hub, DPS, Storage, Function App, plus a separate Event Hub for output
* **Code Examples**: Two code examples, which can be run locally using VS Code, or deployed to an Azure Function App. `IoTHubTrigger` shows how to use the trigger only, and `IoTHubOutput` adds in output bindings and some filtering logic.
* **Azure Dev Ops Pipeline Definitions**: Ready-to-use pipelines to deploy the filter from your ADO project pipeline, into the function app deployed by the ARM Template.

## Deploy Resources

The included [ARM Template](/.azure/deploy/azuredeploy.bicep) deploys all of the resources described in the architecture diagram above.
It also wires up the connections between services so everything is ready to go. Be sure to clone this repo with submodules, as the 
deployment template uses modules from the [AzDeploy.Bicep](https://github.com/jcoliz/AzDeploy.Bicep) project.

Here's what you do...

1. Open Powershell
2. Change to the `.azure/deploy` directory
3. Set `$env:RESOURCEGROUP` to the name of a resource group you'd like to create and deploy into.
4. Run the `BringUp.ps1` script. This creates the resource group, and starts a deployment.
5. Review the `outputs` shown. I recommend saving each of these outputs into an environment variable, perhaps in an `.env.ps1` file, for easy reference. You can start with the `.env.template.ps1` as an example for what to save.

## Start sending data to your IoTHub

If you already know how to do this using your own tooling, great! Go ahead and start regularly sending
data up to the IoT Hub deployed above.

The deployment is also ready to use with the `Temperature Controller` example from the `AzDevice.IoTHubWorker`
project. If you have saved off the deployment outputs from above as environment variables, you could jump into the Getting Started guide. Start by creating a DPS enrollment group, and continue through until you have a `config.toml` file for connecting to this IoT Hub. Copy that file into the `Temperature Controller` example directory, and `dotnet run` to start sending data.

## Run IoTHubTrigger example in VS Code

1. Ensure you have the Azure Functions VS Code extension installed
2. Launch VS Code from within the `IoTHubTrigger` directory
3. Create a `local.settings.json`, using the `local.settings.template`. Fill in the correct values from the deployment outputs as described in the template.
4. Launch the app locally (F5)

This simple example logs the details of each telemetry message coming from the IoT Hub.

```c#
    public static class EventHubTrigger1
    {
        [FunctionName("EventHubTrigger1")]
        public static async Task Run
        (
            [EventHubTrigger("%EVENTPATH%", Connection = "EVENTCSTR", ConsumerGroup = "%HUBCG%")] EventData[] events, 
            ILogger log
        )
        {
            foreach (EventData eventData in events)
            {
                try
                {
                    log.LogInformation($"*** C# Event Hub trigger function processed message #{eventData.SequenceNumber}, enqueued at {eventData.EnqueuedTime}");

                    var body = eventData.EventBody.ToObjectFromJson<Dictionary<string, object>>();
                    foreach (var kvp in body)
                        log.LogInformation($"{kvp.Key}: {kvp.Value}");
```

## Run IoTHubOutput example in VS Code

Same steps as above, but do this from the `IoTHubOutput` directory. This will require a few more settings
in the `local.settings.json` file. In particular, the output event hub needs a path and connection string,
which is attached to the `IAsyncCollector<EventData>` where outgoing events will be added.

```c#
    public static class EventHubFilter
    {
        [FunctionName("EventHubFilter")]
        public static async Task Run
        (
            [EventHubTrigger("%EVENTPATH%", Connection = "EVENTCSTR", ConsumerGroup = "%HUBCG%")] EventData[] events, 
            [EventHub("%EHOUTPATH%", Connection = "EHOUTCSTR")]IAsyncCollector<EventData> outputEvents,
            ILogger log
        )
        {
            foreach (EventData eventData in events)
            {
```

In addition to logging the event details, this example constructs a whole new message if the incoming
message meets its criteria. This message is sent to the output event hub.

Note that if you are sending up data from your own tooling, you'll need to ensure your data follows the expected pattern, or change the filter logic. If you're using `TemperatureController`, the data is already in this format.

```c#
                    if (body.ContainsKey("temperature") && eventData.SystemProperties.ContainsKey("dt-subject"))
                    {
                        var outbody = new Dictionary<string, object>();
                        outbody["temperature"] = body["temperature"];
                        outbody["dt-subject"] = eventData.SystemProperties["dt-subject"];

                        var outjson = System.Text.Json.JsonSerializer.Serialize(outbody);
                        var outevent = new EventData(outjson);
                        await outputEvents.AddAsync(outevent);
                    }
```

You can log onto the portal, and verify that the output event hub 'ehout' is getting message traffic.

## Deploy function code to Azure

I like to follow a rule that only Azure Dev Ops ever deploys code to the Azure cloud--never do I
ever deploy to the cloud from a local machine. This ensures that the setup is much closer to production-ready
when it's time to shift over to a production deployment.

This example includes definitions for a [Continuous Integration Pipeline]() and a [Continuous Deployment Pipeline](). If you create an Azure Dev Ops project from a fork of this code, you can use these 
defintions directly to deploy the function code to your already-deployed services.

This is a pretty simple pipeline, using the `AzureFunctionApp@1` pipeline task. Just be sure to set the
`azureAppServiceName` and `azureServiceConnectionName` variables in your pipeline.

```yaml
steps:
- task: AzureFunctionApp@1
  displayName: 'Deploy Function App'
  inputs:
    azureSubscription: '$(azureServiceConnectionName)'
    appName: '$(azureAppServiceName)'
    appType: functionAppLinux
    package: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip
```

## References

You may find it helpful to refer to these sources along the way

* [Azure IoT Hub trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-iot-trigger)
* [ADO Azure Functions Sample](https://github.com/microsoft/devops-project-samples/tree/master/dotnet/aspnetcore/functionApp/Application)
* [Azure Functions: Continuous delivery with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-azure-devops)
* [Microsoft.Azure.WebJobs.Extensions.EventHubs package README](https://www.nuget.org/packages/Microsoft.Azure.WebJobs.Extensions.EventHubs#readme-body-tab)
* [Tutorial for creating Azure Functions triggered by IoT Hub](https://learn.microsoft.com/en-us/answers/questions/1166602/tutorial-for-creating-iot-hub-triggered-azure-func)
