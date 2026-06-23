# Cloud vs. Market Options: Capability Comparison

This matrix compares the top streaming technologies on the market against native cloud offerings to help architects decide between "Best of Breed" and "Cloud Native" approaches.

## 1. Event Streaming (The Brokers)

### Cloud-Native Offerings
| Feature | AWS Kinesis Data Streams | GCP Pub/Sub | Azure Event Hubs | AWS MSK (Managed Kafka) |
| :--- | :--- | :--- | :--- | :--- |
| **Model** | Shard-based (Partitioned) | Push/Pull Routing | Partitioned | Partitioned Log |
| **Serverless Ops** | On-Demand mode available | Fully Serverless | Auto-inflate available | Serverless tier available |
| **Max Retention** | 365 Days | 31 Days | 90 Days (Premium) | Infinite (via Tiered S3) |
| **Ordering Guarantees** | Strict (per Shard) | Ordering Keys (limited scale per key) | Strict (per Partition) | Strict (per Partition) |
| **Replayability** | Good (Up to 365 days) | Poor (Acknowledge and delete model) | Good (Up to 90 days) | Excellent (Infinite) |
| **Consumer Decoupling**| Poor (Shared 2MB/s limit without EFO) | Excellent (Isolated subscriptions) | Moderate (Consumer Groups) | Moderate (Consumer Groups) |
| **Exactly-Once Delivery**| No (At-least-once) | Yes (Within a single region) | No (At-least-once) | Yes (Idempotent producer & Transactions) |
| **Ecosystem Integrations**| AWS Native (Lambda, Firehose) | GCP Native (Dataflow, BQ) | Azure Native (Stream Analytics) | Open Source (Kafka Connect) |
| **Cost at Scale** | High | High | Medium | Low to Medium |
| **Latency** | ~50ms - 200ms | ~50ms - 150ms | ~20ms - 50ms | < 10ms |
| **Throughput** | High (Scales via shards) | Infinite (Globally auto-scaled) | High (Scales via TUs) | Very High (Scale by instance) |
| **Deployment Model** | Serverless / Managed Service | Fully Serverless SaaS | Fully managed PaaS | Managed Cluster (PaaS) |
| **Operational Complexity** | Low (On-Demand mode) | True Serverless | Low (Managed PaaS) | Medium to High (Broker/Subnets) |
| **Overall Rating** | **7/10** (Solid but aging) | **8.5/10** (Unmatched serverless simplicity) | **8/10** (Great Kafka compatibility) | **9/10** (Enterprise standard, managed) |

### Top Market Options (Self-Hosted or Vendor PaaS)
| Feature | Apache Kafka (Confluent) | Apache Pulsar (StreamNative) | Redpanda | RabbitMQ |
| :--- | :--- | :--- | :--- | :--- |
| **Architecture** | Distributed Commit Log | Multi-layer (Compute + Storage decoupled) | Thread-per-core (C++) | Message Queue (AMQP) |
| **Throughput** | Extremely High | Extremely High | Ultra High (Lower Latency) | Medium / High |
| **Storage Engine** | Local Disk (or Tiered Object) | Apache BookKeeper | Local Disk (or Tiered Object)| RAM / Disk |
| **Complexity** | High (JVM, ZK/KRaft) | Very High (ZK, Bookies, Brokers)| Low (Single C++ Binary) | Low |
| **Multi-Tenancy** | Weak (Logical via ACLs) | Native (Hardware isolated) | Weak (Logical) | Native (Virtual Hosts) |
| **Geo-Replication** | External (MirrorMaker 2) | Native | Native (Enterprise edition) | Federation/Shovel plugins |
| **Protocol Compatibility**| Kafka | Kafka, AMQP, MQTT (via handlers) | Kafka (Drop-in replacement) | AMQP, MQTT, STOMP |
| **Best For** | Enterprise standard, massive ecosystems. | Unified Queuing + Streaming, multi-tenancy. | High performance Kafka alternative, edge deployments. | Complex routing, task queues, not big-data streaming. |
| **Latency** | < 10ms | < 10ms | < 1ms (C++ Thread-per-core) | ~10ms - 50ms |
| **Exactly-Once Delivery** | Yes (Transactions) | Yes (Idempotence & Transactions) | Yes (Kafka API compatible) | No (At-least-once standard) |
| **Deployment Model** | IaaS/PaaS/SaaS | IaaS/PaaS/SaaS | IaaS/PaaS/SaaS | IaaS/PaaS |
| **Operational Complexity** | High (Zookeeper/KRaft, JVM tuning) | Very High (Requires managing BookKeeper) | Low (Single binary, auto-tuning) | Low to Medium (Erlang) |
| **Overall Rating** | **9.5/10** (The King) | **8.5/10** (Powerful but complex) | **9/10** (The lean disruptor) | **6/10** (For queues, not streaming) |

