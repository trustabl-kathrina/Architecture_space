# Kafka-Centric Reference Architecture

A Kafka-centric architecture places Apache Kafka (or Confluent Platform/Cloud) at the absolute center of the enterprise data nervous system.

## Core Components
1.  **Ingestion Layer (Producers)**
    *   *Microservices*: Emitting domain events via Kafka Producer APIs (Java, Go, Python).
    *   *Kafka Connect Source*: Pulling data from legacy systems, RDBMS (via JDBC), and SaaS platforms (e.g., Salesforce).
2.  **Central Nervous System (Broker)**
    *   *Apache Kafka Cluster*: Distributed log storage. Partitions mapped to throughput requirements.
    *   *Schema Registry*: Enforces data contracts (Avro, Protobuf, JSON Schema) to prevent poison pills.
3.  **Stream Processing Layer**
    *   *Kafka Streams (KStreams/KTable)*: Lightweight, embedded library for stateful transformations and stream-stream joins (perfect for Spring Boot/Java shops).
    *   *ksqlDB*: SQL interface over Kafka Streams for rapid prototyping and continuous queries.
4.  **Egress Layer (Consumers)**
    *   *Kafka Connect Sink*: Pushing enriched data to Elasticsearch, Snowflake, or S3.
    *   *Consumer Services*: Microservices reacting to enriched events (e.g., triggering an email).

## Design Principles
*   **Log is the Truth**: Kafka is not just a transient message bus; it is treated as an immutable event store (often with infinite retention for core domain events).
*   **Dumb Pipes, Smart Endpoints**: Kafka just routes bytes. Complex routing and transformation logic lives in the producer/consumer applications.

## Pros & Cons
*   *Pros*: Extremely high throughput, robust ecosystem, strong ecosystem tooling (Confluent), avoids vendor lock-in.
*   *Cons*: Complex to manage self-hosted Zookeeper/KRaft, JVM tuning overhead, steep learning curve.
