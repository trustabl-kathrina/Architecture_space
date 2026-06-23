---
title: Kestra Architecture
section: "02.03.03.07"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [kestra, open-source, yaml, top-10, learning-guide]
canonical: true
---
# 2. Architecture of Kestra

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane (Kestra server)** | API, scheduler, flow repository, UI, plugin registry |
| **Execution plane (workers)** | Task execution in isolated worker processes or K8s |

## Core components

| Component | Function |
| --- | --- |
| **Server** | REST API, scheduling, flow validation, web UI |
| **Executor / Worker** | Runs task types (Python, SQL, shell, cloud plugins) |
| **Repository** | Postgres (flows, executions, logs, triggers) |
| **Plugins** | 600+ integrations (dbt, Spark, BigQuery, Slack, etc.) |

Flows are **YAML-first** with triggers (cron, webhook, event), inputs, and subflows — appealing to platform teams wanting GitOps and low-code authoring.

## vs Airflow

| Dimension | Kestra | Airflow |
| --- | --- | --- |
| Definition | YAML flows | Python DAGs |
| UI | Built-in flow editor | Graph + admin |
| Plugin model | Declarative tasks | Operators/sensors |

## Design principle

**Declarative orchestration** — version flows in Git; server validates and schedules without redeploying Python packages for every change.

## Related

- [Cloud Workflows (managed YAML alternative)](../../02_Cloud_Services/02_GCP/04_Cloud_Workflows_Learning_Guide/README.md)
- [Top 10 README](../README.md)
