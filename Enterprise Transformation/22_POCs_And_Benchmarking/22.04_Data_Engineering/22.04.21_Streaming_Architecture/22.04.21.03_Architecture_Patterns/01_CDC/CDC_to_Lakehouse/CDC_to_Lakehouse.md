# CDC to Lakehouse Architecture

Streaming CDC data directly into an object storage-backed Lakehouse (S3, ADLS, GCS) requires handling UPSERTS efficiently on immutable file systems.

## The Challenge
Object stores (like S3) do not support row-level updates. If a CDC event says "Update User 123", you cannot simply overwrite that row in a CSV or Parquet file.

## The Solution: Open Table Formats
Frameworks like **Apache Hudi**, **Delta Lake**, and **Apache Iceberg** abstract the object store and provide ACID transactional guarantees and row-level UPSERT capabilities.

## Architecture Flow
1.  **Ingest**: Debezium captures CDC events to Kafka.
2.  **Process**: A Spark Structured Streaming or Flink job reads the Kafka topic.
3.  **Merge (Upsert)**: The streaming job uses the table format's API (e.g., Delta's `MERGE INTO` or Hudi's `UPSERT` payload) to apply the changes.
    *   *Copy-on-Write (CoW)*: The engine rewrites the entire Parquet file containing the updated row. (Slower writes, faster reads).
    *   *Merge-on-Read (MoR)*: The engine writes the update to a small row-based delta log. At read time, the base Parquet file and the delta log are merged in memory. (Faster writes, slower reads, requires periodic background compaction).

## Best Practices
*   **Compaction**: Frequently compact small files into larger ones to maintain query performance.
*   **Ordering**: Use the database transaction ID or LSN (Log Sequence Number) provided by Debezium to resolve conflicts if CDC events arrive out of order.
