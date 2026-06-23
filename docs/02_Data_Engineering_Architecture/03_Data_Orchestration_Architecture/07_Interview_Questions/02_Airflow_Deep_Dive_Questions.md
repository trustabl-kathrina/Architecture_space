---
title: Airflow Deep Dive Questions
section: "02.03.07.02"
status: complete
template: interview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [interview, airflow]
canonical: true
---
# Airflow Deep Dive - Interview Questions

## Airflow internals

1. **Scheduler loop** - what happens from DAG file change to task queued?
2. Compare **executors**: Local, Celery, Kubernetes.
3. **XCom** - purpose, size limits, anti-patterns?
4. **Pools, priorities, parallelism** - how do they interact?
5. **Sensors vs deferrable operators** - why deferrable matters at scale.
6. **Airflow 2.x Datasets** - how do they replace external task sensors?
7. **Dynamic task mapping** - use case and scheduler impact?

## Operations

8. How do you **debug a stuck task** in queued state?
9. **DAG versioning** and safe deploy without killing running tasks?
10. **Secrets** - Connections vs external secret backends?
11. Common causes of **metadata DB bloat** and cleanup strategy?
12. **MWAA vs self-hosted** - what does AWS manage vs you?

## Model answers

See [Airflow Architecture](../03_Top_10/02_Apache_Airflow_Learning_Guide/02_Architecture.md), [Retry Strategies](../01_Fundamentals/03_Core_Concepts/03_Retry_Strategies.md).

## Related

- [Scheduling and Dependency Questions](03_Scheduling_And_Dependency_Questions.md)