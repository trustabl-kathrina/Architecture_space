---
title: Amazon Athena SQL Architecture
section: "02.02.01.02.03.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, athena, sql, learning-guide]
canonical: true
---
# 2. Architecture of Amazon Athena SQL

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Job definitions, scheduling hooks, metadata, IAM |
| **Execution plane** | Distributed workers, shuffle, spill, result materialization |

## Data flow topology

`mermaid
flowchart TB
  Src[(Sources)] --> Stage[Staging]
  Stage --> Transform[Amazon Athena SQL]
  Transform --> Sink[(Target_Store)]
`

## Design principles

1. **Idempotent transforms** - safe replays and backfills.
2. **Schema evolution** - backward-compatible column adds; explicit breaking changes.
3. **Partition pruning** - filter early on date/tenant keys.
4. **Observability** - row counts, null rates, SLA timers emitted per run.

## Related

- [Overview](01_Overview.md)
- [Production Configuration](07_Production_Configuration.md)
