# Kafka vs. GCP Pub/Sub

This POC evaluates Apache Kafka against Google Cloud Pub/Sub to determine the optimal event streaming broker for enterprise ingestion.

## Comparison Scenarios

### Scenario 1: Strict Ordering and Event Sourcing
*   **Requirement**: Financial ledger events must be processed in the exact order they were generated.
*   **Kafka**: Natively guarantees strict ordering per partition using hashing on the `account_id` key. Perfect fit.
*   **Pub/Sub**: Historically unordered. Introduced "Ordering Keys," but scaling is restricted per key. Complex to manage if a message fails (subsequent messages with the same key are blocked).
*   *Winner*: **Kafka**

### Scenario 2: Global Scalability with Zero Ops
*   **Requirement**: A mobile game generates 100 to 1,000,000 telemetry events per second unpredictably. No DevOps team is available.
*   **Kafka**: Requires pre-provisioning partitions and managing broker instances. If traffic spikes 10,000%, Kafka will experience backpressure unless heavily over-provisioned (costly).
*   **Pub/Sub**: Purely serverless. Scales instantly to millions of requests without manual intervention. Routing model automatically distributes load to consumers.
*   *Winner*: **Pub/Sub**

### Scenario 3: Stream Replay and Data Retention
*   **Requirement**: ML models require replaying the last 3 months of historical raw events.
*   **Kafka**: Built as an immutable commit log. Can retain data infinitely. Consumers simply reset their offsets to replay data at high disk-read speeds.
*   **Pub/Sub**: By default, deletes messages once acknowledged. Can be configured to retain acknowledged messages for up to 31 days (maximum), but not designed as a long-term data store.
*   *Winner*: **Kafka**

### Scenario 4: Global Fan-Out & Routing
*   **Requirement**: An event must be routed to 50 different microservices, some of which are offline.
*   **Kafka**: Each microservice requires a unique Consumer Group. 50 consumer groups reading the same partition can cause network I/O strain on the broker.
*   **Pub/Sub**: The topic-subscription model isolates consumers. Pub/Sub handles the fan-out transparently on Google's backbone. If one subscriber is down, Pub/Sub buffers its specific queue without affecting others.
*   *Winner*: **Pub/Sub**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Ordering Guarantees**: Validated against strict financial ledger sequential processing requirements.
2. **Serverless Autonomy**: Validated against volatile B2C workloads with zero DevOps team available.
3. **Replayability**: Validated against ML model historical backfill requirements.
4. **Network Fan-Out**: Validated by routing single streams to dozens of independent microservices.

### Capability Comparison Table
| Criteria | Apache Kafka | Google Cloud Pub/Sub |
| :--- | :--- | :--- |
| **Ordering** | Native, strict global ordering per partition | Limited to "Ordering Keys" |
| **Data Retention** | Infinite (Log-based) | Max 31 Days (Message-based) |
| **Consumer Decoupling** | High network I/O strain at massive scale | Perfect isolation via Subscriptions |
| **Latency** | < 10ms | ~50ms - 150ms |
| **Throughput** | Massive (Limited by cluster size) | Infinite (Globally auto-scaled) |
| **Exactly Once Semantics** | Supported (Transactions) | Supported natively (Within a region) |
| **Deployment Model** | IaaS/PaaS | Fully Serverless SaaS |
| **Operational Complexity** | High overhead, manual scaling required | True Serverless, infinite auto-scaling |
