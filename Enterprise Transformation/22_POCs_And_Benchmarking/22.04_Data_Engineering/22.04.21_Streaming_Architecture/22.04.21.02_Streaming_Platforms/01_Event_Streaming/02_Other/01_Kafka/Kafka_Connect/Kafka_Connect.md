# Kafka Connect Architecture

Kafka Connect is a framework for scalably and reliably streaming data between Apache Kafka and other systems (RDBMS, NoSQL, Object Stores).

## Core Architecture
*   **Source Connectors**: Ingest data from an external system (e.g., PostgreSQL via Debezium, Salesforce) into Kafka topics.
*   **Sink Connectors**: Export data from Kafka topics to external systems (e.g., Elasticsearch, Snowflake, S3).
*   **Workers**: The JVM processes that execute the connectors and tasks.
*   **Tasks**: The actual unit of work. Connectors break down jobs into tasks for parallel execution.

## Deployment Modes
1.  **Standalone Mode**: A single JVM process executes all connectors and tasks. Not fault-tolerant. Used for local testing or lightweight tasks.
2.  **Distributed Mode**: Multiple workers form a Connect cluster. Fault-tolerant, automatically load-balances tasks, and stores state/offsets in internal Kafka topics (`connect-configs`, `connect-offsets`, `connect-status`). **Required for production.**

## Key Components
*   **Converters**: Handle the serialization/deserialization of data (e.g., `AvroConverter`, `JsonConverter`). They translate Kafka's byte arrays into Connect's internal data API.
*   **Single Message Transforms (SMTs)**: Lightweight, inline transformations applied to messages as they flow through Connect (e.g., masking PII, adding a timestamp, filtering records, routing to different topics) before they hit the Sink or after they leave the Source.

## Best Practices
*   Separate Source and Sink Connect clusters if they have wildly different scaling profiles or dependencies.
*   Use Schema Registry with `AvroConverter` or `ProtobufConverter` to ensure data integrity.
