---
title: Apache Airflow Benchmarking
section: "02.03.03.02"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 9. Apache Airflow Benchmarking

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: Reference load and sizing profiles
## Sample benchmarks

| Profile | DAG shape | Success criteria |
| --- | --- | --- |
| B1 | 10 tasks serial | Scheduler delay < 30s from tick |
| B2 | 50 tasks fan-out/fan-in | Worker scale-up within 2 min |
| B3 | 500 mapped tasks | Metadata DB CPU < 70% |
| B4 | 24h backfill 1yr | Completes within maintenance window |
| B5 | Deferrable sensor 2h | Worker slot freed within seconds |

Record Airflow version, executor type, worker vCPU/RAM, and metadata DB size with every run for reproducibility.

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
