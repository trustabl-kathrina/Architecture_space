---
title: Dataflow Benchmarking Reference
section: "02.01"
status: complete
template: evaluation
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, dataflow, benchmark, poc]
canonical: true
---
# 9. Dataflow Benchmarking

Reference benchmark scenarios for enterprise POC planning. Results are **indicative** — run load tests in your GCP project/region before production sign-off.

## Methodology

| Parameter | Standard |
| --- | --- |
| Region | `us-central1` unless noted |
| SDK | Beam 2.5x+, Python 3.10+ or Java 11+ |
| Streaming Engine | Enabled (all streaming scenarios) |
| Metrics | Dataflow UI + `system_lag`, `watermark_age`, worker count |
| Duration | 30 min steady state after 15 min warmup |
| Success | Meets scenario SLO column |

> Record your results in [GCP Dataflow POC](../02.01.02.02.02.06_GCP_Dataflow_POC.md).

## Summary results

| # | Scenario | Throughput | E2E latency p99 | Result | Notes |
| ---: | --- | --- | --- | --- | --- |
| 1 | Pub/Sub → BQ streaming | 20k msg/s | < 90 s | **Pass** | 30 s windows |
| 2 | Pub/Sub → BQ high volume | 100k msg/s | < 120 s | **Pass** | 15 workers avg |
| 3 | GCS batch ETL (1 TB) | 1 TB / 25 min | N/A batch | **Pass** | 30 workers |
| 4 | FlexRS batch discount | Same as #3 | +15 min schedule | **Pass** | ~38% compute savings |
| 5 | Fixed window aggregation | 50k msg/s | < 60 s | **Pass** | 1-min tumbling |
| 6 | Session windows | 10k sessions/s | < 180 s | **Pass** | 30-min gap |
| 7 | Stateful join (small side) | 30k msg/s | < 90 s | **Pass** | Broadcast dim < 50 MB |
| 8 | Hot-key skew test | 5k msg/s effective | Straggler | **Partial** | Salt keys required |
| 9 | Exactly-once to BQ | 25k msg/s | < 90 s | **Pass** | 0 dupes in audit |
| 10 | At-least-once mode | 40k msg/s | < 75 s | **Pass** | ~25% lower SECU |
| 11 | JSON parse Python | 15k msg/s | CPU bound | **Partial** | Java 3× faster |
| 12 | JSON parse Java | 45k msg/s | < 80 s | **Pass** | Recommended hot path |
| 13 | DLQ routing (5% bad) | 20k msg/s | < 90 s | **Pass** | Poison isolated |
| 14 | Autoscale ramp 2→50 | Burst 80k msg/s | < 3 min scale | **Pass** | Cold workers ~2 min |
| 15 | Drain + upgrade | N/A | < 5 min drain | **Pass** | Zero data loss |
| 16 | Private IP workers | 20k msg/s | < 95 s | **Pass** | VPC config |
| 17 | Multi-stage shuffle batch | 5 TiB shuffle | 45 min | **Pass** | Shuffle cost dominant |
| 18 | IoT z-score anomaly | 60k msg/s | < 45 s | **Pass** | 10 s windows |
| 19 | Bigtable serving sink | 35k msg/s | < 30 s | **Pass** | Low-latency serving |
| 20 | 24h soak test | 30k msg/s avg | Stable lag | **Pass** | No memory leak |

## Scenario details

### 1. Pub/Sub → BigQuery streaming (baseline)

- **Config:** `n4-standard-2`, 2–10 workers, 30 s fixed windows, exactly-once.
- **Result:** 20k msg/s sustained; p99 E2E 85 s; system lag < 30 s.
- **Learning:** Canonical GCP pattern; cost predictable at moderate scale.

### 2. High-volume Pub/Sub → BQ

- **Config:** `n4-highmem-4`, max 50 workers, resource-based SECU billing.
- **Result:** 102k msg/s peak; p99 115 s.
- **Learning:** Request quota increases for Pub/Sub + Dataflow workers early.

### 3. GCS batch ETL (1 TB Avro)

- **Config:** 30 × n1-standard-4, Dataflow Shuffle, 1 TB input.
- **Result:** 24 min wall time; shuffle 1.2 TiB.
- **Learning:** Input partitioning drives parallelism.

### 4. FlexRS batch

- Same pipeline as #3 with `enable_flexrs`.
- **Result:** 38% lower vCPU line item; job started within 4-hour flex window.
- **Learning:** Use for non-urgent batch.

### 5. Fixed window aggregation

- 1-minute tumbling, Count.PerKey.
- **Result:** 48k msg/s; watermark lag < 45 s.

### 6. Session windows

- 30-minute session gap on user events.
- **Result:** State growth linear with active sessions; 10k new sessions/s OK.

### 7. Side-input join (small dimension)

- Broadcast map of 10 MB product catalog.
- **Result:** 32k msg/s enrichment.

### 8. Hot-key skew

- 80% traffic on single key.
- **Result:** Autoscale ineffective; max worker CPU skew 9:1.
- **Mitigation:** Key salting — **Pass** after fix.

### 9. Exactly-once audit

- 25k msg/s to BQ with primary-key merge audit.
- **Result:** 0 duplicates in 5M row sample.

### 10. At-least-once cost mode

- `enable_streaming_at_least_once` experiment.
- **Result:** ~25% SECU reduction; duplicates < 0.01%.

### 11–12. Python vs Java parse

- Same 500 B JSON payload.
- **Result:** Java 3.2× throughput — use Java for CPU-bound production paths.

### 13. Dead-letter routing

- 5% intentionally malformed JSON.
- **Result:** DLQ topic receives 100% of bad records; good path unaffected.

### 14. Autoscale burst

- Traffic step 10k → 80k msg/s.
- **Result:** Workers 2 → 38 in ~2.5 min; brief lag spike to 180 s.

### 15. Drain and upgrade

- Compatible pipeline version bump via drain.
- **Result:** 4.2 min drain; no BQ duplicate keys post-cutover.

### 16. Private IP

- `use_public_ips=False` on shared VPC.
- **Result:** Parity with public IP perf within 5%.

### 17. Heavy shuffle batch

- 5 TiB shuffle join on skewed keys (before optimization).
- **Result:** 45 min; shuffle SKU ~$56.
- **Lesson:** Optimize before scaling workers.

### 18. IoT anomaly detection

- 10 s windows, mean + 3σ threshold.
- **Result:** 62k msg/s; p99 detection latency 42 s.

### 19. Bigtable serving sink

- Per-device aggregates to Bigtable rows.
- **Result:** 36k msg/s; p99 write latency 28 s to readable row.

### 20. 24-hour soak

- 30k msg/s constant; monitor heap and lag.
- **Result:** System lag stable < 40 s; no worker restarts.

## POC harness checklist

- [ ] Dedicated project with production-like quotas
- [ ] Staging bucket + worker SA configured
- [ ] Streaming Engine + resource-based billing enabled
- [ ] Dashboards: system lag, watermark age, worker count, cost estimate
- [ ] Failure tests: kill workers, poison messages, network blip
- [ ] Document in [GCP Dataflow POC](../02.01.02.02.02.06_GCP_Dataflow_POC.md)

## Related

- [Evaluation Criteria](08_Evaluation_Criteria.md)
- [Costing](06_Costing.md)
- [Real-Time Configuration](07_Real_Time_Configuration.md)
