# Performance Tuning

Tuning a streaming pipeline is a constant trade-off between **Throughput** and **Latency**.

## Kafka Producer Tuning
*   `batch.size`: The maximum amount of data (in bytes) to batch together before sending to the broker. Increasing this improves throughput and compression.
*   `linger.ms`: The amount of time the producer will wait for the batch to fill up before sending it. 
    *   *High Throughput Setup*: High `batch.size` (e.g., 64KB) + High `linger.ms` (e.g., 20ms).
    *   *Low Latency Setup*: `linger.ms=0` (send immediately).
*   `compression.type`: Use `lz4` or `zstd`. Compressing batches drastically reduces network I/O and disk usage on the broker, at the cost of a slight CPU hit on the producer.

## Kafka Consumer Tuning
*   `fetch.min.bytes`: The minimum amount of data the broker should return. If set high, the broker waits until enough data accumulates (improving throughput, worsening latency).
*   `max.poll.records`: The maximum number of records returned in a single call to `poll()`. Adjust based on how long it takes your application to process a single record to avoid consumer timeouts.

## Stream Processor Tuning (Flink/Spark)
*   **State Backend Tuning (RocksDB)**: Tune RocksDB block cache and write buffer sizes to prevent disk I/O bottlenecks during state access.
*   **Checkpoint Interval**: Frequent checkpoints (e.g., every 1 second) provide lower latency for exactly-once outputs but increase overhead. Less frequent checkpoints (e.g., 1 minute) increase throughput but mean more data must be replayed upon failure.
