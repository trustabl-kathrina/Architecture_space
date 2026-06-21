---
title: Apache Airflow Costing
section: "02.03.03.02"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 6. Apache Airflow Costing

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: Self-host and OSS cost models
## Self-hosted cost drivers

| Driver | Typical spend |
| --- | --- |
| Always-on workers | Largest baseline—right-size or use K8sExecutor |
| Metadata DB | RDS/Cloud SQL HA instance |
| Redis/RabbitMQ | Celery broker HA |
| Log storage | S3/GCS lifecycle for task logs |
| Observability | Metrics + log indexing |

Managed Airflow (Composer/MWAA) adds environment fee but removes patch/upgrade toil—see Top 10 cloud entries for calculators.

## Optimization levers

- Autoscale workers on queue depth
- Short-circuit with `@task.short_circuit`
- Avoid excessive XCom serialization
- Use object-store remote logging with retention policies

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
