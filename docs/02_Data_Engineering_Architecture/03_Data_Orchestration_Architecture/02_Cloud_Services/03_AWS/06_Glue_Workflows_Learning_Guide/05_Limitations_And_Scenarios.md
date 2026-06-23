---
title: AWS Glue Workflows Limitations and Mitigations
section: "02.03.02.03.06"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, glue, limitations]
canonical: true
---
# 5. Limitations and Mitigation Scenarios

## Platform limits (summary)

Source: [Glue workflow restrictions](https://docs.aws.amazon.com/glue/latest/dg/blueprint_workflow_restrictions.html) and [Glue quotas](https://docs.aws.amazon.com/general/latest/gr/glue.html).

| Limit | Typical impact | Mitigation |
| --- | --- | --- |
| **≤ 100 jobs/crawlers/triggers per workflow** | Resume/stop errors | Split into linked workflows |
| **One starting trigger** | Cannot mix schedule + on-demand start | Separate dev/prod workflows |
| **External job start breaks in-WF triggers** | Downstream never fires | Always start via workflow trigger |
| **EventBridge batch max 100** | Delayed processing | Step Functions or larger batch window |
| **EventBridge window max 900 s** | 15 min batching cap | MWAA sensor or custom buffer |
| **No non-Glue tasks** | No SNS/Lambda native step | Step Functions / MWAA wrapper |
| **Account concurrent job runs** | Throttling (default ~2000) | Job queuing; Flex; stagger schedules |

## Limitation → mitigation

| Limitation | Scenario | Mitigation |
| --- | --- | --- |
| No Airflow-style backfill UI | 90-day reprocess | On-demand runs with run properties loop |
| Limited cross-account | Shared lake | Resource links + LF; per-account workflows |
| Crawler 10-min minimum | Small bucket hourly crawl | Reduce frequency; use partition projection |
| Spark startup latency | Many tiny jobs | Consolidate jobs; Python shell for micro tasks |
| Workflow not portable | Multi-cloud strategy | Document as AWS-native; MWAA for portable layer |

## When not to use Glue Workflows

| Situation | Better fit |
| --- | --- |
| EMR + Glue + Redshift in one DAG | **MWAA** |
| High-rate S3 per-object orchestration | **Step Functions Express** |
| Portable orchestration code | **MWAA** / Prefect |
| Human approval workflows | **Step Functions** callback |

## Risk scenarios

### Bookmark corruption / reset

**Symptom:** Duplicate or missing incremental data.  
**Mitigation:** IAM restrict `ResetJobBookmark`; audit bookmark changes; idempotent writes.

### DPU runaway on backfill

**Symptom:** Cost spike from parallel workflow runs.  
**Mitigation:** `MaxConcurrentRuns=1`; Flex class; account-level concurrency alarms.

### Trigger did not fire

**Symptom:** Job ran manually but silver never started.  
**Mitigation:** Enforce workflow-only starts in prod; CloudWatch alarm on stale catalog partitions.

## Related

- [Evaluation Criteria](08_Evaluation_Criteria.md)
- [Costing](06_Costing.md)
