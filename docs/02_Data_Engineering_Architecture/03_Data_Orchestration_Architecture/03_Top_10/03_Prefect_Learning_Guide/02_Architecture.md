---
title: Prefect Architecture
section: "02.03.03.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [prefect, open-source, top-10, learning-guide]
canonical: true
---
# 2. Architecture of Prefect

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Prefect server or Prefect Cloud API — deployments, scheduling, state |
| **Execution plane** | Workers / agents in your VPC pulling work from work pools |

## Core components

| Component | Function |
| --- | --- |
| **Flows & tasks** | Python `@flow` / `@task` with dynamic DAG generation |
| **Deployments** | Versioned flow + schedule + infrastructure block |
| **Work pools & workers** | Route runs to process, Docker, or K8s infrastructure |
| **Blocks** | Reusable config for credentials, clusters, storage |
| **Automations** | Event-driven triggers and notifications |

Prefect 2.x separates **orchestration metadata** (server) from **compute** (your workers), avoiding a monolithic scheduler fleet when using hybrid agents.

## Design principle

**Dynamic workflows** — flows can branch at runtime; failures retry at task granularity without redeploying static DAG files.

## Component map

| Piece | Role |
| --- | --- |
| **API / UI** | Deployments, run history, automations |
| **Orchestration engine** | Schedules, queues, state transitions |
| **Work pools & workers** | Pull model execution on K8s, ECS, processes |
| **Blocks** | Reusable config for storage, secrets, notifications |
| **Artifacts & variables** | Run-scoped metadata and configuration |

Prefect 2.x uses a **transactional orchestration model**—each flow run is tracked with granular task states without a separate metadata schema you operate directly.

## Execution isolation

Workers are ephemeral; heavy compute should still live in Spark/BQ jobs triggered from `@flow` tasks, mirroring the thin-orchestrator pattern.

## Related

- [Apache Airflow](../02_Apache_Airflow_Learning_Guide/README.md)
- [Top 10 README](../README.md)
