---
title: Apache Airflow Scenarios
section: "02.03.03.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 4. Apache Airflow Scenarios

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: Enterprise pipeline patterns
## Reference patterns

| Pattern | Airflow mechanism |
| --- | --- |
| Medallion ELT | Task groups per layer; dataset outlets on curated tables |
| Dynamic task mapping | `.expand()` over partition list from XCom or object store manifest |
| SLA alerting | `sla` timedelta on tasks + email/Slack callbacks |
| Cross-DAG trigger | `TriggerDagRunOperator` with `wait_for_completion` |
| Backfill | CLI `airflow dags backfill` or UI with date range |
| Pool throttling | `pool` slots for API rate limits |
| Priority lanes | `priority_weight` + separate queues |

## Anti-patterns

Running heavy Spark inside `PythonOperator` on the worker JVM footprint—delegate to `DataprocSubmitJobOperator`, `EmrAddStepsOperator`, or KubernetesPodOperator instead.

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
