---
title: Cloud Composer Costing
section: "02.03.02.02.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, composer, finops, costing]
canonical: true
---
# 6. Cloud Composer Costing

> **Source of truth:** [Google Cloud Composer pricing](https://cloud.google.com/composer/pricing) — verify rates before budgeting; Composer 3 billing is evolving toward BigQuery slot-hour SKUs in some regions.

## Cost components (Composer 3)

| Component | Description |
| --- | --- |
| **Compute (DCU-hours)** | vCPU, memory, storage for schedulers, DAG processors, triggerers, web server, **workers** — workers autoscale |
| **Environment fee** | Size-based (Small/Medium/Large) infrastructure performance tier |
| **Database storage** | Cloud SQL metadata — billed per GiB-month (minimum ~10 GiB, autoscales) |
| **Cloud Storage** | DAG bucket, logs — standard GCS rates |
| **Egress / data transfer** | Cross-region BigQuery, GCS, internet |
| **Downstream compute** | **Not included** — BigQuery, Dataproc, Dataflow billed separately |

**Key FinOps insight:** You pay for **allocated worker capacity over time**, not per task transition. Idle min workers still incur DCU cost.

## Composer 3 pricing model (conceptual)

| SKU area | Billing unit | Notes |
| --- | --- | --- |
| Standard milli DCU-hours | Per 1,000 milli DCU-hour | Scales with worker count and component sizing |
| Environment size | Higher tier = more scheduler/DB headroom | Small → Medium → Large presets |
| Highly resilient environments | Premium multiplier | Extra redundancy for HA requirements |
| DB storage | ~$0.17/GiB-month (verify region) | Grows with task history |

From April 2025+, some regions transition Composer 3 compute billing under **BigQuery Engine for Apache Airflow** (slot-hour based). Check [transition notice](https://cloud.google.com/composer/pricing) for your region.

## Composer 2 (legacy reference)

| Component | Typical SKU |
| --- | --- |
| Environment fee | ~$0.35/hr (small) — scales by size |
| vCPU / memory / storage | Per worker and scheduler hour |
| Database | Same Cloud SQL storage model |

Migrate new workloads to Composer 3.

## Scenario cost models

### Scenario A — Dev environment

| Assumption | Value |
| --- | --- |
| Workers | min 1, max 3; avg 1 worker 8 hr/day |
| DAG activity | Light testing |
| Environment size | Small |
| **Est. monthly** | **~$300–600** (order of magnitude; use calculator) |

**Tip:** Delete or stop dev environments nights/weekends if policy allows.

### Scenario B — Production analytics (moderate)

| Assumption | Value |
| --- | --- |
| Workers | min 2, max 12; avg 4 during 4-hour batch window |
| Schedulers | 2 |
| Environment size | Medium |
| Daily DAG tasks | ~500 task instances |
| **Est. monthly Composer** | **~$1,500–3,500** + BQ/Dataproc |
| **Downstream BQ** | Often **dominates** total cost |

### Scenario C — Enterprise many-DAG platform

| Assumption | Value |
| --- | --- |
| Workers | max 30+; large environment |
| DAG count | 300+ |
| **Est. monthly Composer** | **$5,000–15,000+** |
| **Mitigation** | Domain split across 2 environments; aggressive pool limits |

### Scenario D — Composer vs Workflows for glue

| Pattern | 1M executions/month | Notes |
| --- | --- | --- |
| Workflows (10 steps each) | ~$100 internal steps (after free tier) | No idle cost |
| Composer (always-on min 2 workers) | **Higher baseline** even if idle | Composer wins on complex DAG ops |

Use **Workflows for sparse glue**, **Composer for dense batch**.

## Cost optimization checklist

1. **Right-size `worker-min-count`** — dev=1; prod=2+ for HA only if needed.
2. **Cap `worker-max-count`** — prevent runaway autoscale during backfill.
3. **Off-peak schedules** — stagger T0 DAGs; avoid all-at-midnight.
4. **Deferrable operators** — free worker slots during long waits.
5. **Offload compute** — BQ/Dataproc Serverless instead of heavy Python on worker.
6. **Metadata retention** — clean old task instances.
7. **Committed use discounts** — for predictable baseline DCU (where offered).
8. **Chargeback tags** — label environments `domain`, `cost_center`.

## Related

- [Benchmarking](09_Benchmarking.md)
- [Production Configuration](07_Production_Configuration.md)
- [Pricing calculator](https://cloud.google.com/products/calculator)
