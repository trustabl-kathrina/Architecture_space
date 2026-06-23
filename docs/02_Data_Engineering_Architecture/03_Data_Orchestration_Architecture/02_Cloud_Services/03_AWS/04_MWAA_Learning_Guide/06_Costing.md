---
title: Amazon MWAA Costing
section: "02.03.02.03.04"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, mwaa, finops, costing]
canonical: true
---
# 6. Amazon MWAA Costing

> **Source of truth:** [AWS MWAA pricing](https://aws.amazon.com/managed-workflows-for-apache-airflow/pricing/) — verify rates before budgeting.

## Cost components

| Component | Description |
| --- | --- |
| **Environment hourly fee** | Scheduler + webserver + **1 baseline worker** — runs 24/7 while environment exists |
| **Additional workers** | Autoscale workers beyond baseline — billed per hour while running |
| **Additional schedulers / webservers** | Scaled capacity on larger configs |
| **RDS metadata storage** | Database storage for Airflow metadata — GiB-month |
| **S3** | DAG bucket, logs — standard S3 rates |
| **Fargate task runtime** | Worker compute underlying MWAA workers |
| **Downstream compute** | **Not included** — Glue DPU, EMR, Redshift billed separately |

**Key FinOps insight:** MWAA cannot be paused. You pay for the **environment 24/7**, not per DAG run.

## Environment class pricing (indicative — us-east-1)

| Class | Approx. environment $/hour | Approx. monthly baseline |
| --- | ---: | ---: |
| **mw1.small** | ~$0.49 | ~$353 |
| **mw1.medium** | ~$0.74 | ~$533 |
| **mw1.large** | ~$0.98 | ~$706 |
| **Additional worker (small)** | ~$0.055/hr each | Scales with queue |

Verify current rates on the [pricing page](https://aws.amazon.com/managed-workflows-for-apache-airflow/pricing/).

## Scenario cost models

### Scenario A — Dev environment

| Assumption | Value |
| --- | --- |
| Class | mw1.small |
| Workers | min 1, max 3; avg 1 |
| **Est. monthly MWAA** | **~$350–450** |

**Tip:** Share one dev MWAA across teams; use local Astro for individual DAG dev.

### Scenario B — Production analytics (moderate)

| Assumption | Value |
| --- | --- |
| Class | mw1.medium |
| Workers | min 2, max 10; avg 4 during 4-hour window |
| Schedulers | 2 |
| Daily task instances | ~500 |
| **Est. monthly MWAA** | **~$600–1,200** + Glue/EMR |
| **Downstream Glue** | Often **dominates** total cost |

### Scenario C — Enterprise many-DAG platform

| Assumption | Value |
| --- | --- |
| Class | mw1.large or xlarge |
| Workers | max 25+ |
| DAG count | 300+ |
| **Est. monthly MWAA** | **$2,000–8,000+** |
| **Mitigation** | Domain-split environments; aggressive pools |

### Scenario D — MWAA vs Step Functions (sparse glue)

| Pattern | 1M executions/month × 8 transitions | Notes |
| --- | --- | --- |
| Step Functions Standard | ~$200 transitions (after free tier) | No idle cost |
| MWAA (mw1.small 24/7) | **~$353+ baseline** even if idle | MWAA wins on complex DAG ops |

Use **Step Functions for sparse glue**, **MWAA for dense batch**.

## Cost optimization checklist

1. **Right-size environment class** — don't use large for dev.
2. **Cap `maxWorkers`** — prevent runaway autoscale during backfill.
3. **Consolidate dev/staging** — one non-prod environment where policy allows.
4. **Deferrable operators** — free worker slots during long waits.
5. **Offload compute** — Glue/EMR instead of heavy Python on worker.
6. **Metadata cleanup** — Airflow DB retention policies.
7. **Tag environments** — `domain`, `cost_center` for chargeback.

## Related

- [Benchmarking](09_Benchmarking.md)
- [Step Functions Costing](../05_Step_Functions_Learning_Guide/06_Costing.md)
- [Cloud Composer Costing](../../02_GCP/03_Cloud_Composer_Learning_Guide/06_Costing.md)
