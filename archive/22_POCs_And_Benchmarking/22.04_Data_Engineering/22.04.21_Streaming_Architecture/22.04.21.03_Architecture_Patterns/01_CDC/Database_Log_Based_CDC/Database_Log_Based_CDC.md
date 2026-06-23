# Database Log-Based CDC

Log-based CDC is the most robust and performant method for capturing changes from a database. Instead of querying the database tables directly, it reads the database's internal transaction log.

## How it Works
Every ACID-compliant database maintains a transaction log to ensure durability (crash recovery) and enable replication.
*   **PostgreSQL**: Write-Ahead Log (WAL). Uses logical decoding plugins (like `pgoutput` or `wal2json`).
*   **MySQL**: Binary Log (Binlog).
*   **Oracle**: Redo Log (often requires Oracle GoldenGate or XStream/LogMiner).
*   **SQL Server**: Transaction Log (requires enabling CDC on the database and tables, which creates capture instances).

## Advantages over Query-Based CDC
*   **No Polling Overhead**: Does not execute `SELECT` queries, preserving database CPU and I/O for operational workloads.
*   **Captures Deletes**: Query-based CDC cannot capture hard deletes (because the row is gone). Log-based CDC captures the `DELETE` event.
*   **Captures Every State Change**: If a row is updated twice between polling intervals, query-based CDC only sees the final state. Log-based CDC captures both intermediate updates.

## Challenges
*   **Complexity**: Requires DBA privileges to configure logical replication roles and manage log retention.
*   **Log Retention**: If the CDC consumer goes offline, the database cannot delete its transaction logs. This can cause the database disk to fill up, potentially causing an outage. (Requires careful monitoring of replication slots).
