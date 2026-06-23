---
title: Dagster Overview
section: "02.03.03.04"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dagster, open-source, assets, top-10, learning-guide, open-source]
canonical: true
---

# 1. Dagster Overview

## What is Dagster?

**Dagster** is an asset-centric orchestrator with software-defined assets, partitions, and built-in lineage. Category: **Open source asset orchestrator**.

## Why Top 10 rank #3?

Ranked in [Top 10 Open Source Orchestration](../01_Overview/01_Top_10_Orchestration_Technologies.md) for adoption in data engineering, OSS community, and production fit â€” **excluding** hyperscaler managed services covered in [Cloud Services](../../02_Cloud_Services/README.md).

## When to use Dagster

| Use whenâ€¦ | Consider alternatives whenâ€¦ |
| --- | --- |
| Open source asset orchestrator matches your platform strategy | Managed cloud-only standard â†’ [Cloud Services](../../02_Cloud_Services/README.md) |
| Team prefers Dagster model | Portable DAG mesh â†’ **Airflow** or **Prefect** |
| Self-host or bring-your-own K8s | Serverless cloud glue only â†’ Step Functions / Workflows in Cloud Services |

## Learning path

Continue to [Architecture](02.03.03.04.01_Architecture.md) or [Scenarios](02.03.03.04.01_Scenarios.md).
## Asset-centric paradigm

Dagster models pipelines as **software-defined assets** (tables, files, ML models) with explicit dependencies. **Jobs** select subsets of assets; **schedules** and **sensors** materialize them on cadence or events.

## Key concepts

| Concept | Meaning |
| --- | --- |
| **Asset** | Persistent data product with lineage |
| **Op / graph** | Lower-level compute (legacy style still supported) |
| **Partition** | Time or dimension slice (daily, region) |
| **Resource** | DB connections, Spark, IO managers |

## Deployment options

**Dagster Cloud** (hybrid or serverless agents) or **open-source Dagster webserver + daemon** with user-managed Postgres.

## Related

- [Top 10 README](../README.md)
- [Dagster hub](../README.md)
