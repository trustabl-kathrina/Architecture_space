---
title: Cloud Workflows Costing
section: "02.03.02.02.04"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, workflows, finops, costing]
canonical: true
---
# 6. Cloud Workflows Costing

> **Source of truth:** [Google Cloud Workflows pricing](https://cloud.google.com/workflows/pricing) — verify before budgeting.

## Cost components

Workflows charges **only for executed steps** — no idle infrastructure cost.

| Category | Free tier (monthly) | After free tier |
| --- | --- | --- |
| **Internal steps** | First 5,000 | **$0.01** per 1,000 steps (rounded up) |
| **External steps** | First 2,000 | **$0.025** per 1,000 steps (rounded up) |

**What counts as a step:** Every successful step, failed step, and **each retry attempt**.

**External steps:** HTTP calls outside Google APIs / certain connector boundaries (see pricing page for current classification).

## Billing calculation

```
monthly_cost =
  ceil(max(0, internal_steps - 5000) / 1000) * $0.01
+ ceil(max(0, external_steps - 2000) / 1000) * $0.025
```

Plus **downstream** costs (BigQuery, Cloud Run, egress) — not included.

## Step classification examples

| Step | Likely category |
| --- | --- |
| `assign`, `switch` | Internal |
| `googleapis.bigquery.v2.jobs.insert` | Internal (Google connector) |
| `http.post` to `api.salesforce.com` | External |
| Retry of failed external call | External (again) |

## Scenario cost models

### Scenario A — Dev / test

| Assumption | Value |
| --- | --- |
| Executions | 500/month × 8 internal steps |
| Total internal steps | 4,000 |
| **Est. cost** | **$0** (within free tier) |

### Scenario B — File trigger pipeline

| Assumption | Value |
| --- | --- |
| Files | 100,000/month |
| Steps per execution | 12 internal + 2 external |
| Internal | 1.2M → (1.2M - 5K) / 1K × $0.01 ≈ **$11.95** |
| External | 200K → (200K - 2K) / 1K × $0.025 ≈ **$4.95** |
| **Workflows total** | **~$17/month** (+ BQ/Run) |

### Scenario C — Webhook fan-out

| Assumption | Value |
| --- | --- |
| HTTP webhooks | 1M/month |
| Steps | 5 internal + 3 external each |
| Internal | 5M steps ≈ **~$50** |
| External | 3M steps ≈ **~$75** |
| **Total** | **~$125/month** |

### Scenario D — Workflows vs Composer (sparse)

| | Workflows | Composer (min 2 workers) |
| --- | --- | --- |
| 1,000 runs/month × 10 steps | ~$0.05 (after free) | **~$1,500+** environment baseline |
| **Winner** | Sparse / event-driven | Dense daily batch |

## Cost optimization

1. **Merge steps** — combine assigns; avoid noop steps.
2. **Reduce retries** — fix root cause; cap `max_retries`.
3. **Prefer internal connectors** over raw HTTP to Google APIs where cheaper.
4. **Batch events** — one workflow processing many files vs one execution per file when latency allows.
5. **Offload loops** — large `for` iterations multiply steps — use BigQuery or Dataflow for bulk.
6. **Monitor step count** per execution in metrics.

## Related

- [Benchmarking](09_Benchmarking.md)
- [Composer Costing](../03_Cloud_Composer_Learning_Guide/06_Costing.md)
