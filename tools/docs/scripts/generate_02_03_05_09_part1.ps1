# Generate 02.03.05-02.03.09 orchestration sections
$OrchRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture"))
$utf8 = New-Object System.Text.UTF8Encoding $false

function FM($title, $section, $template, $tags) {
    return @"
---
title: $title
section: "$section"
status: complete
template: $template
last_reviewed: 2026-06-20
owner: architecture-team
tags: [$tags]
canonical: true
---

"@
}

function Write-Doc($relPath, $title, $section, $template, $tags, $body) {
    $path = Join-Path $OrchRoot $relPath
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllText($path, (FM $title $section $template $tags) + $body.TrimStart(), $utf8)
}

# --- 02.03.05 Benchmarks ---
Write-Doc "02.03.05_Benchmarks\02.03.05.01_Benchmark_Methodology.md" "Orchestration Benchmark Methodology" "02.03.05.01" "evaluation" "benchmark, orchestration, methodology" @'
# Orchestration Benchmark Methodology

## Purpose

Standard method for **benchmarking orchestration platforms** in your environment. Reference profiles below are **indicative** - always re-run in non-prod with your DAG shapes, executor, and metadata DB.

## What to measure

| Dimension | Metrics | Why it matters |
| --- | --- | --- |
| **Control plane** | DAG parse time, scheduler loop duration, queue depth | Scheduling latency at scale |
| **Execution plane** | Task start latency, tasks/sec, worker CPU | Throughput and cost |
| **Reliability** | Success rate under retry storm, recovery time | SLA design |
| **Operational** | Deploy time, upgrade downtime | Day-2 burden |

## Reference load profiles

| ID | Profile | Description |
| ---: | --- | --- |
| **P1** | Minimal | 1 DAG, 5 tasks, daily cron |
| **P2** | Standard ELT | 50 DAGs, avg 15 tasks, 2-level deps |
| **P3** | Wide fan-out | 1 DAG, 500 mapped tasks, K8s executor |
| **P4** | Deep chain | 1 DAG, 100 sequential tasks |
| **P5** | Sensor-heavy | 30 DAGs with external sensors / dataset deps |
| **P6** | Backfill burst | 90-day partition backfill, 2000 task instances |

## Test environment checklist

- [ ] Isolated non-prod cluster matching prod executor type
- [ ] Metadata DB sized like prod (or scaled proportionally)
- [ ] Synthetic tasks (sleep/bash) - not production warehouse load
- [ ] Metrics: scheduler CPU, DB connections, queue length, p50/p99 task delay
- [ ] Document Airflow/Prefect/Dagster version, executor, worker count

## Reporting template

```
Platform: __________  Version: __________  Date: __________
Profile: P__  Executor: __________  Workers: __________

| Metric | Value | Target SLA |
| --- | --- | --- |
| Parse all DAGs (s) | | |
| Schedule delay p99 (s) | | |
| Task queue time p99 (s) | | |
| Successful tasks/hour | | |
| Failed task rate (%) | | |
```

## Related

- [Scheduler Throughput Profiles](02.03.05.02_Scheduler_Throughput_Profiles.md)
- [Top 10 Benchmarking modules](../02.03.03_Top_10/README.md)
'@

Write-Doc "02.03.05_Benchmarks\02.03.05.02_Scheduler_Throughput_Profiles.md" "Scheduler Throughput Profiles" "02.03.05.02" "evaluation" "benchmark, scheduler, airflow" @'
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

See [Composer](../02.03.02_Cloud_Services/02.03.02.02_GCP/02.03.02.02.03_Cloud_Composer_Learning_Guide/README.md) and [MWAA](../02.03.02_Cloud_Services/02.03.02.03_AWS/02.03.02.03.04_MWAA_Learning_Guide/README.md) learning guides.

## Tuning levers

| Lever | Effect |
| --- | --- |
| `parallelism` / pools | Cap blast radius |
| DAG consolidation | Fewer files to parse |
| Deferrable operators | Free worker slots |
| Metadata DB tuning | Index `task_instance`, connection pool size |
| Multiple schedulers (HA) | Failover not 2x throughput |

## Related

- [Benchmark Methodology](02.03.05.01_Benchmark_Methodology.md)
- [Worker Concurrency Scaling](02.03.05.04_Worker_Concurrency_Scaling.md)
'@

