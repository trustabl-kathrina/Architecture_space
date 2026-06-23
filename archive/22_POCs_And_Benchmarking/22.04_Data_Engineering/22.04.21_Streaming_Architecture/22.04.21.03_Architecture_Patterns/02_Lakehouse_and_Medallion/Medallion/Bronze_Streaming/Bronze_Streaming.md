# Bronze Streaming (Raw Ingestion)

The Bronze layer in a streaming architecture is the entry point. Its primary purpose is highly durable, low-latency buffering.

## Architectural Characteristics
*   **Data Format**: Exactly as received from the source (e.g., nested JSON, raw text, Debezium CDC payload). No structural changes.
*   **Storage**: A Kafka Topic or Pub/Sub subscription with long retention, OR a raw Delta/Iceberg table in object storage.
*   **Processing**: Minimal to none. Just land the data.

## Why keep a Bronze Stream?
*   **Replayability**: If there is a bug in the Silver/Gold stream processing logic, you can rewind the consumer offset on the Bronze Kafka topic and replay the raw data through fixed code.
*   **Audit & Lineage**: Proves exactly what the source system sent at a specific point in time, before any transformations altered it.
*   **Quarantine (DLQ)**: Invalid records that fail schema validation upon arrival are routed to a Dead Letter Queue (a separate Bronze topic) for inspection.
