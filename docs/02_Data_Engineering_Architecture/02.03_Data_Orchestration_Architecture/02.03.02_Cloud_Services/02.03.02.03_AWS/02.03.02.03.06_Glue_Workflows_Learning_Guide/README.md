---
title: AWS Glue Workflows Learning Guide
section: "02.03.02.03.06"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, glue, etl, learning-guide, orchestration]
canonical: true
---
# AWS Glue Workflows Learning Guide

Structured learning path for architects and engineers orchestrating **Glue-native ETL** — crawlers, Spark jobs, triggers, job bookmarks, and catalog-centric lakehouse pipelines within AWS Glue Workflows.

## Prerequisites

- AWS account with AWS Glue access
- Familiarity with [Glue Workflows Architecture](../02.03.02.03.03_Glue_Workflows_Architecture.md)
- Basic S3 and IAM concepts
- Optional: Glue Studio, Spark, or Data Catalog experience

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](02.03.02.03.06.01_Overview.md) | What Glue Workflows is, vs MWAA/Step Functions |
| 2 | [Architecture](02.03.02.03.06.02_Architecture.md) | Workflows, triggers, jobs, crawlers, catalog |
| 3 | [How to Use](02.03.02.03.06.03_How_To_Use.md) | Create workflow, triggers, run properties, IAM |
| 4 | [Scenarios](02.03.02.03.06.04_Scenarios.md) | Medallion, incremental, conditional promote patterns |
| 5 | [Limitations and Scenarios](02.03.02.03.06.05_Limitations_And_Scenarios.md) | 100-entity limit, scope, mitigations |
| 6 | [Costing](02.03.02.03.06.06_Costing.md) | DPU billing, Flex vs Standard, scenario models |
| 7 | [Production Configuration](02.03.02.03.06.07_Production_Configuration.md) | Concurrency, bookmarks, monitoring, hybrid |
| 8 | [Evaluation Criteria](02.03.02.03.06.08_Evaluation_Criteria.md) | Scorecard vs MWAA, Step Functions, Glue-only fit |
| 9 | [Benchmarking](02.03.02.03.06.09_Benchmarking.md) | Reference workflow profiles |

## Quick links

- [Glue Workflows Architecture](../02.03.02.03.03_Glue_Workflows_Architecture.md)
- [MWAA Learning Guide](../02.03.02.03.04_MWAA_Learning_Guide/README.md)
- [Step Functions Learning Guide](../02.03.02.03.05_Step_Functions_Learning_Guide/README.md)
- [Official documentation](https://docs.aws.amazon.com/glue/latest/dg/workflows_overview.html)
- [Official pricing](https://aws.amazon.com/glue/pricing/)
