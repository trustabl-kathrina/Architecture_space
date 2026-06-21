---
title: Multi-Cloud Batch Transform Patterns
section: "02.02.01.02.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [cross-cloud, batch]
canonical: true
---
# Multi-Cloud Batch Transform Patterns

| Pattern | Description |
| --- | --- |
| **Portable Spark** | Same JAR/wheel on EMR, Dataproc, Synapse |
| **dbt multi-target** | One project, profiles per warehouse |
| **Object storage neutral** | Delta on S3 + GCS via replication |
| **Orchestration hub** | Airflow on K8s triggering cloud jobs |

## IAM federation

Use workload identity: GCP SA, AWS IAM role, Azure managed identity federation for cross-cloud pipeline steps.
