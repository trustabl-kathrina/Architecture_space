---
title: NRT Latency Tiers
section: "02.02.03.01.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [latency, nrt, sla]
canonical: true
---
# NRT Latency Tiers

## Tier definitions

| Tier | End-to-end latency | Compute model | Cost profile |
| ---: | --- | --- | --- |
| **Platinum** | 30sâ€“2m | Always-on streaming/micro-batch | Highest |
| **Gold** | 2â€“5m | 1â€“5m trigger, autoscale | Medium-high |
| **Silver** | 5â€“15m | Orchestrated micro-batch | Medium |
| **Bronze** | 15â€“60m | Scheduled batch chunks | Lower |

## Measurement points

```mermaid
flowchart LR
  E[Event_time] --> I[Ingest_lag]
  I --> T[Transform_lag]
  T --> Q[Query_available]
```

Track: **ingest lag** (sourceâ†’bronze), **processing lag** (bronzeâ†’silver), **freshness** (silver max timestamp vs now).

## SLA template

| Dataset | Tier | Max lag | Owner |
| --- | --- | --- | --- |
| orders_silver | Gold | 5 min | Data platform |
| inventory_silver | Silver | 15 min | Supply chain |
| finance_gl | Bronze | 60 min | Finance |

## Right-sizing triggers

- Start at **2Ã- expected ingest burst duration**.
- Reduce interval only when downstream dashboards prove value.
- Use **Flex/preemptible** workers for non-platinum tiers.

## Related

- [Micro-Batch Latency Profiles](../../05_Benchmarks/01_Micro_Batch_Latency_Profiles.md)
