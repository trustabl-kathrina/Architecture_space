---
title: Azure Data Factory Costing
section: "02.03.02.04.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [azure, adf, finops, costing]
canonical: true
---
# 6. Azure Data Factory Costing

> **Source of truth:** [Azure Data Factory pricing](https://azure.microsoft.com/pricing/details/data-factory/) — verify rates before budgeting.

## Cost components

| Component | Billing unit | Notes |
| --- | --- | --- |
| **Orchestration** | Per 1,000 activity runs | ~$1 / 1K (Azure IR) |
| **Data movement (Copy)** | DIU-hour | ~$0.25/DIU-hour (Azure IR) |
| **Pipeline activities** | IR hour | ~$0.005/hr (Azure IR) |
| **Mapping data flows** | vCore-hour | Min ~8 vCore cluster; ~$0.18–0.27/vCore-hr |
| **External activities** | Azure-SSIS IR, HDInsight | Varies by compute |
| **SHIR data movement** | Per hour | ~$0.10/hr (different from DIU model) |
| **Operations** | Monitoring/debug | Small fraction of total |

**Key FinOps insight:** ADF is **consumption-based** — no idle factory fee like MWAA. Cost spikes come from **data flow vCores** and **large parallel copies**.

## Billing formula (conceptual)

```
monthly_adf ≈
  (activity_runs / 1000) × orchestration_rate
+ copy_DIU_hours × diu_rate
+ data_flow_vcore_hours × vcore_rate
+ shir_hours × shir_rate (if hybrid)
```

Enable **detailed billing per pipeline** for chargeback ([Microsoft Learn](https://learn.microsoft.com/en-us/azure/data-factory/plan-manage-costs)).

## Scenario cost models

### Scenario A — Dev / test

| Assumption | Value |
| --- | --- |
| Activity runs | 2,000/month |
| Copy | 50 DIU-hours |
| **Est. monthly** | **~$15–25** |

### Scenario B — Daily ingest (copy only)

| Assumption | Value |
| --- | --- |
| Daily copy | 8 DIU × 0.5 hr × 30 = 120 DIU-hr |
| Orchestration | 60 runs/day × 30 = 1,800 runs |
| **Est. monthly** | **~$35–45** (orchestration + DIU) |

### Scenario C — Medallion with mapping data flow

| Assumption | Value |
| --- | --- |
| Data flow | 16 vCore × 1 hr/day × 30 = 480 vCore-hr |
| Copy + orchestration | ~$50 |
| **Est. monthly** | **~$130–180** (data flow dominates) |

### Scenario D — ADF vs MWAA (Azure batch)

| | ADF (consumption) | MWAA equivalent |
| --- | --- | --- |
| Idle orchestration | **~$0** | ~$353+/month baseline |
| Nightly copy + transform | Pay per run | Pay environment + workers |
| **Winner** | Variable batch on Azure | Cross-cloud Airflow portability |

### Scenario E — ADF vs Logic Apps for wait-heavy flow

Long **Wait** activities in ADF bill IR hours — prefer **Logic Apps** for multi-hour human waits ([Microsoft guidance](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview)).

## Cost optimization checklist

1. **Right-size DIU** — benchmark copy; don't default max DIU always.
2. **Replace small data flows** with Synapse SQL or Databricks for micro transforms.
3. **Tumbling window** — avoid redundant full reloads.
4. **SHIR** — right-size VM; scale out nodes not oversized single VM.
5. **Reserved capacity** for predictable data flow vCores (1–3 year).
6. **Tag pipelines** — `domain`, `cost_center` in ARM.
7. **Disable debug sessions** when not in use.

## Related

- [Benchmarking](09_Benchmarking.md)
- [Logic Apps Costing](../04_Logic_Apps_Learning_Guide/06_Costing.md)
