# Silver Streaming (Enriched & Cleansed)

The Silver layer transforms raw events into high-quality, validated, and enriched domain entities.

## Processing Steps (The Streaming Job)
A stream processor (Flink, Spark Structured Streaming, Kafka Streams) reads from the Bronze topic and performs:
1.  **Schema Enforcement/Parsing**: Converting raw JSON into strongly-typed Avro/Protobuf objects.
2.  **Deduplication**: Removing duplicate events (if the source has At-Least-Once delivery semantics) using stateful windows.
3.  **Data Quality Validation**: Dropping or routing records with missing critical fields (e.g., `user_id is null`) to a DLQ.
4.  **Enrichment (Stream-Table Joins)**: Joining the fast-moving event stream with slower-moving reference data (e.g., joining a `click_stream` with a Redis cache or a broadcasted Kafka KTable to add `user_demographics`).
5.  **Standardization**: Standardizing dates to UTC, currency to USD, and masking PII data.

## Output
*   The output is published to a "Silver" Kafka Topic (or written to a Silver Delta/Iceberg table).
*   This stream represents clean, enterprise-ready facts (e.g., `cleansed_transactions`). It is often the primary stream exposed as an "Event Product" in a Data Mesh.
