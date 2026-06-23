# End-to-End Observability in Streaming

Observing a distributed streaming pipeline is fundamentally different from observing a monolithic application. A single business event (e.g., "Order Placed") may traverse an API Gateway, a Producer microservice, a Kafka Topic, a Flink Stream Processor, another Kafka Topic, a Kafka Connect Sink, and finally land in Snowflake.

To achieve **End-to-End (E2E) Observability**, you must implement the three pillars of observability—Metrics, Logs, and Traces—in a unified, correlated manner.

## 1. Distributed Tracing (The Missing Link)
Tracing an event across asynchronous boundaries requires header propagation.
*   **OpenTelemetry (OTel)**: The industry standard. The initiating producer generates a `trace_id` and `span_id`.
*   **Header Injection**: The producer injects the W3C Trace Context into the **Kafka Message Headers**.
*   **Span Extraction**: When the stream processor (e.g., Flink) consumes the message, it extracts the `trace_id` from the header, starts a new span for processing, and injects the same `trace_id` into the downstream message.
*   *Result*: A single visualization in Jaeger, Datadog, or Honeycomb showing the exact latency and success/failure at every hop.

## 2. Metrics (System & Business Health)
Streaming requires specific infrastructure metrics exported to Prometheus/Grafana.
*   **Broker Metrics**: Bytes In/Out, Under-Replicated Partitions (URP), Active Controller Count, Network Processor Idle %.
*   **Client Metrics (Producers/Consumers)**: `record-error-rate`, `record-retry-total`, `request-latency-avg`.
*   **Stream Processor Metrics**: Checkpoint duration, Checkpoint size, RocksDB block cache hit ratio, Watermark lag.
*   **Business Metrics**: "Number of fraudulent transactions blocked per minute."

## 3. Structured Logging
*   All applications in the pipeline must output JSON-formatted logs.
*   Every log statement MUST include the `trace_id` (for tracing correlation) and a `correlation_id` (a business identifier, like `order_id` or `user_id`).
*   This allows an SRE to search Splunk/Elasticsearch for `order_id: 12345` and see every log statement from the API gateway down to the data warehouse.

## 4. Synthetic Monitoring (Heartbeats)
To measure true E2E SLA, you cannot just look at CPU or Kafka lag. You must measure the time it takes for a payload to traverse the entire system.
*   **Canary Injection**: A dedicated synthetic producer injects a dummy "heartbeat" message into the source topic every 10 seconds.
*   **E2E Measurement**: A synthetic consumer listens to the final destination (e.g., queries Snowflake or listens to the final output topic) and calculates: `Time Arrived at Destination - Time Produced`. If this exceeds the SLA (e.g., 5 seconds), a P1 alert is fired.
