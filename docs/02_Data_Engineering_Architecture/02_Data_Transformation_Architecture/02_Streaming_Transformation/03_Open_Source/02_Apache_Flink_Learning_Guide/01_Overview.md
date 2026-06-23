---
title: Apache Flink Overview
section: "02.02.02.03.02"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [flink, streaming, top-10]
canonical: true
---
# 1. Apache Flink Overview

## What is Apache Flink?

**Apache Flink** is the leading **stateful stream processing** engine for transformation with event-time semantics, exactly-once checkpoints, and CEP. It powers real-time silver/gold layers, CDC propagation, and stream-table duality via Flink SQL.

## Mental model

```mermaid
flowchart LR
  Kafka[Kafka_Pulsar] --> Flink[Flink_Job]
  State[(RocksDB_State)] --> Flink
  Flink --> Sink[(Iceberg_JDBC_Kafka)]
```

## When to use Flink

| Use Flink when... | Consider alternatives when... |
| --- | --- |
| **Event-time** windows, watermarks, late data | Minute-level micro-batch OK -> Spark Structured Streaming |
| **Stateful** aggregations (sessions, funnel) | Simple filter/map -> Kafka Streams |
| **Exactly-once** end-to-end with Kafka + lake | Managed serverless -> **Dataflow** / **Managed Flink** |
| **SQL + DataStream** unified API | Batch-only TB scans -> Spark |

## Flink vs Spark Streaming vs Kafka Streams

| Engine | Latency | State | Ops complexity |
| --- | --- | --- | --- |
| **Flink** | ms-s | Rich | Medium-High |
| **Spark SS** | s-min | Micro-batch | Medium |
| **Kafka Streams** | ms | Per-app | Lower (library) |
