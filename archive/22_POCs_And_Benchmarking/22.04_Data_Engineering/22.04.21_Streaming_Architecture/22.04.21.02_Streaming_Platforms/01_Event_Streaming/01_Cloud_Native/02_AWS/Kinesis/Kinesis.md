# Amazon Kinesis

Amazon Kinesis is a collection of managed services for processing and analyzing streaming data.

## Kinesis Data Streams (KDS)
*   **Concept**: A massively scalable and durable real-time data streaming service.
*   **Architecture**: Unlike GCP Pub/Sub's routing model, KDS uses a **Shard** model (very similar to Kafka Partitions). 
    *   *Provisioned Mode*: You specify the number of shards. Each shard provides 1MB/s input and 2MB/s output.
    *   *On-Demand Mode*: AWS automatically scales the shards up and down based on traffic, though it costs more per gigabyte.
*   **Ordering**: Guaranteed at the shard level (based on Partition Key).

## Kinesis Data Firehose
*   **Concept**: An extract, transform, and load (ETL) service that reliably captures, transforms, and delivers streaming data to data lakes, data stores, and analytics services.
*   **Use Case**: "Zero-code" ingestion from Kinesis Data Streams (or direct API) into Amazon S3, Amazon Redshift, Elasticsearch/OpenSearch, or Snowflake.
*   **Buffering**: It micro-batches data based on size (e.g., 5MB) or time (e.g., 60 seconds) before delivering. It does *not* support true millisecond latency delivery.

## Key Differentiators
*   Deeply integrated with AWS IAM and KMS.
*   KDS supports **Enhanced Fan-Out (EFO)**: Provides dedicated 2MB/s read throughput per consumer per shard, preventing consumers from competing for read bandwidth (a common issue in standard Kinesis).

## Performance Tuning
*   **KPL Aggregation**: Use the Kinesis Producer Library (KPL) to automatically aggregate multiple user records into a single Kinesis record (up to 1MB) to maximize shard utilization.
*   **Enhanced Fan-Out (EFO)**: If multiple consumers are experiencing read throttling (exceeding the shared 2MB/s limit per shard), switch to EFO to provision a dedicated 2MB/s pipe per consumer.
*   **Shard Splitting**: Monitor the `WriteProvisionedThroughputExceeded` metric. If writes are throttling, you must manually (or via a Lambda script) split the "hot" shard to increase total capacity.
