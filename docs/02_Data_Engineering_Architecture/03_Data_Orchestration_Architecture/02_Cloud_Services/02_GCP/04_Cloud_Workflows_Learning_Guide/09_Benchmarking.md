---
title: Cloud Workflows Benchmarking
section: "02.03.02.02.04"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, workflows, benchmarking]
canonical: true
---
# 9. Cloud Workflows Benchmarking

Reference profiles for **load testing and step budgeting** before production.

## Methodology

1. Deploy workflow to **staging** project.
2. Synthetic trigger (Script or Load test tool calling `executions.create`).
3. Measure: end-to-end latency, step count, failure rate, queued time.
4. Compare against [Costing](06_Costing.md) model.

## Reference scenarios

| ID | Profile | Steps/exec | Volume | Measure |
| ---: | --- | ---: | ---: | --- |
| W1 | Minimal assign + return | 3 | 10K/day | Baseline latency |
| W2 | BQ query + branch | 8 internal | 5K/day | BQ job wait dominates |
| W3 | External HTTP × 3 | 5 int + 3 ext | 50K/day | External step cost |
| W4 | Parallel × 4 branches | 12 internal | 1K/day | Parallel wall time |
| W5 | For loop 100 items | 100+ internal | 100/day | Step explosion risk |
| W6 | Eventarc burst | 10 steps | 5K in 1 min | 429 vs backlogging |
| W7 | Retry stress (fail 2×) | 5 × 3 attempts | 1K/day | Retry billing impact |
| W8 | Callback wait 1 hr | 4 + wait | 50/day | Long-running stability |

## Expected outcomes (indicative)

| Profile | p50 latency | p99 latency | Notes |
| --- | --- | --- | --- |
| W1 | &lt; 500 ms | &lt; 2 s | Overhead bound |
| W2 | 2–10 s | 30 s | BQ query dependent |
| W6 (no backlog) | — | Many 429 | Enable backlogging |
| W6 (backlog) | +queue time | Executes when quota free | |

## Anti-patterns in benchmarks

- **W5-style large loops** — benchmark exposes step cost; refactor to batch job.
- **Uncapped retries** — inflates both cost and duration metrics.

## Related

- [Production Configuration](07_Production_Configuration.md)
- [Limitations](05_Limitations_And_Scenarios.md)
