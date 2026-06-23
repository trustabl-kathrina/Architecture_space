# Amazon Kinesis vs. Amazon MSK

This POC evaluates AWS's two native streaming offerings to determine which managed service fits specific operational profiles.

## Comparison Scenarios

### Scenario 1: Operational Simplicity
*   **Requirement**: A small team needs a streaming bus up and running in minutes with zero knowledge of distributed systems.
*   **Kinesis**: Extremely simple via the AWS Console. Pick "On-Demand" mode, and you are done. AWS manages everything.
*   **MSK**: Requires understanding Kafka concepts (Brokers, Zookeeper/KRaft, Partitions, VPCs, Subnets, EBS volumes). Even MSK Serverless requires configuring Kafka-specific IAM policies.
*   *Winner*: **Kinesis**

### Scenario 2: Extreme Throughput Cost Efficiency
*   **Requirement**: The system ingests 5 GB/second of log data continuously, 24/7.
*   **Kinesis**: Kinesis pricing is heavily based on PUT payload units and shard hours. At massive, continuous scale, Kinesis becomes significantly more expensive than raw EC2 compute.
*   **MSK**: Provisioned MSK clusters (e.g., using `m5.4xlarge` instances) have fixed hourly compute costs regardless of how many messages pass through them. At high volume, the cost per GB is drastically lower than Kinesis.
*   *Winner*: **MSK**

### Scenario 3: Real-Time Analytics Integration
*   **Requirement**: Non-engineers (analysts) need to write SQL queries against the live data stream.
*   **Kinesis**: Integrates seamlessly with Kinesis Data Analytics Studio (Managed Flink), allowing analysts to write SQL directly against the stream in an interactive notebook.
*   **MSK**: Integrates with Managed Flink, but requires more setup. Alternatively, requires deploying ksqlDB on EC2/EKS.
*   *Winner*: **Kinesis**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Operational Simplicity**: Validated against the team's familiarity with distributed systems and Kafka internals.
2. **Cost at Scale**: Validated by modeling pricing for a continuous 5 GB/s throughput load.
3. **Analytics Integration**: Validated against the business requirement for interactive SQL querying.

### Capability Comparison Table
| Criteria | Amazon Kinesis | Amazon MSK |
| :--- | :--- | :--- |
| **Cost at Massive Scale** | High (Pay per PUT/Shard/GB) | Low (Fixed hourly EC2/Broker costs) |
| **Interactive Analytics** | Native (Kinesis Data Analytics Studio) | Requires EC2 deployments (ksqlDB) |
| **Ecosystem Compatibility** | AWS Native | Open Source (Kafka API) |
| **Latency** | ~50ms - 200ms | < 10ms |
| **Throughput** | High (Scale by shard limits) | Very High (Scale by instance size/count) |
| **Exactly Once Semantics** | Supported via KCL | Supported via Kafka Transactions |
| **Deployment Model** | Serverless PaaS | Managed Cluster (PaaS) |
| **Operational Complexity** | Extremely Low (Serverless options) | Medium to High (Broker/Subnet management) |
