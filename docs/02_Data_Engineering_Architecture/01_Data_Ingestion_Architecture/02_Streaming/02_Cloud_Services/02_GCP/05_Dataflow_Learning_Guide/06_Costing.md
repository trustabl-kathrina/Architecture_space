---
title: Dataflow Costing
section: "02.01"
status: complete
template: evaluation
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, dataflow, finops, costing]
canonical: true
---
# 6. Dataflow Costing

> **Source of truth:** [Google Cloud Dataflow pricing](https://cloud.google.com/dataflow/pricing) — verify rates for your region before budgeting. Figures below use **us-central1** list pricing as of 2026-06.

## Cost components

| Component | Applies to | Billing unit |
| --- | --- | --- |
| Worker vCPU | Batch + streaming | Per vCPU-second (billed as hours) |
| Worker memory | Batch + streaming | Per GiB-second |
| Dataflow Shuffle | Batch | Per GiB shuffled |
| Streaming Engine Compute Units | Streaming (resource-based) | Per SECU |
| Streaming Engine data processed | Streaming (legacy billing) | Per GiB processed |
| Persistent disk | All jobs | Per GB-month on worker disks |
| GPUs | GPU pipelines | Per GPU-hour |
| **Plus** downstream | Pub/Sub, BQ, GCS, egress | Separate SKUs |

Billing is **per second**, priced as hourly rates. Dataflow worker charges **replace** underlying Compute Engine VM line items for managed workers.

## us-central1 reference rates

### Batch workers

| Resource | Standard | FlexRS (~40% discount) |
| --- | ---: | ---: |
| vCPU-hour | $0.056 | $0.0336 |
| GiB-hour | $0.003557 | $0.0021342 |
| Shuffle data processed | $0.011 / GiB | $0.011 / GiB |

Default batch worker: 1 vCPU, 3.25 GiB RAM.

### Streaming workers

| Resource | On-demand | 1-year CUD | 3-year CUD |
| --- | ---: | ---: | ---: |
| vCPU-hour | $0.069 | $0.0552 | $0.0414 |
| GiB-hour | $0.003557 | $0.0028456 | $0.0021342 |
| Streaming Engine (legacy data) | $0.018 / GiB | $0.0144 / GiB | $0.0108 / GiB |
| Streaming Engine Compute Unit | $0.089 / unit | $0.0712 / unit | $0.0534 / unit |

Enable resource-based Streaming Engine billing for production — metered in SECUs aligned to actual shuffle/state usage.

## Cost formula

**Batch job (estimate):**

```
Cost ≈ (vCPU_hours × $0.056) + (GiB_hours × $0.003557) + (shuffle_GiB × $0.011) + disk + egress
```

**Streaming job (monthly estimate):**

```
Cost ≈ Σ_workers [ (vCPU_h × rate) + (GiB_h × rate) ] + SECU_units + Pub/Sub + BQ + transfer
```

Use the [GCP Pricing Calculator](https://cloud.google.com/products/calculator) and Dataflow job **Cost** tab for job-specific estimates.

## Scenario cost models

### Scenario A — Nightly batch ETL (FlexRS)

| Assumption | Value |
| --- | --- |
| Workers | 20 × n1-standard-4 (4 vCPU, 15 GiB) |
| Duration | 45 min/night |
| Shuffle | 500 GiB/night |
| **Nightly compute** | ~20×4×0.75×$0.0336 ≈ $2.02 (FlexRS vCPU) + memory + shuffle |
| **Monthly (~30 runs)** | **~$150–250** |

### Scenario B — Streaming Pub/Sub → BQ (moderate)

| Assumption | Value |
| --- | --- |
| Workers | Autoscale 2–15, avg 8 × n4-standard-2 |
| Uptime | 24/7 |
| Throughput | ~50 MB/s ingest |
| **Monthly vCPU+mem (on-demand)** | ~$800–1,200 |
| **Streaming Engine SECU** | ~$150–300 |
| **Pub/Sub + BQ** | Additional (see Pub/Sub costing guide) |
| **Total Dataflow portion** | **~$1,000–1,500/month** |

### Scenario C — Light streaming (dev/staging)

| Assumption | Value |
| --- | --- |
| Workers | 1–3 avg |
| **Monthly** | **$150–400** |

### Scenario D — Heavy shuffle batch (1 TB join)

| Assumption | Value |
| --- | --- |
| Shuffle | 5 TiB |
| Shuffle cost alone | 5120 GiB × $0.011 ≈ **$56** per run |
| Workers | 50 × 2 hr |
| **Lesson** | Shuffle dominates — optimize join keys early |

### Scenario E — CUD-optimized 24/7 production

| Assumption | Value |
| --- | --- |
| Baseline | 10 workers steady 720 h/month |
| 3-year CUD streaming vCPU | $0.0414/h vs $0.069 |
| **Savings** | ~40% on vCPU line — **$1,200+/year** at scale |

## Optimization levers

1. **Streaming Engine** — always on for streaming.
2. **Resource-based billing** — SECU metering vs legacy GiB processed.
3. **At-least-once mode** — if duplicates acceptable (~20–30% savings possible).
4. **`maxNumWorkers`** — hard FinOps cap.
5. **FlexRS** — batch jobs with flexible schedule.
6. **CUDs** — 1- or 3-year for predictable streaming baseline.
7. **Right-size machine type** — smaller workers with Streaming Engine.
8. **Early filtering** — reduce shuffle and SECU consumption.
9. **Drain + cancel** — stop unused staging jobs promptly.

## Related

- [Pub/Sub Costing](../04_Pub_Sub_Learning_Guide/06_Costing.md)
- [Cost optimization docs](https://cloud.google.com/dataflow/docs/optimize-costs)
- [Benchmarking](09_Benchmarking.md)
