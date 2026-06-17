# CDC (Change Data Capture) Streaming Architecture

CDC architecture captures row-level changes (Inserts, Updates, Deletes) from transactional databases and streams them to downstream systems with minimal impact on the source database.

## Core Components
1.  **Source Systems**: Operational databases (PostgreSQL, MySQL, Oracle, SQL Server, MongoDB).
2.  **CDC Engine**:
    *   *Debezium*: The industry standard open-source CDC tool. It reads the database transaction logs (e.g., Postgres WAL, MySQL binlog).
    *   *AWS DMS / Google Datastream*: Managed cloud-native alternatives.
3.  **Event Bus**: Kafka (Debezium is built as a Kafka Connect source connector).
4.  **Consumers**:
    *   *Search Index*: Streaming updates to Elasticsearch/OpenSearch.
    *   *Cache Invalidation*: Streaming updates to Redis.
    *   *Data Warehouse/Lakehouse*: Synchronizing replicas via Kafka Connect Sinks (e.g., Snowflake Sink) or Spark Structured Streaming.

## Design Principles
*   **Log-Based Over Query-Based**: Always prefer reading database transaction logs over polling with `SELECT * FROM table WHERE updated_at > X`. Log-based CDC captures hard deletes and does not load the source database CPU.
*   **Schema Evolution Handling**: Source database schemas change. The CDC architecture must use a Schema Registry to handle `ALTER TABLE` events gracefully, ensuring downstream consumers don't break.

## Pros & Cons
*   *Pros*: Minimal impact on source systems, captures every state transition (not just the latest state), enables the Outbox pattern.
*   *Cons*: Complex initial setup, requires deep database permissions (e.g., `REPLICATION` role in Postgres), difficult to manage large snapshots of historical data during initial bootstrapping.
