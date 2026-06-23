# Real-Time Analytics Architecture

This architecture is focused on serving user-facing dashboards and application analytics with sub-second query latencies on fast-moving data streams.

## Core Components
1.  **Event Source**: Clickstream data, transaction logs, or application metrics (via Kafka or Kinesis).
2.  **Stream Enrichment (Optional)**: Flink or Kafka Streams to join the raw stream with lookup tables (e.g., resolving a `user_id` to a `demographic_segment`) before ingestion.
3.  **Real-Time OLAP Database**:
    *   *Apache Druid, Apache Pinot, or ClickHouse*: These are specialized analytical databases designed specifically to ingest Kafka streams directly and serve highly concurrent, sub-second aggregation queries.
    *   *Rockset* (Alternative): Managed cloud service for real-time analytics.
4.  **Serving Layer**: Custom applications, Apache Superset, or Grafana querying the OLAP DB via SQL or REST APIs.

## Design Principles
*   **Pre-Aggregation vs. On-the-fly**: Real-time OLAP databases excel at ingesting raw streams and building indexes (e.g., bitmap indexes) continuously. Avoid heavy pre-aggregation in Flink if the OLAP database can handle the query latency; this provides more slice-and-dice flexibility at query time.
*   **Lambda within the Database**: Systems like Druid and Pinot inherently manage a Lambda architecture internally. They hold recent streaming data in memory (Real-time nodes) and seamlessly push historical data to deep storage (Historical nodes), answering queries across both transparently.

## Pros & Cons
*   *Pros*: Sub-second query latency on massive datasets, high concurrency (supports thousands of users querying the dashboard simultaneously).
*   *Cons*: High infrastructure cost (requires significant RAM/SSD for the OLAP cluster), complex query languages (though SQL support is improving), difficult to manage joins at scale.
