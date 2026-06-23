---
title: Metadata Orchestration
section: "02.03.04.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [metadata-driven, orchestration, scheduling]
canonical: true
---
# Metadata Orchestration

## Problem

Time-based cron schedules ignore **data readiness**. Metadata orchestration schedules and prioritizes work from **dataset state** in the catalog - freshness, partitions, quality gates.

## Pattern

```mermaid
flowchart LR
  DS[Dataset_A_updated]
  Cat[Catalog_event]
  Orch[Trigger_downstream_DAG_or_asset]
  DS --> Cat --> Orch
```

## Scheduling modes

| Mode | Description |
| --- | --- |
| **Dataset-triggered** | Airflow Datasets, Dagster asset sensors |
| **Freshness SLA** | Run when upstream SLA met or breach escalates |
| **Quality-gated** | Downstream starts only if quality score ≥ threshold |
| **Cost-aware** | Defer non-critical assets to off-peak via metadata tier |

## Metadata required

- Stable dataset URI / FQN
- Partition keys and last successful partition
- Orchestrator mapping (dag_id, asset key)
- Dependency graph (transitive closure)

## vs time-based cron

| Cron | Metadata-driven |
| --- | --- |
| Simple, predictable | Reactive to actual data arrival |
| May run too early/late | Reduces wasted runs and SLA misses |
| Good for external API windows | Good for internal DAG meshes |

Hybrid: cron **deadline** + metadata **trigger** (run when ready, fail if not ready by deadline).

## Related

- [Active Metadata](../../01_Fundamentals/06_Active_Metadata/01_Active_Metadata.md)
- [Scheduling Patterns](../../01_Fundamentals/03_Core_Concepts/01_Scheduling_Patterns.md)
