---
title: Scheduling Framework for Batch Transforms
section: "02.02.01.08"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [scheduling, orchestration, batch]
canonical: true
---
# Scheduling Framework for Batch Transforms

## Purpose

Coordinate **when** transform jobs run relative to upstream ingestion completion, downstream SLAs, and resource windows.

## Scheduling models

| Model | Use case |
| --- | --- |
| **Time-based cron** | Daily/hourly medallion layers |
| **Dependency-based** | Run silver after bronze partition lands |
| **Event-triggered** | S3/Lake Formation event starts Glue job |
| **Backfill window** | Historical reprocessing with concurrency cap |

## Integration with orchestrators

Link to [02.03 Data Orchestration](../../03_Data_Orchestration_Architecture/README.md): Airflow ExternalTaskSensor, Glue Workflows triggers, Step Functions EventBridge rules.

## Best practices

- Idempotent job design for safe replays
- max_active_runs=1 for merge-heavy layers
- Separate dev/staging/prod schedules with data isolation