Write-Doc "02.03.05_Benchmarks\02.03.05.03_DAG_Parse_And_Deploy_Latency.md" "DAG Parse and Deploy Latency" "02.03.05.03" "evaluation" "benchmark, deploy, ci-cd" @'
# DAG Parse and Deploy Latency

## Context

**Parse time** affects how quickly code changes become schedulable. **Deploy latency** is Git merge to DAG visible in orchestrator.

## Typical measurements

| Stage | Self-hosted Airflow | MWAA/Composer (S3/GCS sync) | Prefect/Dagster deploy |
| --- | --- | --- | --- |
| CI parse + test | 1-5 min | 1-5 min | 1-3 min |
| Artifact sync | 10-60 s (git-sync) | 30 s - 3 min | 10-30 s API |
| Scheduler pick-up | 30 s - 5 min | 1-5 min | Near immediate (API) |
| Total deploy | 2-10 min | 3-10 min | 1-5 min |

## Parse scalability factors

| Factor | Symptom | Mitigation |
| --- | --- | --- |
| Large DAG count (500+) | Long processor loop | Split repos, lazy imports |
| Heavy top-level code | Import errors in prod | CI `list-import-errors` |
| Dynamic DAG generation | CPU spike at parse | Cap dynamic tasks, cache metadata query |

## Benchmark procedure

1. Tag release in Git; record commit SHA
2. Trigger CI pipeline; note end timestamp
3. Poll orchestrator until DAG version reflects SHA
4. Record delta = **deploy latency**

Target: **< 15 min** for standard changes; **< 60 min** for platform upgrades.

## Related

- [CI/CD for Data](../02.03.04_Architecture_Patterns/02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md)
- [GitOps for Data](../02.03.04_Architecture_Patterns/02.03.04.01_DataOps_Patterns/02.03.04.01.02_GitOps_For_Data.md)
'@

Write-Doc "02.03.05_Benchmarks\02.03.05.04_Worker_Concurrency_Scaling.md" "Worker Concurrency and Scaling" "02.03.05.04" "evaluation" "benchmark, workers, scaling" @'
# Worker Concurrency and Scaling

## Context

Execution throughput = **workers x slots x task duration**. Benchmark workers separately from scheduler.

## Executor comparison (indicative)

| Executor | Scale unit | Cold start | Best for |
| --- | --- | --- | --- |
| Celery | Worker process | Low | Steady batch |
| Kubernetes | Pod per task | 30 s - 2 min | Burst ELT |
| MWAA/Composer workers | Managed worker | Medium | Managed ops |
| Step Functions | State transition | ms (Express) | Short glue |
| Argo Workflows | K8s pod | 30 s+ | Container pipelines |

## Profile P3: fan-out (500 tasks)

| Workers/pods | Parallel cap | Wall time (1 min task) | Cost driver |
| ---: | ---: | ---: | --- |
| 10 | 10 | ~50 min | Baseline |
| 50 | 50 | ~10 min | Linear if no contention |
| 100 | 100 | ~5 min | DB/metadata pressure |

## Scaling signals

| Signal | Action |
| --- | --- |
| Queue depth rising | Add workers / HPA |
| Worker CPU low, queue high | Slot/config bottleneck |
| Metadata DB locks | Reduce parallelism, tune pools |
| K8s pending pods | Cluster autoscaler, quotas |

## Related

- [Benchmark Methodology](02.03.05.01_Benchmark_Methodology.md)
- [Argo Workflows Top 10 guide](../02.03.03_Top_10/02.03.03.06_Argo_Workflows_Learning_Guide/README.md)
'@

Write-Doc "02.03.05_Benchmarks\02.03.05.05_Backfill_And_Recovery_Benchmarks.md" "Backfill and Recovery Benchmarks" "02.03.05.05" "evaluation" "benchmark, backfill, recovery" @'
# Backfill and Recovery Benchmarks

## Context

**Backfills** stress orchestrators differently from steady-state: thousands of historical task instances, pool contention, warehouse cost.

## Backfill benchmark (Profile P6)

| Parameter | Example |
| --- | --- |
| Partitions | 90 daily |
| Tasks per partition | 20 |
| Total task instances | 1,800 |
| Pool | `backfill` slot limit 25 |

