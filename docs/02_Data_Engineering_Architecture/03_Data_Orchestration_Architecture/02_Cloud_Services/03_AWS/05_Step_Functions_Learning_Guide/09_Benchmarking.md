---
title: AWS Step Functions Benchmarking
section: "02.03.02.03.05"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, step-functions, benchmarking]
canonical: true
---
# 9. AWS Step Functions Benchmarking

Reference profiles for **load testing and transition budgeting** before production.

## Methodology

1. Deploy state machine to **staging** account.
2. Synthetic trigger via EventBridge or `start-execution` load script.
3. Measure: end-to-end latency, transition count, failure rate, throttling.
4. Compare Standard vs Express using [Costing](06_Costing.md).

## Reference scenarios

| ID | Profile | Transitions/exec | Volume | Measure |
| ---: | --- | ---: | ---: | --- |
| S1 | Pass chain only | 3 | 10K/day | Baseline latency |
| S2 | Glue `.sync` | 4 | 5K/day | Glue wait dominates |
| S3 | Map × 10 branches | 12 | 1K/day | Parallel wall time |
| S4 | Map × 100 items | 100+ | 100/day | Transition cost explosion |
| S5 | EventBridge burst | 6 | 5K in 1 min | Throttling vs DLQ |
| S6 | Retry stress (fail 2×) | 5 × 3 attempts | 1K/day | Retry billing impact |
| S7 | Callback wait 1 hr | 4 + wait | 50/day | Standard long-running |
| S8 | Express sync API | 5 | 100K/day | Express vs Standard cost |

## Expected outcomes (indicative)

| Profile | p50 latency | p99 latency | Notes |
| --- | --- | --- | --- |
| S1 | &lt; 200 ms | &lt; 1 s | Overhead bound |
| S2 | 5–30 min | Glue-bound | Not Express-compatible if &gt; 5 min |
| S5 (no DLQ) | — | Throttling errors | EventBridge replay config |
| S8 Express | &lt; 500 ms | &lt; 2 s | Log to CloudWatch required |

## Anti-patterns in benchmarks

- **S4 large Map** — exposes transition cost; use Distributed Map or Glue bulk.
- **Uncapped retries** — inflates both cost and duration metrics.

## Related

- [Production Configuration](07_Production_Configuration.md)
- [Cloud Workflows Benchmarking](../../02_GCP/04_Cloud_Workflows_Learning_Guide/09_Benchmarking.md)
