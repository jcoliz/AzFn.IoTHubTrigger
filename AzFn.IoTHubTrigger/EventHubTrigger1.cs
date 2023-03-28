using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public static class EventHubTrigger1
    {
        [FunctionName("EventHubTrigger1")]
        public static async Task Run
        (
            [EventHubTrigger("%EVENTPATH%", Connection = "EVENTCSTR", ConsumerGroup = "%HUBCG%")] EventData[] events, 
            ILogger log
        )
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    log.LogInformation($"*** C# Event Hub trigger function processed message #{eventData.SequenceNumber}, enqueued at {eventData.EnqueuedTime}");

                    var body = eventData.EventBody.ToObjectFromJson<Dictionary<string, object>>();
                    foreach (var kvp in body)
                        log.LogInformation($"{kvp.Key}: {kvp.Value}");

                    foreach (var kvp in eventData.Properties)
                        log.LogInformation($"P.{kvp.Key}: {kvp.Value}");

                    foreach (var kvp in eventData.SystemProperties)
                        log.LogInformation($"SP.{kvp.Key}: {kvp.Value}");

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
