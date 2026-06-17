# Spark Structured Streaming

Spark Structured Streaming is a stream processing engine built on the Spark SQL engine. It allows you to express streaming computations the same way you express batch computations on static data.

## Micro-Batch Architecture
Unlike Flink, Spark Structured Streaming (traditionally) processes data in **micro-batches**.
1.  The engine polls the source (e.g., Kafka) at a configurable interval (trigger interval).
2.  It processes the newly arrived data as a small, bounded DataFrame using the Spark SQL engine.
3.  It updates the result table and writes it to the sink.
*   *Latency*: Typically in the hundreds of milliseconds to seconds. Not suitable for ultra-low latency requirements (like HFT), but perfectly fine for 95% of enterprise ETL.

*(Note: Spark introduced "Continuous Processing" mode for sub-millisecond latency, but it has limitations compared to Flink).*

## Key Advantages
1.  **Unified API**: The exact same DataFrame/SQL code can be used to run a daily batch job or a 24/7 streaming job. This drastically reduces code duplication.
2.  **Ecosystem Integration**: Seamless integration with the rest of the Spark ecosystem (Delta Lake, MLlib). It is the premier engine for Lakehouse architectures.
3.  **Simplicity**: Very easy to pick up for data engineers already familiar with PySpark or Spark SQL.

## State Management
State (for aggregations, joins, windowing) is maintained across micro-batches using a Write-Ahead Log (WAL) and state store backed by HDFS/S3. It guarantees end-to-end exactly-once semantics.

## Performance Tuning
*   **Trigger Intervals**: Fine-tune the trigger interval. Using `Trigger.ProcessingTime("0 seconds")` executes micro-batches as fast as possible, but slightly longer triggers (e.g., "5 seconds") can dramatically improve throughput by creating larger, more efficient Parquet/Delta writes.
*   **Shuffle Partitions**: By default, `spark.sql.shuffle.partitions` is 200. For small streaming jobs, this causes massive overhead. Reduce this number to match the actual number of executor cores (e.g., 16 or 32) to prevent task scheduling delays.
*   **Asynchronous Checkpointing**: Ensure checkpointing to S3/HDFS is optimized (e.g., using fast committer APIs) to prevent the micro-batch loop from blocking while waiting for state writes to complete.
