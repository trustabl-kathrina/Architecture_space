---
title: Composer vs MWAA vs Self-Hosted Airflow
section: "02.03.06.02"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [comparison, composer, mwaa, airflow]
canonical: true
---
# Cloud Composer vs MWAA vs Self-Hosted Airflow

## Summary

All three run **Apache Airflow** with different operational models. Choice is driven by **cloud anchor**, **ops appetite**, and **network topology**.

| Lens | Cloud Composer (GCP) | Amazon MWAA (AWS) | Self-hosted Airflow |
| --- | --- | --- | --- |
| Ops model | Google-managed GKE + Airflow | AWS-managed control plane | You operate all layers |
| Best fit | GCP-native data stack | AWS-native, private VPC | Multi-cloud, full control |
| Cost predictability | Environment + GKE + workers | Environment + workers | Infra + staff time |

## Comparison matrix

| Criterion | Composer 2/3 | MWAA | Self-hosted |
| --- | --- | --- | --- |
| Airflow versioning | Google-supported runtime | AWS-supported runtime | Pin any version |
| Executor | Celery/K8s (env dependent) | Celery (default) | Any executor |
| DAG storage | GCS sync | S3 sync | Git, S3, PVC |
| Networking | VPC-SC, Private IP | VPC, SG | Custom |
| IAM integration | GCP IAM | AWS IAM | Custom |
| Upgrade control | Google schedule | AWS schedule | Full control |
| Day-2 burden | Low-medium | Low-medium | High |

## When to choose

| Choose Composer when | Choose MWAA when | Choose self-hosted when |
| --- | --- | --- |
| BigQuery, GCS, Dataproc hub | Glue, Redshift, S3 hub | Multi-cloud DAGs, custom executors |
| GCP org standards | AWS landing zone | Astronomer/Helm already standardized |

## Related

- [Composer Learning Guide](../02_Cloud_Services/02_GCP/03_Cloud_Composer_Learning_Guide/README.md)
- [MWAA Learning Guide](../02_Cloud_Services/03_AWS/04_MWAA_Learning_Guide/README.md)