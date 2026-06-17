# Spark Structured Streaming vs. Apache Flink

This POC evaluates the two most dominant open-source stream processing engines.

## Comparison Scenarios

### Scenario 1: Unified Batch and Stream Processing (Lakehouse)
*   **Requirement**: The team wants to use the exact same code to ingest continuous streams into Delta Lake, and to run massive daily historical backfills.
*   **Spark Structured Streaming**: The undisputed king of the Lakehouse. The DataFrame API is identical for batch and stream. Native integration with Delta Lake/Iceberg.
*   **Flink**: While Flink supports bounded streams (batch), its API and ecosystem are heavily optimized for continuous streaming. Integration with table formats is improving but trails Spark.
*   *Winner*: **Spark Structured Streaming**

### Scenario 2: Sub-Millisecond Fraud Detection (Low Latency)
*   **Requirement**: A credit card swipe must be evaluated against a moving window of state within 5 milliseconds.
*   **Spark Structured Streaming**: Uses a micro-batch architecture. Minimum latency is typically bounded by the trigger interval (hundreds of milliseconds to seconds). Not suitable for true real-time.
*   **Flink**: A true continuous streaming engine. Events are processed individually as they arrive. Perfectly capable of sub-millisecond latencies.
*   *Winner*: **Flink**

### Scenario 3: Complex State Management
*   **Requirement**: The application must track the session state of millions of users, holding terabytes of state in memory without crashing.
*   **Spark Structured Streaming**: State is managed via HDFS/S3 checkpointing, but complex, custom stateful aggregations (e.g., managing multiple independent timers per key) are difficult to express in the DataFrame API.
*   **Flink**: State is a first-class citizen. Flink embeds RocksDB locally on the worker nodes, allowing for massive state storage with incredibly fast read/write access. Provides low-level APIs (`KeyedProcessFunction`) for granular state and timer control.
*   *Winner*: **Flink**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **API Unification**: Validated against the Lakehouse paradigm requiring identical code for continuous streams and massive historical batch backfills.
2. **True Low Latency**: Validated against sub-millisecond SLA requirements for fraud detection.
3. **State Capacity**: Validated by pushing terabytes of active session state and measuring GC overhead and failure recovery.

### Capability Comparison Table
| Criteria | Spark Structured Streaming | Apache Flink |
| :--- | :--- | :--- |
| **Execution Model** | Micro-batching | True Continuous Processing |
| **Batch/Stream Unification** | Excellent (Identical DataFrame API) | Good, but continuous streaming is primary focus |
| **State Management** | HDFS/S3 Checkpoints | Local RocksDB + Distributed Snapshots (Chandy-Lamport) |
| **Latency** | ~500ms to Seconds (Micro-batch) | Sub-Millisecond (Continuous) |
| **Throughput** | Extremely High (Batch optimized) | Extremely High (Stream optimized) |
| **Exactly Once Semantics** | Supported | Supported |
| **Deployment Model** | Cluster (YARN, K8s, Databricks) | Cluster (YARN, K8s, KDA) |
| **Operational Complexity** | High (Spark cluster management) | High (Flink cluster management) |
