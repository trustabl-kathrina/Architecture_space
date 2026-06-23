---
title: Amazon MWAA Limitations and Mitigations
section: "02.03.02.03.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, mwaa, limitations]
canonical: true
---
# 5. Limitations and Mitigation Scenarios

## Platform limits (summary)

Source: [MWAA quotas](https://docs.aws.amazon.com/mwaa/latest/userguide/quotas.html) — verify current values.

| Limit | Typical impact | Mitigation |
| --- | --- | --- |
| **Environment class ceiling** | Max workers/DAGs bounded | Upgrade class or split environments |
| **Cannot pause environment** | 24/7 baseline cost | Dev/staging consolidation; Step Functions for sparse jobs |
| **DAG import time** | Scheduler blocked | Lazy imports; reduce top-level code |
| **requirements.txt install** | Environment update downtime | Pin deps; test in CI; schedule updates |
| **Private webserver access** | Ops friction | VPN/SSO; CLI token for API |
| **Custom Airflow config** | Some knobs read-only | Use supported `airflow-configuration-options` |
| **Worker slot exhaustion** | Queue backlog | Increase max workers; deferrable operators; pools |

## Limitation → mitigation

| Limitation | Scenario | Mitigation |
| --- | --- | --- |
| No stop/start for cost save | Dev runs 1×/day | Shared dev MWAA or local Astro/MiniStack |
| Slow plugin deploy | Large plugins.zip | Minimize plugins; containerized tasks via EKS pod operator |
| RDS metadata growth | Years of task history | Airflow DB cleanup; retention policies |
| Cross-region DAG | Multi-region DR | S3 replication + secondary MWAA runbook |
| Non-AWS operators | Salesforce API | HTTP operator or defer to Step Functions |

## When not to use MWAA

| Situation | Better fit |
| --- | --- |
| Single S3 → Glue chain | **Step Functions** |
| Glue-only 5-job mesh | **Glue Workflows** |
| Sub-minute webhook orchestration | **Express Step Functions** |
| Zero AWS commitment portable K8s | **Airflow on EKS** |

## Risk scenarios

### Scheduler overload (slow DAG bag)

**Symptom:** Missed schedules; high `SchedulerHeartbeat` gaps.  
**Mitigation:** Split DAG repos; reduce import side effects; upgrade environment class.

### Worker autoscale lag during backfill

**Symptom:** Queue depth spikes; SLA miss.  
**Mitigation:** Pre-scale `minWorkers`; cap `max_active_runs`; use pools.

### Secrets in task logs

**Symptom:** Connection strings in CloudWatch.  
**Mitigation:** Secrets Manager backend; mask logs; restrict log access.

## Related

- [Evaluation Criteria](08_Evaluation_Criteria.md)
- [Costing](06_Costing.md)