---

## 2. Stream Processing (The Compute Engines)

### Cloud-Native Offerings
| Feature | AWS Managed Flink (KDA) | GCP Dataflow | Azure Stream Analytics |
| :--- | :--- | :--- | :--- |
| **Underlying Engine** | Apache Flink | Apache Beam | Proprietary SQL Engine |
| **Serverless Abstraction**| Yes (KPUs) | Yes (Liquid Sharding) | Yes (Streaming Units) |
| **Language Support** | Java, Python, SQL, Scala | Java, Python, Go, SQL | SQL-like dialect only |
| **State Management** | RocksDB + S3 | Google Backend State Engine | Internal |
| **Autoscaling Reactivity**| Slow (Requires job restart) | Instant (Dynamic splitting mid-flight) | Moderate (Rule-based SU scaling) |
| **Unified Batch/Stream** | Weak (Flink is stream-first) | Perfect (Beam model) | Weak (Different tools needed for batch) |
| **Custom ML Embedding** | Yes (via User Defined Functions) | Excellent (Native DoFn embedding) | Limited / Complex via external REST APIs |
| **Best For** | Complex stateful processing on AWS. | Unified batch/stream and dynamic autoscaling. | Quick, low-code analytics and PowerBI dashboards. |
| **Latency** | Sub-millisecond | Milliseconds | Seconds |
| **Throughput** | Extremely High | Extremely High (Auto-scales) | High |
| **Exactly Once Semantics** | Supported (Chandy-Lamport) | Supported | Supported |
| **Deployment Model** | Serverless PaaS | Serverless PaaS | Fully Managed PaaS |
| **Operational Complexity** | High (Requires dedicated streaming cluster/manager) | Low (Serverless, handled by Google) | Low (UI/SQL driven) |
| **Overall Rating** | **8/10** (Powerful engine, clunky AWS wrapper) | **9/10** (The gold standard for serverless streaming) | **7/10** (Great for analysts, poor for engineers) |

### Top Market Options (Self-Hosted or Vendor PaaS)
| Feature | Apache Flink | Spark Structured Streaming | Kafka Streams / ksqlDB |
| :--- | :--- | :--- | :--- |
| **Architecture** | Continuous Streaming | Micro-batching | Embedded Library |
| **Latency** | Sub-millisecond | Hundreds of milliseconds | Milliseconds |
| **Deployment** | Standalone, YARN, Kubernetes | Standalone, YARN, Kubernetes | Microservice JVM (Spring Boot) |
| **State Management** | Local RocksDB + Distributed Snapshots | HDFS / Object Store Checkpoints | Local RocksDB (backed by Kafka changelogs) |
| **Complex Event Processing**| Best in Class (Flink CEP) | Limited | Limited |
| **Ecosystem Integrations**| Massive (Any DB/Message Bus) | Massive (Lakehouse/Delta/Iceberg native) | Restricted to Kafka topologies natively |
| **Operational Overhead** | High (Managing TaskManagers/JobManagers) | High (Managing Spark clusters) | Low (Scales with microservices) |
| **Best For** | True real-time CEP and massive state. | Lakehouse ingestion and unified ELT. | Kafka-to-Kafka transformations without external clusters. |
| **Throughput** | Extremely High | Extremely High (Batch optimized) | High |
| **Exactly Once Semantics** | Supported | Supported | Supported (Via Kafka Transactions) |
| **Operational Complexity** | High (Cluster management, savepoints) | High (Spark cluster tuning) | Very Low (Scales with application pods) |
| **Overall Rating** | **9.5/10** (The streaming champion) | **8.5/10** (The batch/lakehouse champion) | **8/10** (The microservice champion) |
