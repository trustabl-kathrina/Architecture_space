# CDC to Data Warehouse

Replicating operational databases to a Cloud Data Warehouse (Snowflake, BigQuery, Redshift) for analytical querying.

## Architecture Options

### 1. The ELT Approach (Fivetran / Airbyte / dbt)
*   Managed tools (Fivetran, Airbyte) handle the CDC extraction and load the raw CDC events directly into a staging table in the Data Warehouse.
*   Transformation (dbt) runs inside the warehouse to merge the CDC events (`c`, `u`, `d`) into the final target table representing the current state.
*   *Pros*: Extremely easy to set up, minimal infrastructure.
*   *Cons*: Warehouse compute can be expensive for frequent micro-batch merges.

### 2. The Streaming Sink Approach (Kafka Connect)
*   Debezium -> Kafka -> Kafka Connect Snowflake/BigQuery Sink.
*   The Sink connector handles the micro-batching and API calls (e.g., Snowflake Snowpipe, BigQuery Storage Write API).
*   *Pros*: Lower latency, leverages existing Kafka infrastructure.
*   *Cons*: Handling complex schema evolutions and deduplication requires careful tuning of the Sink connector properties.

## Best Practices
*   **Soft Deletes**: In the Data Warehouse, prefer "Soft Deletes" (adding an `is_deleted = true` flag) over hard deletes to preserve historical context for analytics.
*   **SCD Type 2**: Instead of just keeping the latest state, use the CDC stream to build Slowly Changing Dimensions Type 2, tracking the valid `start_date` and `end_date` of every row version.
