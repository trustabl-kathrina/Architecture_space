---
title: Amazon MWAA Benchmarking
section: "02.03.02.03.04"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, mwaa, benchmarking]
canonical: true
---
# 9. Amazon MWAA Benchmarking

Reference profiles for **load testing and environment sizing** before production.

## Methodology

1. Deploy MWAA to **staging** with production-like class.
2. Synthetic DAGs with controlled task count and duration.
3. Measure: queue depth, worker utilization, schedule delay, parse time.
4. Compare against [Costing](06_Costing.md) model.

## Reference scenarios

| ID | Profile | Tasks/run | Volume | Measure |
| ---: | --- | ---: | ---: | --- |
| M1 | EmptyOperator baseline | 10 | 100 runs/day | Scheduler overhead |
| M2 | Glue job wait | 1 Glue (30 min) | 24/day | Worker slot hold |
| M3 | Parallel 50 tasks | 50 | 1 run/day | Autoscale ramp time |
| M4 | Dynamic task map 200 | 200 | 1/day | maxWorkers stress |
| M5 | DAG bag 100 files | parse only | continuous | Scheduler heartbeat |
| M6 | Backfill 90 days | 1 task/day × 90 | once | Queue + cost spike |
| M7 | Sensor-heavy DAG | 5 sensors | hourly | Worker waste |
| M8 | Requirements heavy | import test | deploy | Environment update time |

## Expected outcomes (indicative)

| Profile | Success criteria | Risk signal |
| --- | --- | --- |
| M3 | Queue clears &lt; 15 min | maxWorkers hit 30+ min |
| M5 | Parse &lt; 60 s total | Missed schedules |
| M6 | Complete within SLA window | RDS storage spike |
| M7 | Consider deferrable sensors | Workers idle polling |

## Anti-patterns in benchmarks

- **M4 without cap** — exposes need for pools and Glue offload.
- **M7 external sensors** — benchmark should drive Dataset or object existence checks instead.

## Related

- [Production Configuration](07_Production_Configuration.md)
- [Cloud Composer Benchmarking](../../02_GCP/03_Cloud_Composer_Learning_Guide/09_Benchmarking.md)
