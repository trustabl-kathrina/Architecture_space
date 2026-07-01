# Kafka Streams vs. Apache Flink

This POC evaluates two of the most popular stateful stream processing frameworks: Kafka Streams (an embedded library) and Apache Flink (a distributed cluster engine).

## Comparison Scenarios

### Scenario 1: Infrastructure Overhead
*   **Requirement**: A microservice needs to do a simple stateful aggregation (e.g., counting API requests per user per minute). The team wants to avoid managing new distributed clusters.
*   **Kafka Streams**: It is just a Java `.jar` library. You embed it into your existing Spring Boot application. It scales by simply deploying more instances of your microservice (e.g., via Kubernetes HPA). It relies entirely on Kafka for state persistence.
*   **Flink**: Requires deploying a dedicated Flink Cluster (JobManagers, TaskManagers) or using a managed service (AWS Managed Flink). Overkill for a simple aggregation inside a single microservice.
*   *Winner*: **Kafka Streams**

### Scenario 2: Complex Event Processing (CEP) and Advanced Windowing
*   **Requirement**: Detecting complex fraud patterns ("Transaction > $1000 followed by IP change within 10 seconds").
*   **Kafka Streams**: Has basic Tumbling, Hopping, and Session windows, but lacks a dedicated pattern-matching API. Implementing complex NFA state machines is highly manual and error-prone.
*   **Flink**: Has a dedicated `Flink CEP` library with regex-like syntax for event pattern matching. Offers highly granular control over watermarks, late data, and custom window evictors.
*   *Winner*: **Flink**

### Scenario 3: Data Sources and Sinks
*   **Requirement**: The stream processor must read from Kafka, enrich with data from Postgres (via JDBC), and write the result to Elasticsearch.
*   **Kafka Streams**: Designed *exclusively* for Kafka-to-Kafka topologies. Reading from Postgres or writing to Elasticsearch requires chaining Kafka Connect into the architecture (Postgres -> Connect -> Kafka -> KStreams -> Kafka -> Connect -> Elasticsearch).
*   **Flink**: Has a massive ecosystem of native Sources and Sinks. A single Flink job can read from Kafka, query Postgres dynamically using Async I/O, and write directly to Elasticsearch.
*   *Winner*: **Flink**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Infrastructure Footprint**: Validated against the team's desire to avoid deploying new distributed clusters for simple streaming tasks.
2. **Complex Pattern Matching**: Validated against fraud detection requirements utilizing complex NFA state machines.
3. **I/O Flexibility**: Validated against the requirement to read/write natively to non-Kafka databases (like Postgres and Elasticsearch) in a single hop.

### Capability Comparison Table
| Criteria | Kafka Streams | Apache Flink |
| :--- | :--- | :--- |
| **Deployment Model** | Embedded Java Library (Microservices) | Distributed Cluster (Job/Task Managers) |
| **Data Sources & Sinks** | Kafka strictly (Requires Kafka Connect for others) | Native connectors for virtually any DB/Storage |
| **Pattern Matching (CEP)** | Weak / Manual implementation | Extremely Strong (Dedicated Flink CEP Library) |
| **Latency** | Milliseconds | Sub-millisecond |
| **Throughput** | High | Extremely High |
| **Exactly Once Semantics** | Supported (Via Kafka Transactions) | Supported (Via Checkpoints) |
| **Operational Complexity** | Very Low (Scales with application pods) | High (Requires dedicated streaming cluster/manager) |
