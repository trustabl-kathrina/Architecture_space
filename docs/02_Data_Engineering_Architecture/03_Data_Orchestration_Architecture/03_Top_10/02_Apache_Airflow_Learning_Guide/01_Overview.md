---
title: Apache Airflow Overview
section: "02.03.03.02"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 1. Apache Airflow Overview

## What is Airflow?

**Apache Airflow** is the de facto open source DAG orchestrator for batch data pipelines. Category: **Open source DAG orchestrator**.

## Why Top 10 rank #1?

Ranked in [Top 10 Open Source Orchestration](../01_Overview/01_Top_10_Orchestration_Technologies.md) for adoption in data engineering, OSS community, and production fit â€” **excluding** hyperscaler managed services covered in [Cloud Services](../../02_Cloud_Services/README.md).

## When to use Airflow

| Use whenâ€¦ | Consider alternatives whenâ€¦ |
| --- | --- |
| Open source DAG orchestrator matches your platform strategy | Managed cloud-only standard â†’ [Cloud Services](../../02_Cloud_Services/README.md) |
| Team prefers Airflow model | Portable DAG mesh â†’ **Airflow** or **Prefect** |
| Self-host or bring-your-own K8s | Serverless cloud glue only â†’ Step Functions / Workflows in Cloud Services |

## Learning path

Continue to [Architecture](02.03.03.02.01_Architecture.md) or [Scenarios](02.03.03.02.01_Scenarios.md).
## Core objects

| Object | Role |
| --- | --- |
| **DAG** | Directed acyclic graph of tasks with schedule and default args |
| **Task / Operator** | Unit of work (`PythonOperator`, provider hooks, deferrable operators) |
| **DagRun** | One logical execution of a DAG for an interval or manual trigger |
| **TaskInstance** | State machine for a single task in one DagRun |

Airflow 2.x centralizes configuration in `airflow.cfg` (or env vars) and uses a **metadata database** (PostgreSQL recommended) for all runtime state.

## Deployment topologies

| Topology | When |
| --- | --- |
| Single-node (SequentialExecutor) | Local dev only |
| CeleryExecutor + Redis/RabbitMQ | Classic multi-worker |
| KubernetesExecutor / CeleryK8s | Elastic workers per task |
| Managed (Composer, MWAA, Astronomer) | Production without patching Airflow itself |

## Ecosystem

**Provider packages** ship integrations (AWS, GCP, Snowflake, dbt, etc.). Prefer providers over raw `BashOperator` curl for idempotency and testability.

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
