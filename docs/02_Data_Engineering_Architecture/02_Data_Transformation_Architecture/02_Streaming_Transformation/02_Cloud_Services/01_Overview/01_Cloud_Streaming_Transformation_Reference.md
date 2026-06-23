---
title: Cloud Streaming Transformation Reference Architecture
section: "02.02.02.02.01"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [cloud, streaming]
canonical: true
---
# Cloud Streaming Transformation Reference Architecture

## Purpose

Hyperscaler mapping for **streaming transformation** - stateful compute on managed brokers, writing to lakehouse and real-time serving.

## Matrix

| Capability | GCP | AWS | Azure |
| --- | --- | --- | --- |
| Broker | Pub/Sub | Kinesis/MSK | Event Hubs |
| Processor | Dataflow | Managed Flink/Glue SS | Stream Analytics/Fabric |
| State store | Managed + GCS checkpoints | S3 checkpoints | ADLS checkpoints |
| Lake sink | BigQuery streaming | S3 Delta/Iceberg | OneLake Delta |

## Diagram

``mermaid
flowchart TB
  Broker[Broker] --> Proc[Stream_Processor]
  Proc --> Lake[Lakehouse_Silver]
  Proc --> RT[Real_Time_Serving]
``n
## Related

- [Multi-Cloud Streaming Transforms](../05_Cross_Cloud/01_Multi_Cloud_Streaming_Transform_Patterns.md)
