---
title: Argo Workflows Overview
section: "02.03.03.06"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [argo, kubernetes, cncf, open-source, top-10, learning-guide]
canonical: true
---

# 1. Argo Workflows Overview

## What is Argo?

**Argo Workflows** is a CNCF Kubernetes-native workflow engine for containerized batch and ML pipelines. Category: **Kubernetes-native workflows**.

## Why Top 10 rank #5?

Ranked in [Top 10 Open Source Orchestration](../01_Overview/01_Top_10_Orchestration_Technologies.md) for adoption in data engineering, OSS community, and production fit â€” **excluding** hyperscaler managed services covered in [Cloud Services](../../02_Cloud_Services/README.md).

## When to use Argo

| Use whenâ€¦ | Consider alternatives whenâ€¦ |
| --- | --- |
| Kubernetes-native workflows matches your platform strategy | Managed cloud-only standard â†’ [Cloud Services](../../02_Cloud_Services/README.md) |
| Team prefers Argo model | Portable DAG mesh â†’ **Airflow** or **Prefect** |
| Self-host or bring-your-own K8s | Serverless cloud glue only â†’ Step Functions / Workflows in Cloud Services |

## Learning path

Continue to [Architecture](02.03.03.06.01_Architecture.md) or [Scenarios](02.03.03.06.01_Scenarios.md).
## Kubernetes-native workflows

Argo Workflows executes **DAGs of containers** defined in YAML (or Helm/Hera Python). Each step is a pod; artifacts pass via volumes or S3/GCS artifact repositories.

CNCF graduated project; common in **ML and HPC** pipelines on existing K8s clusters.

## Related

- [Top 10 README](../README.md)
- [Argo Workflows hub](../README.md)
