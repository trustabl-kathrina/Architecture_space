# Stateful Stream Processing

State is what makes stream processing powerful (and difficult). If you are just mapping JSON to JSON, your processing is stateless. If you are doing aggregations, joins, or pattern matching, you need state.

## The Problem with State
In a distributed system, if a worker node crashes, the state stored in its RAM is lost. Therefore, state must be managed, partitioned, and backed up in a fault-tolerant way.

## State Management Architecture (e.g., Apache Flink)
1.  **Local State Backend**: Instead of querying an external database (like Redis) for every event (which would ruin latency), stream processors keep state *locally* on the worker node.
    *   *In-Memory*: Fast, but limited by JVM heap size.
    *   *RocksDB*: An embedded key-value store. It writes state to local disk (SSD), allowing for terabytes of state per node with very low read/write latency.
2.  **State Partitioning**: State is strictly partitioned by key. All events for `user_id=123` are routed to the exact same worker node so it can update its local state.
3.  **Checkpointing (Fault Tolerance)**:
    *   The system periodically injects "checkpoint barriers" into the event stream.
    *   When a worker node receives a barrier, it takes a snapshot of its current local state (e.g., from RocksDB) and writes it asynchronously to durable, distributed storage (like Amazon S3 or HDFS).
    *   It also records the current Kafka offsets.
4.  **Recovery**: If a node dies, a new node is spun up, the state is downloaded from S3 into its local RocksDB, and it resumes reading from Kafka at the exact offsets recorded in the checkpoint.

## Types of State
*   **ValueState**: Stores a single value per key (e.g., current total sum).
*   **ListState**: Stores a list of values per key (e.g., all events in a current window).
*   **MapState**: Stores a map (key-value dictionary) per key.
