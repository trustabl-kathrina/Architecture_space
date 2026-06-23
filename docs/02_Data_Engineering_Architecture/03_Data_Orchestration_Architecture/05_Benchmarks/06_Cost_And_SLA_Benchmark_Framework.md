---
title: Cost and SLA Benchmark Framework
section: "02.03.05.06"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [benchmark, cost, sla]
canonical: true
---
# Cost and SLA Benchmark Framework

## Purpose

Link **orchestration benchmarks** to **FinOps** and **SLA tiers** - control plane cost is often small vs compute, but bad orchestration drives warehouse waste.

## Cost components

| Component | Typical % of total | Benchmark focus |
| --- | ---: | --- |
| Orchestrator control plane | 5-15% | MWAA/Composer hourly, self-host K8s |
| Workers / task compute | 40-70% | Slot-hours, pod-minutes |
| Downstream (Spark, BQ, Snowflake) | 20-50% | Failed retries, over-scheduling |
| Observability / metadata | 5-10% | Log volume, lineage export |

## SLA tier mapping

| Tier | Deadline example | Benchmark requirement |
| --- | --- | --- |
| **T0** | 6 AM finance | p99 schedule delay < 5 min |
| **T1** | Same business day | p99 < 30 min |
| **T2** | Best effort | No hard benchmark |

## Cost benchmark worksheet

| DAG / domain | Runs/month | Avg duration | Retry rate | Warehouse $/run | Orchestration $/run |
| --- | ---: | ---: | ---: | ---: | ---: |
| | | | | | |

**Optimization signals:** retry rate > 5%, nightly overlap causing queue, sensors polling every 60s on idle deps.

## Related

- [SLA Management](../01_Fundamentals/03_Core_Concepts/04_SLA_Management.md)
- [Managed Workflows](../02_Cloud_Services/01_Overview/02_Managed_Workflows.md)