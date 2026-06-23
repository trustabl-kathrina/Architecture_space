---
title: How to Use Cloud Composer
section: "02.03.02.02.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, composer, operations, airflow]
canonical: true
---
# 3. How to Use Cloud Composer

## Setup prerequisites

1. Enable `composer.googleapis.com` on the GCP project.
2. Choose **region** (align with BigQuery/Dataproc data residency).
3. Create **VPC network + subnetworks** for private IP environment.
4. Create **service account** for Composer with least-privilege roles on data resources.
5. Define naming: `composer-{domain}-{env}` (e.g., `composer-finance-prod`).

## Create environment (gcloud — Composer 3)

```bash
gcloud composer environments create composer-analytics-prod \
  --location=us-central1 \
  --composer-version=3 \
  --image-version=composer-3-airflow-2.10.2-build.1 \
  --environment-size=ENVIRONMENT_SIZE_MEDIUM \
  --network=projects/PROJECT/global/networks/data-vpc \
  --subnetwork=projects/PROJECT/regions/us-central1/subnetworks/composer-subnet \
  --enable-private-environment \
  --web-server-allow-all \
  --scheduler-count=2 \
  --worker-min-count=2 \
  --worker-max-count=12
```

Adjust `image-version` to a [currently supported](https://cloud.google.com/composer/docs/concepts/versioning) release.

## Deploy DAGs

### Option A — GCS sync (common)

```bash
ENV_BUCKET=$(gcloud composer environments describe composer-analytics-prod \
  --location=us-central1 --format="value(config.dagGcsPrefix)")

gsutil cp dags/*.py "${ENV_BUCKET}/"
gsutil cp requirements.txt plugins.zip "${ENV_BUCKET%/dags}/"
```

### Option B — CI/CD (recommended)

1. PR → CI runs `airflow dags list-import-errors` against Composer image.
2. Merge → pipeline uploads to GCS or uses `gcloud composer environments storage dags import`.

### Sample DAG (BigQuery partition load)

```python
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.timetables.trigger import CronTriggerTimetable
from datetime import datetime

with DAG(
    dag_id="orders_daily",
    start_date=datetime(2024, 1, 1),
    schedule=CronTriggerTimetable("0 2 * * *", timezone="UTC"),
    catchup=False,
    tags=["finance", "tier:T1"],
) as dag:
    load = BigQueryInsertJobOperator(
        task_id="load_orders",
        configuration={
            "query": {
                "query": "CALL `project.dataset.sp_load_orders`('{{ ds }}')",
                "useLegacySql": False,
            }
        },
        location="US",
    )
```

## Connections and secrets

```bash
# Secret Manager backend (Composer 2/3)
gcloud composer environments update composer-analytics-prod \
  --location=us-central1 \
  --update-secrets=airflow-secrets=projects/PROJECT/secrets/airflow-conn-bq/versions/latest
```

In Airflow UI or env config, reference Secret Manager for connection JSON — **never** commit credentials to Git.

## IAM patterns

| Role | Grant to |
| --- | --- |
| `roles/composer.admin` | Platform team only |
| `roles/composer.user` | Data engineers (trigger, view) |
| `roles/composer.worker` | Environment service account (automatic) |
| `roles/bigquery.jobUser` + `dataEditor` | SA on target datasets |
| `roles/dataproc.worker` / custom | SA for Dataproc submits |

Use **custom roles** to restrict prod DAG trigger to break-glass group.

## Infrastructure as code (Terraform)

```hcl
resource "google_composer_environment" "prod" {
  name   = "composer-analytics-prod"
  region = "us-central1"

  config {
    software_config {
      image_version = "composer-3-airflow-2.10.2-build.1"
    }
    workloads_config {
      scheduler { count = 2, cpu = 2, memory_gb = 4 }
      worker {
        min_count = 2
        max_count = 12
        cpu       = 2
        memory_gb = 8
      }
    }
    environment_size = "ENVIRONMENT_SIZE_MEDIUM"
    node_config {
      network         = google_compute_network.data.id
      subnetwork      = google_compute_subnetwork.composer.id
      service_account = google_service_account.composer.email
    }
    private_environment_config { enable_private_endpoint = true }
  }
}
```

## Observability

| Signal | Source |
| --- | --- |
| Task duration / failures | Airflow UI + Cloud Monitoring Composer metrics |
| Scheduler heartbeat | `composer.googleapis.com/environment/scheduler/heartbeat_count` |
| Worker count | Autoscaling metrics |
| DAG parse errors | `import_errors` in UI; alert in CI |
| Logs | Cloud Logging — filter `resource.type="cloud_composer_environment"` |

**OpenLineage:** Install provider; emit lineage on task start/complete to Data Catalog/Marquez.

## Operational checklist

- [ ] Private IP enabled for prod
- [ ] DAGs deployed via CI only
- [ ] `catchup=False` unless backfill planned
- [ ] Pools configured for warehouse concurrency
- [ ] Retries and `execution_timeout` set per task tier
- [ ] Environment SA least privilege verified quarterly
- [ ] Staging environment mirrors prod Airflow version

## Related

- [Architecture](02_Architecture.md)
- [Production Configuration](07_Production_Configuration.md)
- [Scenarios](04_Scenarios.md)
