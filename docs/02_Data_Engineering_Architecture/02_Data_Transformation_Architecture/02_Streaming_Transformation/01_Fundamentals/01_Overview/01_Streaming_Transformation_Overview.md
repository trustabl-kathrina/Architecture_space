---
title: Streaming Transformation Overview
section: "02.02.02.01.01.01"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [streaming]
canonical: true
---

# Streaming Transformation Overview

**Streaming transformation** applies business logic to unbounded event streams with **low latency** - filtering, enrichment, windowed aggregation, and CDC merge into silver/gold tables.

## Event-time vs processing-time


| Semantics           | Use                                             |
| ------------------- | ----------------------------------------------- |
| **Event time**      | Correct analytics with watermarks (Flink, Beam) |
| **Processing time** | Approximate dashboards, lower latency           |
| **Ingestion time**  | Audit trails only                               |


See [Top 10 Streaming Technologies](../../03_Open_Source/01_Overview/01_Top_10_Streaming_Transformation_Technologies.md).