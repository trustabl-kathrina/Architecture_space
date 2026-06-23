---
title: Azure Stream Analytics Limitations And Scenarios
section: "02.02.02.03.07"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [streaming transformation, learning-guide]
canonical: true
---
# 5. Azure Stream Analytics Limitations And Scenarios - Limitations and Anti-Patterns

## Platform quotas (verify current docs)

| Limit | Typical impact |
| --- | --- |
| Max workers / DPUs | Caps throughput |
| API rate limits | Throttles deploy frequency |
| State / shuffle size | OOM or spill |
| Concurrent jobs | Queue latency |

## When **not** to use 02.02.02.03.07 Azure Stream Analytics

- Sub-second complex event processing â†’ dedicated Flink cluster.
- Simple one-table SQL in warehouse â†’ native dbt/SQL only.
- Tiny datasets (< 1 GB) â†’ over-engineering cost.

## Anti-patterns

| Anti-pattern | Why it fails |
| --- | --- |
| Full scan every micro-batch | Cost explosion |
| No checkpoint on stream job | Unrecoverable duplicates |
| Shared prod/dev credentials | Security audit failure |
| Schema drift without contract | Silent data corruption |

## Mitigations

- Partition pruning and incremental reads.
- Right-size trigger interval vs SLA.
- Schema registry + compatibility checks.

## Related

- [Production Configuration](README.md)
