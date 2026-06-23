---
title: Scheduler Throughput Profiles
section: "02.03.05.02"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [benchmark, scheduler, airflow]
canonical: true
---
# Scheduler Throughput Profiles

## Context

Scheduler throughput limits how many **task instances** can be created and queued per minute. Bottlenecks: DAG processor, metadata DB write rate, scheduler CPU.

## Indicative reference ranges (self-hosted Airflow 2.x, Celery/K8s)

> Not vendor guarantees - lab-style profiles on 4 vCPU scheduler, Postgres metadata, 10 workers.

| Profile | DAGs | Tasks/run | Task instances/min (peak) | Notes |
| --- | ---: | ---: | ---: | --- |
| P1 Minimal | 1 | 5 | 10 | Baseline |
| P2 Standard | 50 | 750 | 200-500 | Typical mid-size |
| P3 Fan-out | 1 | 500 mapped | 300-800 | Pool limits critical |
| P5 Sensor-heavy | 30 | varies | 50-150 | Sensor stack depth hurts |

## Managed Airflow (Composer / MWAA)

| Factor | Impact |
| --- | --- |
| Environment class | Larger = more scheduler capacity |
| DAG count | Soft limits documented per tier |
| Worker autoscaling | Execution separate from schedule rate |

See [Composer](../02_Cloud_Services/02_GCP/03_Cloud_Composer_Learning_Guide/README.md) and [MWAA](../02_Cloud_Services/03_AWS/04_MWAA_Learning_Guide/README.md) learning guides.

## Tuning levers

| Lever | Effect |
| --- | --- |
| `parallelism` / pools | Cap blast radius |
| DAG consolidation | Fewer files to parse |
| Deferrable operators | Free worker slots |
| Metadata DB tuning | Index `task_instance`, connection pool size |
| Multiple schedulers (HA) | Failover not 2x throughput |

## Related

- [Benchmark Methodology](01_Benchmark_Methodology.md)
- [Worker Concurrency Scaling](04_Worker_Concurrency_Scaling.md)