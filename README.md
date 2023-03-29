# Process and filter IoT data by using Azure Functions

This is a complete end-to-end example of how to use Azure Functions to receive data
from an Azure IoT Hub, filter them, and output the results to a separate Event Hub.

## What's Here?

* **Complete ARM Template**: Deploys an IoT Hub, DPS, Storage, Function App, plus a separate Event Hub for output
* **Code Examples**: Two code examples, which can be run locally using VS Code, or deployed to an Azure Function App. `IoTHubTrigger` shows how to use the trigger only, and `IoTHubOutput` adds in output bindings and some filtering logic.
* **Azure Dev Ops Pipeline Definitions**: Ready-to-use pipelines to deploy the filter from your ADO project pipeline, into the function app deployed by the ARM Template.

## References

You may find it helpful to refer to these sources along the way

* [Azure IoT Hub trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-iot-trigger)
* [ADO Azure Functions Sample](https://github.com/microsoft/devops-project-samples/tree/master/dotnet/aspnetcore/functionApp/Application)
* [Azure Functions: Continuous delivery with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-azure-devops)
* [Microsoft.Azure.WebJobs.Extensions.EventHubs package README](https://www.nuget.org/packages/Microsoft.Azure.WebJobs.Extensions.EventHubs#readme-body-tab)
* [Tutorial for creating Azure Functions triggered by IoT Hub](https://learn.microsoft.com/en-us/answers/questions/1166602/tutorial-for-creating-iot-hub-triggered-azure-func)
