---
title: Streaming To Lakehouse
section: "02.01"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [lakehouse, streaming, medallion]
canonical: true
---
# Streaming to Lakehouse

## Pattern

Continuously land curated stream outputs into lakehouse tables (Delta Lake, Iceberg, Hudi) for batch analytics, ML features, and compliance — while keeping Kafka as the real-time system of motion.

## Medallion streaming alignment

| Layer | Stream role | Table type |
| --- | --- | --- |
| Bronze | Raw CDC / events | Append-only, schema-on-read |
| Silver | Cleansed, conformed | Upserts, deduped keys |
| Gold | Aggregates for BI | Materialized metrics |

```mermaid
flowchart LR
  CDC[CDC] --> Kafka
  Kafka --> Flink[Flink_Silver]
  Flink --> Iceberg[Iceberg_Silver]
  Iceberg --> Spark[Batch_Gold]
  Kafka --> RT[Serving_S10]
```

## Design decisions

- **Upsert semantics** — primary keys from CDC; handle out-of-order updates with event time.
- **Compaction** — align Kafka retention with lakehouse time travel requirements.
- **Schema evolution** — backward-compatible Avro/Protobuf in schema registry.
- **Latency SLA** — bronze near-real-time; gold may remain micro-batch.

## Related

- [CDC Overview](../../01_Fundamentals/04_CDC_Architecture/01_CDC_Overview.md)
- [Lakehouse Framework](../../../02_Data_Engineering_Architecture/05_Data_Storage_Architecture/03_Lakehouse/01_Fundamentals/01_Overview/01_Lakehouse_Framework.md)
- [Real-Time Analytics Architecture](../../../08_Analytics_Architecture/10_Real_Time_Analytics_Architecture/05_Streaming_Analytics/Real_Time_Analytics_Architecture.md)
