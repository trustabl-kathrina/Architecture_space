---
title: Apache Airflow Evaluation Criteria
section: "02.03.03.02"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 8. Apache Airflow Evaluation Criteria

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: Scorecard vs peer technologies
## Scorecard (qualitative)

| Criterion | Airflow | Notes |
| --- | ---: | --- |
| Batch DAG maturity | 5/5 | Industry default |
| Asset/lineage native | 3/5 | Datasets improving; Dagster stronger |
| Dynamic UX for ops | 4/5 | Rich UI |
| Self-host ops burden | 2/5 | Requires platform team |
| Portability | 5/5 | Same DAGs on MWAA/Composer |

Peers: **Prefect** (ergonomic Python, hybrid cloud), **Dagster** (assets), **Temporal** (durable micro-workflows).

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
