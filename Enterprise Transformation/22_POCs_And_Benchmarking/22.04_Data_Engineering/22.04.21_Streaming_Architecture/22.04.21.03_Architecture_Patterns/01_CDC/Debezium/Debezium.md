# Debezium Architecture

Debezium is an open-source distributed platform for change data capture. It points to your databases, reads the transaction logs, and produces a generic event stream.

## Core Architecture
Debezium is built on top of **Apache Kafka Connect**. It runs as a set of *Source Connectors*.
1.  **Connector Plugins**: Specific implementations for Postgres, MySQL, Oracle, SQL Server, MongoDB, and Cassandra.
2.  **Snapshot Phase**: When Debezium connects to a database for the first time, it takes a consistent snapshot of the selected tables (using `SELECT` with table locks or lock-free MVCC methods) to establish a baseline state.
3.  **Streaming Phase**: After the snapshot, it transitions seamlessly to reading the transaction log from the exact point the snapshot was taken.

## The Debezium Event Payload
Debezium standardizes the event format regardless of the source database. A typical payload contains:
*   `before`: The state of the row *before* the change (null for INSERTS).
*   `after`: The state of the row *after* the change (null for DELETES).
*   `source`: Metadata (database name, table name, transaction ID, LSN - Log Sequence Number).
*   `op`: The operation type (`c` for create, `u` for update, `d` for delete, `r` for read/snapshot).

## Best Practices
*   Use a Schema Registry (Avro/Protobuf) to handle database schema changes. Debezium handles DDL changes gracefully if configured with a registry.
*   Monitor replication lag and connector status continuously.
*   Use Single Message Transforms (SMTs) to unwrap the payload (e.g., `UnwrapFromEnvelope`) if downstream consumers only need the `after` state.
