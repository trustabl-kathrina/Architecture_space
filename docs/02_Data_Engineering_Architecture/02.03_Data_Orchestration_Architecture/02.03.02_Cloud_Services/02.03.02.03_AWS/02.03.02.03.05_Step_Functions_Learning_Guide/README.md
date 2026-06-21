---
title: AWS Step Functions Learning Guide
section: "02.03.02.03.05"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, step-functions, serverless, learning-guide, orchestration]
canonical: true
---
# AWS Step Functions Learning Guide

Structured learning path for architects and engineers implementing **serverless orchestration** with AWS Step Functions — state machines for Lambda/Glue chains, event-driven glue, and lightweight pipeline coordination.

## Prerequisites

- AWS account with Step Functions access
- Familiarity with [Step Functions Architecture](../02.03.02.03.02_Step_Functions_Architecture.md)
- Basic IAM and JSON/YAML
- Optional: EventBridge, Lambda, or Glue experience

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](02.03.02.03.05.01_Overview.md) | What Step Functions is, Standard vs Express, vs MWAA |
| 2 | [Architecture](02.03.02.03.05.02_Architecture.md) | State machines, executions, ASL, integrations |
| 3 | [How to Use](02.03.02.03.05.03_How_To_Use.md) | Author ASL, deploy, invoke, IAM |
| 4 | [Scenarios](02.03.02.03.05.04_Scenarios.md) | Event-driven and data pipeline patterns |
| 5 | [Limitations and Scenarios](02.03.02.03.05.05_Limitations_And_Scenarios.md) | Quotas, payload limits, mitigations |
| 6 | [Costing](02.03.02.03.05.06_Costing.md) | Standard vs Express pricing, scenario models |
| 7 | [Production Configuration](02.03.02.03.05.07_Production_Configuration.md) | Retry, Map, callbacks, EventBridge, monitoring |
| 8 | [Evaluation Criteria](02.03.02.03.05.08_Evaluation_Criteria.md) | Scorecard vs MWAA, Cloud Workflows, Logic Apps |
| 9 | [Benchmarking](02.03.02.03.05.09_Benchmarking.md) | Reference execution profiles |

## Quick links

- [Step Functions Architecture](../02.03.02.03.02_Step_Functions_Architecture.md)
- [MWAA Learning Guide](../02.03.02.03.04_MWAA_Learning_Guide/README.md)
- [Glue Workflows Learning Guide](../02.03.02.03.06_Glue_Workflows_Learning_Guide/README.md)
- [Cloud Workflows Learning Guide](../../02.03.02.02_GCP/02.03.02.02.04_Cloud_Workflows_Learning_Guide/README.md)
- [Official documentation](https://docs.aws.amazon.com/step-functions/)
- [Official pricing](https://aws.amazon.com/step-functions/pricing/)
