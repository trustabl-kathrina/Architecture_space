# Gold Streaming (Aggregations)

The Gold layer contains highly refined, use-case specific data, usually aggregated for specific dashboards, ML features, or operational triggers.

## Processing Steps
Stream processors read from Silver topics and perform complex, stateful operations:
1.  **Windowed Aggregations**: "Calculate the total sales per store every 5 minutes (Tumbling Window)."
2.  **Sessionization**: Grouping individual clicks into a single `UserSession` event.
3.  **Complex Event Processing (CEP)**: Identifying specific patterns (e.g., generating an `AccountTakeoverAlert` event).

## Output & Serving
Because Gold data represents specific answers or current states, it is rarely just left in a Kafka topic. It is usually "sunk" into a serving layer:
*   **Real-Time OLAP**: Ingested into Apache Pinot, Druid, or Rockset to serve low-latency dashboards.
*   **Key-Value Store**: Ingested into Redis or DynamoDB to serve as low-latency features for ML inference or application lookups.
*   **Operational Triggers**: Firing an event directly to an API gateway to trigger a push notification to a user.
