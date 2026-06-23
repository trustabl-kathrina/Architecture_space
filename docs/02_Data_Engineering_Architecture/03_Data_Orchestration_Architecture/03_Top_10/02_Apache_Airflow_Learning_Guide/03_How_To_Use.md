---
title: Apache Airflow How To Use
section: "02.03.03.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [airflow, open-source, top-10, learning-guide]
canonical: true
---

# 3. Apache Airflow How To Use

See [official documentation](https://airflow.apache.org/docs/) and [Top 10 hub](../README.md).

Module focus: Author, deploy, invoke, operate
## Local bootstrap

```bash
pip install "apache-airflow[celery,postgres]==2.10.*"
airflow db migrate
airflow users create ...
airflow standalone   # or docker-compose official image
```

Store DAGs under `dags/` with `AIRFLOW__CORE__DAGS_FOLDER` or Git-sync sidecars in Kubernetes.

## Authoring patterns

- Use **TaskFlow API** (`@dag`, `@task`) for typed Python dependencies.
- Set `catchup=False` on backfill-sensitive pipelines unless historical reprocessing is intended.
- Pin `start_date` in the past only when catchup is required.
- Use **datasets** (Airflow 2.4+) for data-driven scheduling between DAGs.

## CI/CD

1. `airflow dags list-import-errors` in CI on every PR.
2. Run **pytest** with `airflow.utils.state` mocks or `DagBag` load tests.
3. Promote via S3/GCS sync, Helm, or provider-specific deploy hooks.

## Operations

Rotate Fernet keys with a documented procedure; export connections to secret backend (Vault, AWS Secrets Manager, GCP Secret Manager).

## Related

- [Top 10 README](../README.md)
- [Apache Airflow hub](../README.md)
