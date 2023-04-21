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

                    // This is designed to handle messages for devices implementing "dtmi:azdevice:i2ctemphumiditymonitor;1".
                    // See: https://github.com/jcoliz/AzDevice.IoTHubWorker/tree/main/examples/I2cTempHumidityMonitor
                    //
                    // However, it will work for any interface which implements components starting with "Sensor",
                    // and implementing "Temperature" and "Humidity" telemetry, and also has properties "CurrentTemperature" and "CurrentHumidity"
                    //
                    // Note that the name of the device in IoT Hub needs to be the same as the corresponding digital twin ID
                    if (
                            eventData.SystemProperties.ContainsKey("dt-subject") 
                            && 
                            ((string)eventData.SystemProperties["dt-subject"]).StartsWith("Sensor")
                        )
                    {
                        // Extract needed info
                        var deviceId = eventData.SystemProperties["iothub-connection-device-id"] as string;
                        var component = eventData.SystemProperties["dt-subject"];
                        double temperature = ((System.Text.Json.JsonElement)body["Temperature"]).GetDouble();
                        double humidity = ((System.Text.Json.JsonElement)body["Humidity"]).GetDouble();

                        log.LogInformation($"Sending to Digital Twin for Device:{deviceId} Temperature:{temperature} Humidity:{humidity}");

                        // Take telemetry values from telemetry message, and pass them along as property
                        // values, because that's what digital twins knows about
                        // TODO: This should also listen for device twin updates, and then patch ALL of the
                        // digital twin values.

                        var updateTwinData = new JsonPatchDocument();
                        updateTwinData.AppendReplace($"/{component}/CurrentTemperature", temperature);
                        updateTwinData.AppendReplace($"/{component}/CurrentHumidity", humidity);
                        await client.UpdateDigitalTwinAsync(deviceId, updateTwinData);

                        log.LogInformation("Sent update to digital twin");
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
