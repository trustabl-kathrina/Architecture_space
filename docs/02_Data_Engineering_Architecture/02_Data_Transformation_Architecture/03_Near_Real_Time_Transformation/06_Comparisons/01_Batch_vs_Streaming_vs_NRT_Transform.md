---
title: Batch vs Streaming vs NRT Transform
section: "02.02.03.06"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [comparison, nrt]
canonical: true
---
# Batch vs Streaming vs NRT Transformation

| Dimension | Batch | NRT (Micro-batch) | Streaming |
| --- | --- | --- | --- |
| **Latency SLA** | Minutesâ€“hours | 1â€“15 minutes | Sub-secondâ€“seconds |
| **Compute model** | Scheduled job | Triggered micro-batch | Always-on |
| **State** | Minimal | Windowed/checkpoint | Full stateful |
| **Cost** | Lowest per TB | Medium | Highest |
| **Complexity** | Lowest | Medium | Highest |
| **Best examples** | Nightly ELT | Silver MERGE every 5m | Fraud scoring |
| **Engines** | Spark batch, dbt | SS trigger, DLT, Dataflow | Flink, Kafka Streams |

## Decision matrix

```mermaid
flowchart TD
  A[New transform requirement] --> B{Need sub-second?}
  B -->|Yes| S[Streaming]
  B -->|No| C{Need under 15 min?}
  C -->|Yes| N[NRT]
  C -->|No| T[Batch]
```

## Related

- [NRT Strategy](../../01_Fundamentals/01_Strategy/01_NRT_Transformation_Strategy.md)
