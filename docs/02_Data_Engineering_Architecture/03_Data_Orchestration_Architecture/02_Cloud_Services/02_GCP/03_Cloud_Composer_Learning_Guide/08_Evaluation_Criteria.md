---
title: Cloud Composer Evaluation Criteria
section: "02.03.02.02.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, composer, evaluation]
canonical: true
---
# 8. Cloud Composer Evaluation Criteria

Scorecard for comparing **Cloud Composer** against **Cloud Workflows**, **AWS MWAA**, and **self-hosted Airflow on GKE**.

**Rating scale:** 1 (weak) — 5 (excellent)

## Scorecard

| Criterion | Weight | Composer | Workflows | MWAA | Self-host Airflow |
| --- | ---: | ---: | ---: | ---: | ---: |
| **Batch DAG complexity** | High | 5 | 2 | 5 | 5 |
| **Operational burden** | High | 4 | 5 | 4 | 2 |
| **GCP integration** | High | 5 | 5 | 1 | 4 |
| **Portability** | Medium | 4 | 1 | 4 | 5 |
| **Backfill / time travel** | High | 5 | 2 | 5 | 5 |
| **Lineage / metadata** | Medium | 4 | 2 | 4 | 4 |
| **Cost at low utilization** | Medium | 2 | 5 | 2 | 2 |
| **Cost at high parallel batch** | Medium | 4 | 3 | 4 | 3 |
| **Security (VPC-SC, private)** | High | 5 | 4 | 4 | 4 |
| **Event-driven glue** | Medium | 3 | 5 | 3 | 3 |
| **Team skill fit (Airflow)** | High | 5 | 3 | 5 | 5 |

## Weighted interpretation

| Profile | Lean Composer | Lean Workflows |
| --- | --- | --- |
| GCP data platform, 50+ batch DAGs | **Strong** | Peripheral only |
| Microservice API orchestration | Weak | **Strong** |
| Existing Airflow DAG portfolio | **Strong** | N/A |
| Sparse nightly jobs (&lt; 20 steps total) | Moderate | **Strong** |
| Multi-cloud identical orchestrator | MWAA + Composer parity | Not portable |

## Recommendation framework

```
IF gcp_primary AND batch_dags > 10 AND needs_backfill
THEN Composer = default orchestrator
IF steps < 15 AND event_driven AND no DAG graph
THEN Workflows = default
IF portable_airflow AND aws_primary
THEN MWAA (not Composer)
```

## Related

- [Managed Workflows comparison](../../01_Overview/02_Managed_Workflows.md)
- [Workflows Evaluation](../04_Cloud_Workflows_Learning_Guide/08_Evaluation_Criteria.md)
- [Orchestration Strategy](../../../../01_Fundamentals/02_Strategy/01_Orchestration_Strategy.md)
