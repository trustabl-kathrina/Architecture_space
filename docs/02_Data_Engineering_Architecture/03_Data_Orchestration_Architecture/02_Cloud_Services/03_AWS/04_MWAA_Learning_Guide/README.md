---
title: Amazon MWAA Learning Guide
section: "02.03.02.03.04"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, mwaa, airflow, learning-guide, orchestration]
canonical: true
---
# Amazon MWAA Learning Guide

Structured learning path for architects and engineers implementing batch and micro-batch data pipelines on **Amazon Managed Workflows for Apache Airflow (MWAA)**.

## Prerequisites

- AWS account with MWAA access in target region
- Familiarity with [MWAA Architecture](../02.03.02.03.01_MWAA_Architecture.md)
- Basic [Airflow DAG concepts](../../../../01_Fundamentals/01_Overview/01_What_Is_Data_Orchestration.md)
- Optional: S3, Glue, EMR, or Redshift pipeline experience

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](01_Overview.md) | What MWAA is, environment classes, when to use |
| 2 | [Architecture](02_Architecture.md) | Control plane, workers, RDS metadata, scaling |
| 3 | [How to Use](03_How_To_Use.md) | Create environment, deploy DAGs, operators, IAM |
| 4 | [Scenarios](04_Scenarios.md) | Enterprise batch orchestration patterns on AWS |
| 5 | [Limitations and Scenarios](05_Limitations_And_Scenarios.md) | Quotas, constraints, mitigations |
| 6 | [Costing](06_Costing.md) | Environment class pricing, scenario models, FinOps |
| 7 | [Production Configuration](07_Production_Configuration.md) | Worker scaling, SLAs, private webserver, HA |
| 8 | [Evaluation Criteria](08_Evaluation_Criteria.md) | Scorecard vs Step Functions, Composer, self-hosted |
| 9 | [Benchmarking](09_Benchmarking.md) | Reference load scenarios and sizing |

## Quick links

- [MWAA Architecture](../02.03.02.03.01_MWAA_Architecture.md)
- [Glue Workflows Learning Guide](../06_Glue_Workflows_Learning_Guide/README.md)
- [Step Functions Learning Guide](../05_Step_Functions_Learning_Guide/README.md)
- [Cloud Composer Learning Guide](../../02_GCP/03_Cloud_Composer_Learning_Guide/README.md)
- [Official documentation](https://docs.aws.amazon.com/mwaa/)
- [Official pricing](https://aws.amazon.com/managed-workflows-for-apache-airflow/pricing/)
