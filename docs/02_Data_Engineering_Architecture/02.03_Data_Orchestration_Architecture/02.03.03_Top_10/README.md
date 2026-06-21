---
title: Top 10 Open Source Orchestration Technologies
section: "02.03.03"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [orchestration, top-10, open-source, learning-guide]
canonical: true
---
# 02.03.03 Top 10 Open Source Orchestration

Ranked catalog of **open source and self-hosted** data orchestration platforms — each with a **9-module learning guide**. Hyperscaler managed services (Composer, MWAA, ADF, Step Functions, etc.) are in [02.03.02 Cloud Services](../02.03.02_Cloud_Services/README.md) only.

## Start here

- [Top 10 Rankings and Selection Criteria](02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md)
- [Cloud Orchestration Services](../02.03.02_Cloud_Services/README.md)
- [What Is Data Orchestration](../02.03.01_Fundamentals/02.03.01.01_Overview/02.03.01.01.01_What_Is_Data_Orchestration.md)

## Ranked technologies (open source)

| Rank | Technology | Category | Learning guide |
| ---: | --- | --- | --- |
| 1 | **Apache Airflow** | DAG orchestrator | [Guide](02.03.03.02_Apache_Airflow_Learning_Guide/README.md) |
| 2 | **Prefect** | Python flows | [Guide](02.03.03.03_Prefect_Learning_Guide/README.md) |
| 3 | **Dagster** | Asset-centric | [Guide](02.03.03.04_Dagster_Learning_Guide/README.md) |
| 4 | **Temporal** | Durable execution | [Guide](02.03.03.05_Temporal_Learning_Guide/README.md) |
| 5 | **Argo Workflows** | Kubernetes native | [Guide](02.03.03.06_Argo_Workflows_Learning_Guide/README.md) |
| 6 | **Kestra** | Declarative YAML | [Guide](02.03.03.07_Kestra_Learning_Guide/README.md) |
| 7 | **Flyte** | K8s data/ML | [Guide](02.03.03.08_Flyte_Learning_Guide/README.md) |
| 8 | **Luigi** | Lightweight Python | [Guide](02.03.03.09_Luigi_Learning_Guide/README.md) |
| 9 | **Metaflow** | ML/data workflows | [Guide](02.03.03.10_Metaflow_Learning_Guide/README.md) |
| 10 | **Mage** | Notebook pipelines | [Guide](02.03.03.11_Mage_Learning_Guide/README.md) |

## Learning guide module pattern

| # | Module | Focus |
| ---: | --- | --- |
| 1 | Overview | What it is, mental model, when to use |
| 2 | Architecture | Components, control vs execution plane |
| 3 | How to Use | Author, deploy, operate |
| 4 | Scenarios | Enterprise patterns |
| 5 | Limitations and Scenarios | Constraints, mitigations |
| 6 | Costing | Self-host / OSS cost models |
| 7 | Production Configuration | HA, security, monitoring |
| 8 | Evaluation Criteria | Scorecard vs Top 10 peers |
| 9 | Benchmarking | Reference load profiles |

## OSS vs cloud managed

| Layer | Where documented |
| --- | --- |
| **Open source / self-hosted** | This section (Top 10) |
| **GCP / AWS / Azure managed** | [02.03.02 Cloud Services](../02.03.02_Cloud_Services/README.md) |

Many teams run **Airflow OSS** on K8s or adopt **Composer/MWAA** for managed operations — compare [Managed Workflows](../02.03.02_Cloud_Services/02.03.02.01_Overview/02.03.02.01.02_Managed_Workflows.md).

## Related

- [02.03 Data Orchestration Architecture](../README.md)
- [Cloud Services catalog](../02.03.02_Cloud_Services/README.md)
