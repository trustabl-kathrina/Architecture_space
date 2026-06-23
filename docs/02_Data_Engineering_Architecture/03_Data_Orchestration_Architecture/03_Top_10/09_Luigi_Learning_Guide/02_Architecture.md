---
title: Luigi Architecture
section: "02.03.03.09"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [luigi, spotify, open-source, top-10, learning-guide]
canonical: true
---
# 2. Architecture of Luigi

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Central scheduler (optional), dependency graph resolution |
| **Execution plane** | Worker processes running `Task.run()` |

## Core components

| Component | Function |
| --- | --- |
| **Task** | Python class with `requires()`, `run()`, `output()` |
| **Target** | Abstraction for outputs (HDFS, S3, local files) — existence drives idempotency |
| **Scheduler** | Web UI + prioritization of pending tasks (luigid) |
| **Worker** | CLI or daemon executing one task at a time per process |

Luigi predates modern orchestrators: **minimal surface area**, no rich operator ecosystem. Dependencies form a DAG via `requires()`; completion is inferred when `output()` targets exist.

## When architecture is enough

Small teams with **file-based pipelines** and simple daily batches — not multi-tenant platforms or complex SLAs.

## Design principle

**Targets as state** — skip work if output already exists; keep tasks idempotent.

## Related

- [Apache Airflow](../02_Apache_Airflow_Learning_Guide/README.md) (successor pattern for most greenfield)
- [Top 10 README](../README.md)
