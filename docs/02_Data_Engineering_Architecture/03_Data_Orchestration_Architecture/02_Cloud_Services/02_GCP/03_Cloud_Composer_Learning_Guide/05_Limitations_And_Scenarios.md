---
title: Cloud Composer Limitations and Mitigations
section: "02.03.02.02.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, composer, limitations]
canonical: true
---
# 5. Limitations and Mitigation Scenarios

## Platform limits (summary)

Source: [Composer quotas](https://cloud.google.com/composer/quotas) and [Airflow limits](https://cloud.google.com/composer/docs/composer-2/airflow-dag-limitations) — verify before production sign-off.

| Limit | Typical impact | Mitigation |
| --- | --- | --- |
| **DAG file count / parse time** | Scheduler delay, import errors | Split DAG bundles; optimize top-level imports; increase environment size |
| **Worker max count** | Parallelism ceiling | Raise max workers; use pools; offload to BQ/Dataproc async jobs |
| **Metadata DB throughput** | Slow UI, task state lag | Larger environment size; reduce task churn; archive old runs |
| **Long task on worker** | Slot exhaustion | Deferrable operators; `DataprocSubmitJobOperator` async pattern |
| **Cross-project networking** | Private IP routing complexity | Shared VPC; PSC; document firewall rules |
| **Upgrade coupling** | Airflow version tied to Composer image | Staging env; test DAG compatibility before prod upgrade |
| **Cost at idle** | Composer 3 still bills control plane + min workers | Lower `worker-min-count` in dev; pause non-prod environments |
| **Not serverless** | Min workers + environment overhead | Use Workflows for sparse micro-orchestration |

## Limitation → scenario → mitigation

| Limitation | Affected scenario | Mitigation |
| --- | --- | --- |
| Worker slot held by sensor | High-frequency external polls | Deferrable sensors; dataset triggers; Eventarc |
| DAG parse timeout | 500+ DAG files | Multiple environments by domain; lazy imports |
| Single-region metadata | DR RPO > 0 | Cross-region env + replicated GCS DAG bucket |
| Airflow UI exposure | Security audit | Private endpoint + IAP; disable public access |
| PyPI dependency conflicts | Mixed domain DAGs | Separate environments or constrained `requirements.txt` |
| BigQuery slot contention | Parallel BQ tasks | Airflow pools; reservation assignment per pool |

## When not to use Composer

| Situation | Better fit |
| --- | --- |
| 3–5 step HTTP glue only | **Cloud Workflows** |
| Sub-minute event fan-out | **Eventarc + Cloud Run** |
| Zero always-on cost requirement | Workflows (pay per step) or Scheduler + Run |
| Full Airflow plugin/kernel control | Self-hosted Airflow on GKE |
| Non-Python orchestration standard | Portable engine on K8s (Dagster/Prefect) |

## Risk scenarios

### Scheduler overload

**Symptom:** DAG runs delayed; queue grows.  
**Mitigation:** Reduce `@once`/`schedule_interval` churn; increase environment size; split schedulers (Composer HA).

### Worker starvation

**Symptom:** Tasks stuck in `queued`.  
**Mitigation:** Increase max workers; reduce long tasks; use priority_weight on T0 DAGs.

### Metadata bloat

**Symptom:** UI timeouts; DB storage growth.  
**Mitigation:** `airflow db clean` policy; reduce retention; archive metadata.

### Upgrade regression

**Symptom:** Deprecated operator breaks DAGs.  
**Mitigation:** Pin image version; CI import test; staged rollout.

## Related

- [Evaluation Criteria](08_Evaluation_Criteria.md)
- [Costing](06_Costing.md)
- [Retry Strategies](../../../../01_Fundamentals/03_Core_Concepts/03_Retry_Strategies.md)
