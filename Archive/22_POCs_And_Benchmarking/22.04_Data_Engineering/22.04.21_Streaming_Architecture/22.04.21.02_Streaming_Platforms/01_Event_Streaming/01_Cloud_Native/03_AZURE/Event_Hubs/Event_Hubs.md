# Azure Event Hubs

Azure Event Hubs is a big data streaming platform and event ingestion service. It can receive and process millions of events per second.

## Core Architecture
*   **Namespaces**: A management container for multiple Event Hubs (topics).
*   **Partitions**: Like Kafka and Kinesis, Event Hubs uses a partitioned consumer model. Events are ordered only within a partition.
*   **Throughput Units (TUs) / Processing Units (PUs)**: The measure of capacity. You scale Event Hubs by increasing TUs (Standard tier) or PUs (Premium/Dedicated tier).
*   **Auto-inflate**: A feature that automatically scales up Throughput Units to meet usage needs, preventing throttling during spikes.

## Key Features
*   **Kafka Compatibility**: Event Hubs provides an Apache Kafka endpoint. Existing Kafka producers and consumers (Java, Python, Go) can talk to Event Hubs just by changing the connection string, without rewriting any code.
*   **Event Hubs Capture**: Automatically captures streaming data and batches it into Azure Blob Storage or Azure Data Lake Storage (ADLS Gen2) in Avro or Parquet format. (Similar to AWS Firehose).
*   **Schema Registry**: Natively integrated schema registry supporting Avro to enforce data quality.

## Performance Tuning
*   **Auto-Inflate**: Always enable Auto-Inflate on standard namespaces to automatically scale up Throughput Units (TUs) during sudden traffic spikes, preventing `ServerBusyException` throttling.
*   **Partition Count**: Set partition counts high during initial creation (e.g., 32+ for high throughput). You cannot easily change partition counts on standard tiers later without creating a new Event Hub.
*   **AMQP Batching**: Ensure producer clients are using the AMQP protocol and `EventDataBatch` classes to compress and group events, minimizing TCP overhead.
