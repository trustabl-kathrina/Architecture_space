---
title: Real Time Analytics Architecture
section: "08.10"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [real-time, analytics, olap]
canonical: true
---
# Real-Time Analytics Architecture

## Definition

Real-time analytics architecture delivers sub-second query and dashboard results on continuously arriving data. It sits **downstream** of stream processing (02.07) and focuses on **serving engines** — not event transport or transformation.

## Boundary with 02.01.02

| Layer | Section | Responsibility |
| --- | --- | --- |
| Ingest & process | 02.01.02 | Events, CDC, stream processors, watermarks |
| Serve & query | 08.10 | OLAP stores, materialized views, low-latency APIs |

## Reference stack

```mermaid
flowchart LR
  subgraph sec20102 [02.01.02]
    Kafka[Kafka_or_PubSub]
    Flink[Flink_or_Dataflow]
  end
  subgraph sec0810 [08.10]
    Pinot[Pinot_or_ClickHouse]
    API[Serving_API]
  end
  Kafka --> Flink --> Pinot --> API
```

## Related

- [08.10 README](../../README.md)
- [Streaming to Lakehouse](../../02_Data_Engineering_Architecture/01_Data_Ingestion_Architecture/02_Streaming/04_Architecture_Patterns/05_Reference_Architectures/03_Streaming_To_Lakehouse.md)
- [ClickHouse](../08.10.01_ClickHouse/README.md)
