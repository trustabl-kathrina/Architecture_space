# Amazon MSK (Managed Streaming for Apache Kafka)

MSK is AWS's fully managed service that makes it easy to build and run applications that use Apache Kafka to process streaming data.

## Core Architecture
*   **Provisioned MSK**: You select the VPC, Subnets, Broker instance types (e.g., `m5.large`), and EBS volume sizes. AWS manages the Zookeeper/KRaft controllers, broker patching, and cluster health.
*   **MSK Serverless**: A cluster type that automatically scales compute and storage resources. You do not manage brokers or instances. You pay per GB ingested/egressed.

## Key Features
*   **Multi-AZ**: Deploys brokers natively across multiple Availability Zones for high availability.
*   **Tiered Storage**: Integrates Kafka with Amazon S3. Older data is seamlessly moved to cheap S3 storage but remains transparently queryable by Kafka consumers, allowing for virtually infinite retention without paying for massive EBS volumes.
*   **MSK Connect**: Fully managed Kafka Connect workers to stream data to/from S3, Redshift, OpenSearch, etc., without managing the Connect JVMs.

## When to use MSK over Kinesis?
*   You require the open-source Kafka ecosystem (Kafka Streams, ksqlDB, specific Connectors).
*   You are migrating an existing Kafka workload from on-premise to the cloud without rewriting consumer/producer code.
*   You have massive throughput requirements where provisioned MSK becomes cheaper at scale than Kinesis On-Demand.

## Performance Tuning
*   **Right-Sizing Instance Types**: Unlike serverless options, MSK relies on EC2 instance types. Memory-optimized instances (e.g., `r5` series) are crucial if your consumers frequently read historical data not currently in the OS Page Cache.
*   **EBS Volume Throughput**: Provision GP3 volumes with explicit IOPS and throughput allocations to ensure disk writes never block producer acknowledgments.
*   **Partition Balancing**: Monitor cluster health using Cruise Control to ensure partitions and leaders are evenly distributed across all brokers in the cluster.
