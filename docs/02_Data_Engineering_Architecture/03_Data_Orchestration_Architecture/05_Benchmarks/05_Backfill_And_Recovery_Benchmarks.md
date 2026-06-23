---
title: Backfill and Recovery Benchmarks
section: "02.03.05.05"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [benchmark, backfill, recovery]
canonical: true
---
# Backfill and Recovery Benchmarks

## Context

**Backfills** stress orchestrators differently from steady-state: thousands of historical task instances, pool contention, warehouse cost.

## Backfill benchmark (Profile P6)

| Parameter | Example |
| --- | --- |
| Partitions | 90 daily |
| Tasks per partition | 20 |
| Total task instances | 1,800 |
| Pool | `backfill` slot limit 25 |

| Metric | Measure |
| --- | --- |
| Wall-clock duration | Start to last success |
| Warehouse cost | Credits/$ during backfill |
| Failure rate | Retries, dead letter |
| SLA impact | T0 DAG delay if shared pools |

## Recovery benchmarks

| Scenario | RTO target | Measure |
| --- | --- | --- |
| Scheduler failover | < 5 min | Time to resume scheduling |
| Metadata DB restore | < 1 h | From backup |
| Region DR | < 4 h | Secondary orchestrator + DAG sync |
| Corrupted DAG rollback | < 15 min | Git revert + sync |

## Best practices

- Dedicated **backfill pool** with lower priority than T0
- `max_active_runs=1` on backfill DAG variants
- Cost cap alerts on warehouse during backfill

## Related

- [Scheduling Patterns](../01_Fundamentals/03_Core_Concepts/01_Scheduling_Patterns.md)
- [Retry Strategies](../01_Fundamentals/03_Core_Concepts/03_Retry_Strategies.md)