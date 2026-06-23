---
title: Cloud Composer Benchmarking
section: "02.03.02.02.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, composer, benchmarking]
canonical: true
---
# 9. Cloud Composer Benchmarking

Reference scenarios for **sizing and load testing** Composer environments. Run in **staging** before production sign-off.

## Methodology

1. Clone prod DAG structure with **synthetic tasks** (sleep or noop) or representative BQ jobs.
2. Measure: schedule delay, queue time, task duration, worker autoscale lag.
3. Tools: Airflow UI, Cloud Monitoring, custom metrics on `dagrun.duration`.
4. Document environment size, worker min/max, and Airflow version.

## Reference scenarios

| ID | Scenario | Tasks/run | Parallelism | Expected outcome |
| ---: | --- | ---: | ---: | --- |
| B1 | Single linear DAG | 20 | 1 | Baseline duration ≈ sum(task times) |
| B2 | Fan-out 50 tasks | 50 | 50 | Workers scale to min(50, max_workers) |
| B3 | 10 DAGs same cron | 200 total | pooled | Queue if workers &lt; parallel tasks |
| B4 | Long sensor (deferrable) | 5 sensors × 30 min | low worker use | Deferrable frees slots vs classic sensor |
| B5 | BigQuery 100 concurrent | 100 BQ jobs | pool=20 | Throttle to pool; no slot explosion |
| B6 | Backfill 30 days | 30 runs × 10 tasks | max_active_runs=1 | Sequential DAG runs; plan duration |
| B7 | Parse 200 DAG files | — | — | Import completes &lt; 60s target (size-dependent) |
| B8 | Fail/retry storm | 100 tasks fail 2× | — | Retry delay respected; no scheduler crash |

## Sample metrics to capture

| Metric | Target (indicative) |
| --- | --- |
| Schedule delay (cron → first task) | &lt; 30 s |
| Autoscale lag (queue → new worker) | &lt; 3 min |
| P95 task queue time (T0 DAG) | &lt; 2 min |
| DAG run SLA margin | ≥ 15 min before deadline |

Adjust targets per organization SLAs.

## Load test cautions

- Do **not** load test prod — use isolated staging project.
- BigQuery load tests consume **slots** — use reservations or off-peak.
- Backfill tests can **spam metadata DB** — use bounded date ranges.

## Related

- [Production Configuration](07_Production_Configuration.md)
- [Limitations](05_Limitations_And_Scenarios.md)
- [Costing](06_Costing.md)
