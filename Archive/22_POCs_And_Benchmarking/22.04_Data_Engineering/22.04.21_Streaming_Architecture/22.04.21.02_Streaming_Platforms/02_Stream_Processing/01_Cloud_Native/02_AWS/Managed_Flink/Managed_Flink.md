# Amazon Managed Service for Apache Flink

Formerly known as **Kinesis Data Analytics (KDA)**, this service allows you to transform and analyze streaming data in real-time using Apache Flink.

## Core Architecture
*   **Serverless Flink**: You write standard Apache Flink code (Java, Scala, Python) and upload the compiled JAR/code to AWS. AWS provisions the underlying compute (KPU - Kinesis Processing Units) and manages the Flink JobManager and TaskManagers automatically.
*   **State Management**: It natively manages RocksDB state and automatically checkpoints state to a hidden Amazon S3 bucket for fault tolerance and exactly-once semantics.
*   **Autoscaling**: Can automatically add or remove KPUs based on CPU utilization and throughput bottlenecks.

## Integration Points
*   **Sources**: Kinesis Data Streams, Amazon MSK.
*   **Sinks**: S3, Redshift, DynamoDB, OpenSearch.
*   **Studio**: Provides a Zeppelin notebook interface for interactive, SQL-based stream processing queries against live data before deploying as a long-running job.

## Why use Managed Flink?
*   You need complex, stateful event processing (windowing, joins, CEP) over streaming data, which AWS Lambda cannot handle natively without external databases.
*   You want the power of Apache Flink without the operational nightmare of managing Kubernetes clusters, Zookeeper, and JobManagers.

## Performance Tuning
*   **KPU Sizing and Parallelism**: Calculate parallel execution based on Kinesis shards (1 KPU per shard is a safe baseline). Set `AutoScalingEnabled` to true, but carefully monitor `CpuUtilization` metrics to prevent thrashing.
*   **RocksDB Configuration**: Tune the embedded RocksDB state backend by adjusting the `ManagedMemoryFraction` to ensure RocksDB has enough RAM for its block cache, preventing it from constantly spilling to disk during heavy windowing operations.
*   **Checkpoint Alignment**: For topologies experiencing backpressure, enable Unaligned Checkpoints to allow checkpoint barriers to overtake queued data, ensuring checkpoints complete successfully without timing out.
