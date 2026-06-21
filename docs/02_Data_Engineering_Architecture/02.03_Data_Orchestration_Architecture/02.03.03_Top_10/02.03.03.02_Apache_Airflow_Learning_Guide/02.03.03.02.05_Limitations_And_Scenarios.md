---
title: Apache Airflow Limitations And Scenarios
section: "02.03.03.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 5. Apache Airflow Limitations And Scenarios

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: Quotas, constraints, mitigations
## Known constraints

| Constraint | Detail |
| --- | --- |
| Schedule granularity | Minimum one minute for cron; use sensors or event triggers for sub-minute |
| Metadata DB pressure | High task count increases scheduler DB churn—partition old data |
| Worker packaging | Python deps must exist on every worker image |
| No native exactly-once | Orchestration is at-least-once; make tasks idempotent |
| UI not multi-tenant alone | RBAC helps but true isolation needs separate deployments |

## Mitigations

Use **deferrable operators** for long polls; **TaskGroups** and **SubDAGs (deprecated)** replaced by task groups; externalize secrets; enable **statsd/OpenTelemetry** for scheduler lag metrics.

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
