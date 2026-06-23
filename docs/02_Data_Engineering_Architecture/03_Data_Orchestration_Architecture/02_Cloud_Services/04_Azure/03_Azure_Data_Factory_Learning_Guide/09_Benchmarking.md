---
title: Azure Data Factory Benchmarking
section: "02.03.02.04.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [azure, adf, benchmarking]
canonical: true
---
# 9. Azure Data Factory Benchmarking

Reference profiles for **DIU sizing and pipeline SLA validation** before production.

## Methodology

1. Deploy pipelines to **non-prod** factory with production-like datasets.
2. Vary DIU, parallel copies, and data flow vCores.
3. Measure: copy throughput, pipeline duration, SHIR CPU, cost per run.
4. Compare against [Costing](06_Costing.md).

## Reference scenarios

| ID | Profile | Activities | Volume | Measure |
| ---: | --- | ---: | ---: | --- |
| A1 | Copy SQL → ADLS | 1 copy | 10 GB | DIU sweep (2,4,8,16) |
| A2 | Copy large file | 1 copy | 500 GB | Throughput GB/min |
| A3 | Mapping data flow | 1 data flow | 50 GB | vCore-hours |
| A4 | ForEach 50 partitions | 50 copies | 50 × 1 GB | Concurrency limit |
| A5 | SHIR hybrid copy | 1 copy | 20 GB | SHIR CPU vs DIU |
| A6 | Tumbling window backfill | 720 windows | 30 days hourly | Total orchestration cost |
| A7 | Nested pipelines × 5 | 5 levels | Daily | Orchestration run count |
| A8 | Databricks notebook | 1 external | 2 hr job | End-to-end SLA |

## Expected outcomes (indicative)

| Profile | Success criteria | Risk signal |
| --- | --- | --- |
| A1 | Linear throughput to optimal DIU | Flat beyond 16 DIU — source bound |
| A3 | Transform within batch window | 8 vCore minimum cost floor |
| A5 | SHIR CPU &lt; 70% | Network or SHIR bottleneck |
| A6 | Backfill completes in budget | Runaway activity run count |

## Anti-patterns in benchmarks

- **A4 unbounded parallelism** — hits factory concurrency limits.
- **A3 for tiny datasets** — data flow overhead exceeds benefit.

## Related

- [Production Configuration](07_Production_Configuration.md)
- [MWAA Benchmarking](../../03_AWS/04_MWAA_Learning_Guide/09_Benchmarking.md)
