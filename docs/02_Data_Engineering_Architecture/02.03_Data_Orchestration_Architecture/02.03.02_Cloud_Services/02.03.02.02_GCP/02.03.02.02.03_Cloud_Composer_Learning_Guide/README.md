---
title: Google Cloud Composer Learning Guide
section: "02.03.02.02.03"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, composer, airflow, learning-guide, orchestration]
canonical: true
---
# Google Cloud Composer Learning Guide

Structured learning path for architects and engineers implementing batch and micro-batch data pipelines on **Managed Service for Apache Airflow (Cloud Composer)**.

## Prerequisites

- GCP project with Composer API enabled
- Familiarity with [Cloud Composer Architecture](../02.03.02.02.01_Cloud_Composer_Architecture.md)
- Basic [Airflow DAG concepts](../../../../02.03.01_Fundamentals/02.03.01.01_Overview/02.03.01.01.01_What_Is_Data_Orchestration.md)
- Optional: BigQuery, Dataproc, or Cloud Storage pipeline experience

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](02.03.02.02.03.01_Overview.md) | What Composer is, Composer 2 vs 3, when to use |
| 2 | [Architecture](02.03.02.02.03.02_Architecture.md) | Control plane, workers, metadata DB, scaling |
| 3 | [How to Use](02.03.02.02.03.03_How_To_Use.md) | Create environment, deploy DAGs, operators, IAM |
| 4 | [Scenarios](02.03.02.02.03.04_Scenarios.md) | Enterprise batch orchestration patterns |
| 5 | [Limitations and Scenarios](02.03.02.02.03.05_Limitations_And_Scenarios.md) | Quotas, constraints, mitigations |
| 6 | [Costing](02.03.02.02.03.06_Costing.md) | DCU pricing, scenario models, FinOps |
| 7 | [Production Configuration](02.03.02.02.03.07_Production_Configuration.md) | Worker scaling, SLAs, private IP, HA |
| 8 | [Evaluation Criteria](02.03.02.02.03.08_Evaluation_Criteria.md) | Scorecard vs MWAA, Workflows, self-hosted Airflow |
| 9 | [Benchmarking](02.03.02.02.03.09_Benchmarking.md) | Reference load scenarios and sizing |

## Quick links

- [Cloud Composer Architecture](../02.03.02.02.01_Cloud_Composer_Architecture.md)
- [Cloud Workflows Learning Guide](../02.03.02.02.04_Cloud_Workflows_Learning_Guide/README.md)
- [Orchestration Strategy](../../../../02.03.01_Fundamentals/02.03.01.02_Strategy/02.03.01.02.01_Orchestration_Strategy.md)
- [Official documentation](https://cloud.google.com/composer/docs)
- [Official pricing](https://cloud.google.com/composer/pricing)