| Metric | Measure |
| --- | --- |
| Wall-clock duration | Start to last success |
| Warehouse cost | Credits/$ during backfill |
| Failure rate | Retries, dead letter |
| SLA impact | T0 DAG delay if shared pools |

## Recovery benchmarks

| Scenario | RTO target | Measure |
| --- | --- | --- |
| Scheduler failover | < 5 min | Time to resume scheduling |
| Metadata DB restore | < 1 h | From backup |
| Region DR | < 4 h | Secondary orchestrator + DAG sync |
| Corrupted DAG rollback | < 15 min | Git revert + sync |

## Best practices

- Dedicated **backfill pool** with lower priority than T0
- `max_active_runs=1` on backfill DAG variants
- Cost cap alerts on warehouse during backfill

## Related

- [Scheduling Patterns](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.01_Scheduling_Patterns.md)
- [Retry Strategies](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.03_Retry_Strategies.md)
'@

Write-Doc "02.03.05_Benchmarks\02.03.05.06_Cost_And_SLA_Benchmark_Framework.md" "Cost and SLA Benchmark Framework" "02.03.05.06" "evaluation" "benchmark, cost, sla" @'
# Cost and SLA Benchmark Framework

## Purpose

Link **orchestration benchmarks** to **FinOps** and **SLA tiers** - control plane cost is often small vs compute, but bad orchestration drives warehouse waste.

## Cost components

| Component | Typical % of total | Benchmark focus |
| --- | ---: | --- |
| Orchestrator control plane | 5-15% | MWAA/Composer hourly, self-host K8s |
| Workers / task compute | 40-70% | Slot-hours, pod-minutes |
| Downstream (Spark, BQ, Snowflake) | 20-50% | Failed retries, over-scheduling |
| Observability / metadata | 5-10% | Log volume, lineage export |

## SLA tier mapping

| Tier | Deadline example | Benchmark requirement |
| --- | --- | --- |
| **T0** | 6 AM finance | p99 schedule delay < 5 min |
| **T1** | Same business day | p99 < 30 min |
| **T2** | Best effort | No hard benchmark |

## Cost benchmark worksheet

| DAG / domain | Runs/month | Avg duration | Retry rate | Warehouse $/run | Orchestration $/run |
| --- | ---: | ---: | ---: | ---: | ---: |
| | | | | | |

**Optimization signals:** retry rate > 5%, nightly overlap causing queue, sensors polling every 60s on idle deps.

## Related

- [SLA Management](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.04_SLA_Management.md)
- [Managed Workflows](../02.03.02_Cloud_Services/02.03.02.01_Overview/02.03.02.01.02_Managed_Workflows.md)
'@

Write-Doc "02.03.05_Benchmarks\README.md" "Benchmarks" "02.03.05" "hub" "benchmark, orchestration" @'
# 02.03.05 Benchmarks

Reference **benchmark profiles, methodology, and sizing guidance** for orchestration platforms.

## Start here

- [Benchmark Methodology](02.03.05.01_Benchmark_Methodology.md)
- [Cost and SLA Benchmark Framework](02.03.05.06_Cost_And_SLA_Benchmark_Framework.md)

## Topics

| Doc | Focus |
| --- | --- |
| [Benchmark Methodology](02.03.05.01_Benchmark_Methodology.md) | Profiles P1-P6, reporting template |
| [Scheduler Throughput](02.03.05.02_Scheduler_Throughput_Profiles.md) | Task instances/min, tuning |
| [DAG Parse and Deploy Latency](02.03.05.03_DAG_Parse_And_Deploy_Latency.md) | CI/CD timing |
| [Worker Concurrency Scaling](02.03.05.04_Worker_Concurrency_Scaling.md) | Executors, fan-out |
| [Backfill and Recovery](02.03.05.05_Backfill_And_Recovery_Benchmarks.md) | Historical runs, RTO |
| [Cost and SLA Framework](02.03.05.06_Cost_And_SLA_Benchmark_Framework.md) | FinOps linkage |

## Related

- [Top 10 Benchmarking modules](../02.03.03_Top_10/README.md)
- [Comparisons](../02.03.06_Comparisons/README.md)
'@

Write-Host "02.03.05 Benchmarks done"
