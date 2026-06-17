# Apache Flink vs. Google Cloud Dataflow

This POC evaluates two of the most powerful stream processing engines: Apache Flink (often self-hosted or managed) and Google Cloud Dataflow (the managed runner for Apache Beam).

## Comparison Scenarios

### Scenario 1: API and Portability
*   **Requirement**: The organization wants to avoid vendor lock-in and run the same streaming code on-premise and in the cloud.
*   **Flink**: Code written in the DataStream API is heavily tied to the Flink ecosystem.
*   **Dataflow (Beam)**: You write code in the Apache Beam SDK. Beam is specifically designed to be runner-agnostic. You can run the exact same Beam code on Google Dataflow, a local Flink cluster, or an AWS Spark cluster.
*   *Winner*: **Dataflow (Apache Beam)**

### Scenario 2: Dynamic Autoscaling and Hot Keys
*   **Requirement**: A streaming pipeline experiences massive, unpredictable traffic spikes where a single "key" (e.g., a viral hashtag) receives 90% of the traffic, causing Data Skew.
*   **Flink**: Uses static hash-based partitioning. If a hot key overwhelms a single TaskManager slot, that node will crash, taking down the job. Fixing it requires manual salting in the code.
*   **Dataflow**: Features "Liquid Sharding". The Dataflow backend detects the straggler worker, dynamically splits the workload for that specific hot key, and redistributes it across available workers mid-flight without code changes.
*   *Winner*: **Dataflow**

### Scenario 3: Granular State Control and Cost
*   **Requirement**: A complex CEP (Complex Event Processing) job runs 24/7, maintaining massive local state with strict sub-millisecond SLAs. The budget is fixed.
*   **Flink**: Provides the absolute lowest level of control over RocksDB state backends, memory management, and timer services. When self-hosted on Kubernetes, compute costs are fixed and predictable regardless of message volume.
*   **Dataflow**: Provides a higher-level abstraction. The "Streaming Engine" moves state off the workers, which is magical but abstracts away low-level tuning. Billing is per-second based on vCPU, RAM, and Streaming Engine data processed, which can become prohibitively expensive for heavy 24/7 continuous workloads.
*   *Winner*: **Flink**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Portability**: Validated by the business requirement to run code across multi-cloud and on-premise environments.
2. **Resilience to Data Skew**: Validated by injecting extreme "Hot Key" traffic spikes to observe node failure vs. dynamic rebalancing.
3. **Cost vs. Control**: Validated against budget constraints and the need for granular memory/state tuning.

### Capability Comparison Table
| Criteria | Apache Flink | Google Cloud Dataflow |
| :--- | :--- | :--- |
| **API Portability** | Low (Tied to Flink ecosystem) | High (Apache Beam is runner-agnostic) |
| **Autoscaling Mechanics** | TaskManager scaling (Requires job restarts) | Liquid Sharding (Dynamic mid-flight split) |
| **State Management** | Deep granular control (Local RocksDB) | Abstracted (Google Streaming Engine) |
| **Cost Model** | Fixed (Instance/Kubernetes based) | Variable (Pay per vCPU/RAM/Data processed) |
| **Latency** | Sub-millisecond (True continuous) | Milliseconds |
| **Throughput** | Extremely High | Extremely High (Auto-scales to meet demand) |
| **Exactly Once Semantics** | Supported (Chandy-Lamport Snapshots) | Supported |
| **Deployment Model** | IaaS (K8s, EMR) or PaaS (KDA) | Serverless PaaS |
| **Operational Complexity** | High (Requires dedicated streaming cluster/manager) | Low (Serverless, handled by Google) |
