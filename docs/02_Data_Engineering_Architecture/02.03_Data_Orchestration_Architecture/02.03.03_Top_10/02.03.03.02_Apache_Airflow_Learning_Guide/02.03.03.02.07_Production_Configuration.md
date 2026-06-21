---
title: Apache Airflow Production Configuration
section: "02.03.03.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 7. Apache Airflow Production Configuration

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: HA, security, monitoring recipes
## Production checklist

| Area | Recommendation |
| --- | --- |
| HA | Multi-scheduler (Airflow 2+), redundant webservers behind LB |
| Secrets | `SecretsBackend` integration; disable admin connection UI in prod |
| RBAC | Map SSO groups to Airflow roles |
| DAG integrity | `dagbag_import_timeout`, max active runs per DAG |
| Upgrades | Blue/green metadata migration in staging first |
| Backups | Nightly metadata snapshots; document restore RTO |

## Observability

Export scheduler metrics: `scheduler_heartbeat`, `dag_processing`, `executor_queue`. Alert on p95 task queue time and failed SLA callbacks.

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
