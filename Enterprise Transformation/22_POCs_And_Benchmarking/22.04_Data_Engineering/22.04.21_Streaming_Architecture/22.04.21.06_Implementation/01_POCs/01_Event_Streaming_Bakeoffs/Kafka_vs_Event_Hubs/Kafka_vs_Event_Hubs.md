# Kafka vs. Azure Event Hubs

This POC evaluates Apache Kafka against Azure Event Hubs for an enterprise migrating to the Microsoft Azure cloud.

## Comparison Scenarios

### Scenario 1: Migration Without Code Rewrites
*   **Requirement**: An enterprise has 50 existing Java/Spring Boot applications using the `kafka-clients` library. They are moving to Azure and want a managed service without rewriting the apps.
*   **Kafka (Confluent Cloud/HDInsight)**: Native Kafka, so zero code changes required.
*   **Azure Event Hubs**: Event Hubs provides a "Kafka Endpoint". Existing applications simply change their broker connection string to the Event Hubs URL. No code changes are required for standard produce/consume operations.
*   *Winner*: **Tie** (Event Hubs makes migration incredibly easy while being fully native Azure PaaS).

### Scenario 2: Maximum Message Size
*   **Requirement**: The system needs to stream large media files or massive JSON payloads (e.g., 5MB per message).
*   **Kafka**: By default, the max message size is 1MB. It can be tuned higher via `message.max.bytes`, but this degrades performance and increases memory pressure on brokers.
*   **Event Hubs**: Standard tier has a hard limit of 1MB. Dedicated tier allows up to 1MB.
*   *Verdict*: Neither is great for large files. *Architectural Best Practice*: Use the **Claim Check Pattern** (store the 5MB file in Blob Storage/S3, and send a 1KB Kafka message containing the URL to the blob).

### Scenario 3: Ecosystem and Stream Processing
*   **Requirement**: The architecture requires complex, stateful stream processing using Kafka Streams or ksqlDB.
*   **Kafka**: Natively supports Kafka Streams and ksqlDB.
*   **Event Hubs**: The Event Hubs Kafka endpoint *does not* fully support Kafka Streams API (specifically regarding internal changelog topics and transactions). You must use Azure Stream Analytics or Databricks instead.
*   *Winner*: **Kafka** (if married to the Kafka Streams ecosystem).

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Migration Complexity**: Validated by evaluating code rewrites required for legacy Spring Boot apps migrating to the cloud.
2. **Payload Capacity**: Validated against requirements for streaming large objects (e.g., 5MB+).
3. **Ecosystem Compatibility**: Validated against the need for advanced stateful stream processing via Kafka Streams vs native Azure tools.

### Capability Comparison Table
| Criteria | Apache Kafka | Azure Event Hubs |
| :--- | :--- | :--- |
| **Migration Path** | N/A (Native standard) | Excellent (Kafka Endpoint API) |
| **Max Payload Size** | Configurable (>1MB possible but anti-pattern) | 1MB (Standard/Dedicated limit) |
| **Stream Processing Integration** | Deep native support (Kafka Streams, ksqlDB) | Azure Stream Analytics, Databricks |
| **Latency** | < 10ms (Highly tunable) | ~20ms - 50ms |
| **Throughput** | Millions of messages/sec | High (Scales via Throughput Units) |
| **Exactly Once Semantics** | Supported (Idempotent producers + Transactions) | Not natively supported |
| **Deployment Model** | IaaS (EC2/VMs) or PaaS (Confluent Cloud/MSK) | Fully managed PaaS |
| **Operational Complexity** | High (JVM, ZK/KRaft management) | Low (Fully managed PaaS) |
