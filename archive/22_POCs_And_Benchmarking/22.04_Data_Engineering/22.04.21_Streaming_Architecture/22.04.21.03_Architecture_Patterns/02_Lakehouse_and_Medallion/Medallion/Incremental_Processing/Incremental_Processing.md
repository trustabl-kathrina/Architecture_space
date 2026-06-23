# Incremental Processing

Incremental processing is the core architectural principle that allows streaming systems to be efficient. Instead of recalculating an entire dataset from scratch every hour (batch), the system only processes the *delta* (what has changed since the last execution).

## The State Problem
To calculate an incremental update, the system must know the previous state.
*   *Example*: If the stream sends `{"user_id": 1, "purchase": 50}`, and the goal is to calculate total lifetime value, the system must know the user's previous total.

## Architectural Approaches

### 1. External State Lookups (Anti-Pattern for High Throughput)
*   The stream processor receives an event, pauses, queries an external database (e.g., Postgres or Redis) for the current state, adds the new value, and writes it back.
*   *Drawback*: Network latency for every event destroys throughput.

### 2. Embedded State (The Flink/Kafka Streams Way)
*   The previous state is held in a local embedded database (RocksDB) on the worker node processing the event.
*   The update happens in sub-milliseconds because there is no network call. The framework handles asynchronously backing up this local state to durable storage (S3) via checkpoints.

### 3. Delta Table Merges (The Lakehouse Way)
*   Using Spark Structured Streaming, a micro-batch of new events is processed.
*   Spark uses the `MERGE INTO` SQL command (or equivalent API) to perform an Upsert against the historical Delta table on object storage.
*   This relies on the underlying storage format's ability to efficiently rewrite or append delta files.

## Handling Retractions
In complex topologies (e.g., joining two streams), an update to the upstream data might invalidate a previously emitted downstream result. Modern stream processors (like Flink) handle this by automatically emitting a **Retraction Record** (a `-` minus event) followed by the corrected `+` event, ensuring downstream aggregates remain mathematically correct.
