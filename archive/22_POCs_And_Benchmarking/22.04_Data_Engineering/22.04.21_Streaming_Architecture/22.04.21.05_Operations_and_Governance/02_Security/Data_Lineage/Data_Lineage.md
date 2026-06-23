# Data Lineage in Streaming

Data Lineage answers the questions: "Where did this data come from?" and "If I change this schema, what downstream services will break?"

## The Complexity of Streaming Lineage
In batch systems (like dbt + Snowflake), lineage is easily derived by parsing SQL `SELECT` statements. In streaming, data flows through Java/Python applications, Kafka topics, and Flink jobs, making static code analysis nearly impossible.

## Architectural Approaches

### 1. OpenLineage Integration
*   **OpenLineage** is an open standard for metadata and lineage collection.
*   Stream processors (like Spark Structured Streaming and Flink) emit OpenLineage events to a central backend (like **Marquez** or **Datahub**) whenever a job starts, stops, or reads/writes from a topic.
*   *Result*: A visual graph showing `Topic A` -> `Flink Job B` -> `Topic C`.

### 2. Header Propagation (Distributed Tracing)
*   Leveraging OpenTelemetry (OTel).
*   The originating producer injects a `traceparent` ID into the Kafka message headers.
*   Every stream processor that reads the message and produces a derived message extracts the header and injects it into the new message.
*   *Result*: You can view a trace in Jaeger/Datadog showing the exact microsecond latency of a specific event as it traversed 5 different topics and 3 microservices.
