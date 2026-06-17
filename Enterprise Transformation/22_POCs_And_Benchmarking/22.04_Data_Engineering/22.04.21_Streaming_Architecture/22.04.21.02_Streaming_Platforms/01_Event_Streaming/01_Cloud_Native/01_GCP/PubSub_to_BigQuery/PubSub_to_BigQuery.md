# Pub/Sub to BigQuery Architecture

Historically, ingesting Pub/Sub data into BigQuery required a Dataflow pipeline. GCP now offers native, zero-compute ingestion methods.

## 1. Pub/Sub BigQuery Subscriptions
*   **How it Works**: You create a subscription that writes *directly* to an existing BigQuery table. No Dataflow, no code.
*   **Pros**: Lowest cost, lowest latency, zero operational overhead.
*   **Cons**: Cannot do any transformations, joins, or aggregations before the data lands. You must land the raw JSON/Avro and transform it inside BigQuery using dbt or scheduled queries (ELT pattern).

## 2. BigQuery Storage Write API (Streaming Inserts)
*   If you need custom logic before ingestion, you use Dataflow (or a custom microservice) to read from Pub/Sub and write to BigQuery using the Storage Write API.
*   Provides exactly-once delivery semantics and high throughput.

## Design Recommendation
Default to **Pub/Sub BigQuery Subscriptions** for all raw data landing. If the data requires enrichment (e.g., calling an external API or joining with a Redis cache) *before* it lands in BigQuery to meet strict latency SLAs, use Dataflow.
