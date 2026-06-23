---
title: Google Cloud Workflows Learning Guide
section: "02.03.02.02.04"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, workflows, serverless, learning-guide, orchestration]
canonical: true
---
# Google Cloud Workflows Learning Guide

Structured learning path for architects and engineers implementing **serverless orchestration** with Google Cloud Workflows — YAML state machines for API composition, event-driven glue, and lightweight pipeline chains.

## Prerequisites

- GCP project with Workflows API enabled
- Familiarity with [Cloud Workflows Architecture](../02.03.02.02.02_Cloud_Workflows_Architecture.md)
- Basic HTTP/REST and IAM on GCP
- Optional: Eventarc, Cloud Functions, or Cloud Run experience

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](01_Overview.md) | What Workflows is, mental model, vs Composer |
| 2 | [Architecture](02_Architecture.md) | Executions, steps, connectors, concurrency |
| 3 | [How to Use](03_How_To_Use.md) | Author YAML, deploy, invoke, IAM |
| 4 | [Scenarios](04_Scenarios.md) | Event-driven and integration patterns |
| 5 | [Limitations and Scenarios](05_Limitations_And_Scenarios.md) | Quotas, step limits, mitigations |
| 6 | [Costing](06_Costing.md) | Step pricing, free tier, scenario models |
| 7 | [Production Configuration](07_Production_Configuration.md) | Retry, callbacks, Eventarc, monitoring |
| 8 | [Evaluation Criteria](08_Evaluation_Criteria.md) | Scorecard vs Composer, Step Functions |
| 9 | [Benchmarking](09_Benchmarking.md) | Reference execution profiles |

## Quick links

- [Cloud Workflows Architecture](../02.03.02.02.02_Cloud_Workflows_Architecture.md)
- [Cloud Composer Learning Guide](../03_Cloud_Composer_Learning_Guide/README.md)
- [Official documentation](https://cloud.google.com/workflows/docs)
- [Official pricing](https://cloud.google.com/workflows/pricing)
