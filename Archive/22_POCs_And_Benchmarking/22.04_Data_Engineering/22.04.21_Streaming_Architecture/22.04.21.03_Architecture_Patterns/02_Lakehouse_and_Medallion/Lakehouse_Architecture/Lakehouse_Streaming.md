# Lakehouse Streaming Architecture

The Lakehouse streaming architecture unifies batch and streaming paradigms directly on top of cheap object storage (S3/GCS/ADLS) using open table formats.

## Core Components
1.  **Event Bus**: Kafka or Kinesis buffer events to decouple producers from the lake.
2.  **Streaming Ingestion Engine**:
    *   *Apache Spark Structured Streaming*: Continuous or micro-batch ingestion.
    *   *Fivetran / Airbyte*: Managed CDC to Lakehouse.
3.  **Open Table Formats**:
    *   *Delta Lake*: Native streaming support with ACID transactions. Features like `readStream` and `writeStream` make Delta tables act like message queues.
    *   *Apache Hudi / Apache Iceberg*: Support for upserts (merge) and streaming reads.
4.  **Processing (The Medallion Architecture)**
    *   **Bronze**: Raw, append-only stream of JSON/Avro records landing in Delta/Iceberg.
    *   **Silver**: Streaming jobs read from Bronze, deduplicate, filter, and join with reference data. (Upserts applied here).
    *   **Gold**: Aggregated, business-level tables updated incrementally (e.g., using Delta Live Tables or dbt).

## Design Principles
*   **Storage Compute Separation**: Compute (Spark/Trino) scales independently from storage (Object Store).
*   **Unified API**: Use the same DataFrame API for historical backfills and real-time streaming.

## Pros & Cons
*   *Pros*: Cost-effective (uses object storage instead of expensive data warehouses), eliminates the Lambda architecture complexity, avoids vendor lock-in on compute engines.
*   *Cons*: "Real-time" is usually micro-batch (seconds to minutes of latency) rather than sub-millisecond; managing compaction and vacuuming of small files is critical and requires operational overhead.
