# Exactly-Once Semantics (EOS)

Message delivery guarantees define how an event broker and stream processor handle failures, retries, and state consistency.

## Delivery Guarantees
1.  **At-Most-Once**: Messages may be lost, but never redelivered. Used for high-throughput, loss-tolerant telemetry. (Fire and forget).
2.  **At-Least-Once**: Messages are never lost, but may be redelivered in case of a crash or timeout. Consumers must be **idempotent** to handle duplicate messages safely without data corruption.
3.  **Exactly-Once (Effectively-Once)**: Messages are guaranteed to be processed successfully exactly once, even in the event of failures. This is the holy grail of stream processing, specifically for financial or transactional systems.

## How EOS is Achieved (Architectural Mechanisms)
*   **Idempotence**: A producer assigns sequence numbers to messages. The broker deduplicates retries based on the producer ID and sequence number. Consumers can also use database primary keys to ensure that saving the same event twice simply overwrites it.
*   **Transactional Messaging**: (e.g., Kafka Transactions). Allows a producer to write to multiple partitions atomically. Either all messages are written successfully, or none are visible to consumers.
*   **Distributed Snapshots (Chandy-Lamport)**: Frameworks like Apache Flink use the Chandy-Lamport algorithm to inject asynchronous barriers into the stream, taking consistent snapshots of distributed state and offset positions. Upon failure, the system rolls back the state and the Kafka consumer offsets to the exact same barrier.
*   **Two-Phase Commit (2PC)**: Often used between stream processors and external sinks (like an RDBMS) to ensure that the processing state and the output commit are atomic.

## The End-to-End Exactly-Once Challenge
True Exactly-Once Semantics require support across the entire pipeline: 
1. The **Source** must be replayable (e.g., Kafka).
2. The **Processor** must guarantee state consistency (e.g., Flink Checkpoints).
3. The **Sink** must participate in transactions or support idempotent UPSERTs. If the sink is a simple REST API or an append-only file system, End-to-End EOS is impossible.

## The Trade-off
Exactly-once semantics incur a performance penalty (increased latency and lower throughput) due to transaction coordination, distributed locking, and checkpointing overhead. As an architect, default to At-Least-Once with idempotent consumers unless the business logic strictly mandates EOS.
