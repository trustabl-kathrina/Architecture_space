---
title: Temporal Architecture
section: "02.03.03.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [temporal, durable-execution, open-source, top-10, learning-guide]
canonical: true
---
# 2. Architecture of Temporal

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane (Temporal cluster)** | Workflow state, task matching, history, visibility APIs |
| **Execution plane (workers)** | User code: workflows and activities on your infrastructure |

## Core components

| Component | Function |
| --- | --- |
| **Frontend service** | gRPC gateway for clients and workers |
| **History service** | Durable event-sourced workflow state per execution |
| **Matching service** | Routes tasks to available worker pollers |
| **Worker service** | Internal cluster operations |
| **Workers (your apps)** | Host workflow and activity implementations |

Persistence uses Cassandra, Postgres, or MySQL (plus optional Elasticsearch for advanced visibility).

## Data engineering fit

Temporal excels at **long-running, failure-prone coordination**: waiting on external systems, human approval, compensating transactions, and saga-style ELT steps — not replacing Spark for bulk transform.

## Design principle

**Durable execution** — workflow code is replayed from history; activities perform side effects with retries and timeouts.

## Cluster layout

| Part | Role |
| --- | --- |
| **Frontend service** | gRPC API for workers |
| **History service** | Event sourcing per workflow execution |
| **Matching service** | Task queue routing |
| **Worker** | User code polling task queues |

**Temporal Cloud** hosts the control plane; self-hosted uses Cassandra/MySQL/PostgreSQL persistence stores.

## Related

- [AWS Step Functions (managed alternative)](../../02_Cloud_Services/03_AWS/05_Step_Functions_Learning_Guide/README.md)
- [Top 10 README](../README.md)
