using Azure;
using Azure.DigitalTwins.Core;
using Azure.Identity;
using Azure.Messaging.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Text.Json;

//
// Digital Twin insertion cribbed from 
// https://learn.microsoft.com/en-us/azure/digital-twins/how-to-ingest-iot-hub-data
//

namespace Company.Function
{
    public static class EventHubToDigitalTwin
    {
        private static readonly string adtInstanceUrl = Environment.GetEnvironmentVariable("ADT_SERVICE_URL");
        private static readonly HttpClient httpClient = new HttpClient();

        [FunctionName("EventHubToDigitalTwin")]
        public static async Task Run
        (
            [EventHubTrigger("%EVENTPATH%", Connection = "EVENTCSTR", ConsumerGroup = "%HUBCG%")] EventData[] events, 
            ILogger log
        )
        {
            if (adtInstanceUrl == null) 
                throw new ApplicationException("Application setting \"ADT_SERVICE_URL\" not set");

            // Authenticate with Digital Twins
            var cred = new DefaultAzureCredential();
            var client = new DigitalTwinsClient(new Uri(adtInstanceUrl), cred);
            log.LogInformation($"ADT service client connection created.");

            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    log.LogInformation($"*** C# EventHubToDigitalTwin function processed message #{eventData.SequenceNumber}, enqueued at {eventData.EnqueuedTime}");

                    var body = eventData.EventBody.ToObjectFromJson<Dictionary<string, object>>();
                    foreach (var kvp in body)
                        log.LogInformation($"{kvp.Key}: {kvp.Value}");

                    foreach (var kvp in eventData.Properties)
                        log.LogInformation($"P.{kvp.Key}: {kvp.Value}");

                    foreach (var kvp in eventData.SystemProperties)
                        log.LogInformation($"SP.{kvp.Key}: {kvp.Value}");

                    // For all telemetry messages on all components (including the root), we will send the
                    // data through to a Current{Name} property for each {Name} in the body.

                    var source = eventData.SystemProperties["iothub-message-source"] as string;
                    if (source == "Telemetry")
                    {
                        var updateTwinData = new JsonPatchDocument();
                        string objectpath = "/";
                        if (eventData.SystemProperties.ContainsKey("dt-subject"))
                            objectpath += (eventData.SystemProperties["dt-subject"] as string) + "/";

                        foreach (var kvp in body)
                        {
                            JsonElement? el = kvp.Value as JsonElement?;

                            // This only deals with numbers right now, because that's all we need.
                            // For the future, we could easily switch on ValueKind to do the right
                            // thing for each value
                            if (el.HasValue && el.Value.ValueKind == JsonValueKind.Number)
                            {
                                double value = el.Value.GetDouble();
                                updateTwinData.AppendReplace($"{objectpath}Current{kvp.Key}", value);
                            }
                        }

                        var deviceId = eventData.SystemProperties["iothub-connection-device-id"] as string;

                        log.LogInformation($"Sending to Digital Twin for Device:{deviceId} Patch:{updateTwinData}");
                        await client.UpdateDigitalTwinAsync(deviceId, updateTwinData);

                        log.LogInformation("Sent telemetry update to digital twin");
                    }
                    else if (source == "twinChangeEvents")
                    {
                        // TODO: Create a property patch containing an update for EVERY reported property
                    }

                    await Task.Yield();
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
