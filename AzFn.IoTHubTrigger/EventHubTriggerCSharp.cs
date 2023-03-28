using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Messaging.EventHubs;

namespace AzFn
{
    public static class EventHubTriggerCSharp
    {
        [FunctionName("EventHubTriggerCSharp")]
        public static void Run(
            [EventHubTrigger("%HUBNAME%", Connection = "HUBCSTR")] EventData myEventHubMessage,
            DateTime enqueuedTimeUtc,
            Int64 sequenceNumber,
            string offset,
            ILogger log)
        {
            var body = myEventHubMessage.EventBody.ToString();
            log.LogInformation($"Event: {body}");
            // Metadata accessed by binding to EventData
            log.LogInformation($"SP.EnqueuedTimeUtc={myEventHubMessage.SystemProperties["EnqueuedTimeUtc"]}");
            log.LogInformation($"SP.SequenceNumber={myEventHubMessage.SystemProperties["SequenceNumber"]}");
            log.LogInformation($"SP.Offset={myEventHubMessage.SystemProperties["Offset"]}");
            // Metadata accessed by using binding expressions in method parameters
            log.LogInformation($"EnqueuedTimeUtc={enqueuedTimeUtc}");
            log.LogInformation($"SequenceNumber={sequenceNumber}");
            log.LogInformation($"Offset={offset}");
        }
    }
}
