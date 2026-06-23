# Kafka vs. Amazon Kinesis Data Streams

This POC evaluates Apache Kafka (self-managed or Confluent) against Amazon Kinesis Data Streams (KDS) for AWS-centric event ingestion.

## Comparison Scenarios

### Scenario 1: Unpredictable Traffic Spikes
*   **Requirement**: A B2C application expects sudden, massive spikes in traffic (e.g., during a Superbowl ad) and requires zero downtime.
*   **Kafka**: Partitioning is static. Scaling up brokers and reassigning partitions takes time and moves terabytes of data across the network, which can impact performance during the spike.
*   **Kinesis**: KDS On-Demand mode automatically and instantly scales shards up and down in response to traffic without manual intervention.
*   *Winner*: **Kinesis**

### Scenario 2: High Number of Consumers (Fan-Out)
*   **Requirement**: A single event stream must be read by 15 different downstream microservices independently and concurrently.
*   **Kafka**: Handles high fan-out exceptionally well. Consumers use different Consumer Groups and track their own offsets in the `__consumer_offsets` topic without taxing the broker's read bandwidth excessively.
*   **Kinesis**: Standard Kinesis shares a 2MB/sec read limit *per shard* across ALL consumers. 15 consumers will instantly throttle the shard. You must use **Enhanced Fan-Out (EFO)**, which provides dedicated 2MB/sec pipes per consumer, but significantly increases costs.
*   *Winner*: **Kafka** (More cost-effective for massive fan-out)

### Scenario 3: Long-Term Retention and Replayability
*   **Requirement**: Events must be stored for 5 years to support regulatory audits and ML model retraining.
*   **Kafka**: Using Tiered Storage (Confluent or MSK), older data is offloaded to S3 while remaining transparently queryable by consumers. Storage is extremely cheap.
*   **Kinesis**: Maximum retention is strictly 365 days. Data must be flushed to S3 (via Firehose) for long-term storage, meaning consumers must write dual-read logic (read recent from Kinesis, read old from S3).
*   *Winner*: **Kafka**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Scaling Elasticity**: Validated by injecting sudden traffic spikes to measure manual intervention required vs. auto-scaling speed.
2. **Fan-Out Limits**: Validated by attaching 15 concurrent consumer groups and measuring read throttling.
3. **Long-Term Storage**: Validated against requirements for 5-year retention and consumer replayability.

### Capability Comparison Table
| Criteria | Apache Kafka | Amazon Kinesis Data Streams |
| :--- | :--- | :--- |
| **Scaling Mechanism** | Static Partitioning (Manual rebalancing) | On-Demand (Automatic shard splitting) |
| **Consumer Fan-Out** | Very High (Isolated consumer offsets) | Limited (Shared 2MB/s limit unless EFO is used) |
| **Data Retention** | Infinite (via Tiered Storage) | Max 365 Days |
| **Message Ordering** | Strict (Per Partition) | Strict (Per Shard/Partition Key) |
| **Latency** | < 10ms | ~50ms - 200ms (70ms with EFO) |
| **Throughput** | Millions of messages/sec | Scales linearly via shards (1MB/s in, 2MB/s out per shard) |
| **Exactly Once Semantics** | Supported (Transactions) | Supported (via KCL deduplication logic) |
| **Deployment Model** | IaaS/PaaS (Confluent/MSK) | Serverless / Managed Service |
| **Operational Complexity** | High (Requires partition capacity planning) | Low (On-Demand mode handles spikes) |
