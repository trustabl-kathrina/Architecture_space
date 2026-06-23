---
title: Worker Concurrency and Scaling
section: "02.03.05.04"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [benchmark, workers, scaling]
canonical: true
---
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

- [Benchmark Methodology](01_Benchmark_Methodology.md)
- [Argo Workflows Top 10 guide](../03_Top_10/06_Argo_Workflows_Learning_Guide/README.md)