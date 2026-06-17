# Kafka Streams

Kafka Streams is a client library for building applications and microservices where the input and output data are stored in Kafka clusters.

## Core Abstractions
1.  **KStream (Record Stream)**: Represents an unbounded stream of independent events (e.g., financial transactions). Every new record is an *Insert*.
2.  **KTable (Changelog Stream)**: Represents a materialized view of a stream, representing the latest state of a given key (e.g., current account balance). Every new record is an *Upsert* (or *Delete* if the value is null).
3.  **GlobalKTable**: Similar to KTable, but fully replicated to every Kafka Streams instance. Useful for small lookup tables (e.g., zip codes to city names) to avoid network shuffles during joins.

## Architecture
*   **Topology**: A graph of stream processing nodes (Sources, Processors, Sinks).
*   **State Stores**: For stateful operations (joins, windowing, aggregations), Kafka Streams uses local embedded databases (typically RocksDB) backed by internal Kafka changelog topics. If a node dies, the state is restored from the changelog topic on another node.
*   **Task/Partition Mapping**: Kafka Streams scales perfectly with Kafka. It creates one Stream Task per input topic partition.

## Advanced Features
*   **Windowing**: Grouping events by time (Tumbling, Hopping, Sliding, and Session windows).
*   **Exactly-Once Processing (EOS)**: Achieved via Kafka Transactions. Ensures that consuming, processing, and producing outputs happen atomically.
*   **Interactive Queries**: Allows external services to query the local state stores (RocksDB) directly via REST APIs, turning the Kafka Streams application into a distributed, queryable database.

## Performance Tuning
*   **Stream Threads**: Increase `num.stream.threads` up to the number of input partitions. This is the primary way to parallelize processing inside a single JVM instance before needing to scale out to new Kubernetes pods.
*   **Record Caching**: Tune `cache.max.bytes.buffering`. This cache deduplicates updates for the same key *before* writing to the local RocksDB store and the downstream changelog topic. Increasing this size massively reduces disk I/O and network traffic.
*   **Commit Interval**: Adjust `commit.interval.ms`. A higher interval (e.g., 10 seconds) improves throughput by batching state commits, while a lower interval (e.g., 100ms) improves end-to-end latency for downstream consumers.
