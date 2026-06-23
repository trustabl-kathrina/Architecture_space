---
title: Managed Workflows
section: "02.03.02.01"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [cloud, orchestration, managed, comparison]
canonical: true
---
# Managed Workflow Services (Cloud Comparison)

## Summary

**Managed workflow services** offload orchestrator operations — patching, scaling, metadata store, and control-plane HA — to the cloud provider. The three dominant patterns are **managed Airflow** (Composer, MWAA), **serverless state machines** (Cloud Workflows, Step Functions, Logic Apps), and **data-factory pipelines** (ADF, Glue Workflows).

| Lens | Managed Airflow | Serverless workflow | Data factory |
| --- | --- | --- | --- |
| Mental model | DAG of tasks (Python/operators) | State machine / YAML steps | Activity pipelines with triggers |
| Best fit | Complex batch, cross-service DAGs | Event-driven chains, API orchestration | Azure/Glue-native ETL |
| Ops burden | Medium (worker sizing, upgrades managed) | Low | Low–medium |
| Portability | High (Airflow OSS) | Cloud-specific | Cloud-specific |

---

## Service inventory by cloud

| Cloud | Service | Type | Documentation |
| --- | --- | --- | --- |
| **GCP** | Cloud Composer | Managed Airflow | [Architecture](../02_GCP/02.03.02.02.01_Cloud_Composer_Architecture.md) |
| **GCP** | Cloud Workflows | Serverless | [Architecture](../02_GCP/02.03.02.02.02_Cloud_Workflows_Architecture.md) |
| **AWS** | MWAA | Managed Airflow | [Architecture](../03_AWS/02.03.02.03.01_MWAA_Architecture.md) |
| **AWS** | Step Functions | Serverless | [Architecture](../03_AWS/02.03.02.03.02_Step_Functions_Architecture.md) |
| **AWS** | Glue Workflows | Analytics jobs | [Architecture](../03_AWS/02.03.02.03.03_Glue_Workflows_Architecture.md) |
| **Azure** | Azure Data Factory | Data factory | [Architecture](../04_Azure/02.03.02.04.01_Azure_Data_Factory_Architecture.md) |
| **Azure** | Logic Apps | Serverless / integration | [Architecture](../04_Azure/02.03.02.04.02_Logic_Apps_Architecture.md) |

**Complementary (not full DAG engines):** Cloud Scheduler, EventBridge, Event Grid, Cloud Scheduler — use as triggers into the services above.

---

## Comparison matrix

| Feature | Cloud Composer | MWAA | Step Functions | Cloud Workflows | ADF | Logic Apps |
| --- | --- | --- | --- | --- | --- | --- |
| **Workflow definition** | Python DAGs | Python DAGs | ASL JSON/YAML | YAML | JSON / UI | Designer + JSON |
| **Max task duration** | Hours–days | Hours–days | 1 year (Standard) | 1 year | Hours | Configurable |
| **Dynamic DAG** | TaskFlow, dynamic mapping | Same | Map state (limited) | Limited | Parameters | Variables |
| **Scheduling** | Built-in + Cloud Scheduler | Built-in + EventBridge | EventBridge rules | Cloud Scheduler | Triggers | Recurrence |
| **Lineage integration** | OpenLineage plugins | OpenLineage plugins | Custom | Custom | Purview | Limited |
| **Pricing model** | Environment + GKE + workers | Environment + workers | Per state transition | Per step + invocation | Activity execution | Per action |
| **Private network** | Private IP Composer | VPC endpoints | VPC integration | VPC-SC | Managed VNet IR | VNet integration |
| **Best batch DAG scale** | High | High | Medium | Medium | High (Azure) | Low–medium |

---

## Cloud Native Matrix

| Feature / Cloud | AWS | Azure | GCP |
| --- | --- | --- | --- |
| Managed Airflow | MWAA | AKS self-host / partners | Cloud Composer |
| Serverless orchestrator | Step Functions | Logic Apps | Cloud Workflows |
| ETL-native orchestrator | Glue Workflows | ADF / Fabric | Data Fusion (niche) |
| Event trigger | EventBridge | Event Grid | Eventarc / Pub/Sub |
| Primary data warehouse hook | Redshift, Athena | Synapse, Fabric | BigQuery |

---

## Best option by scenario

- **GCP-native enterprise batch** — Cloud Composer + BigQuery/Dataproc operators
- **AWS-native, existing Airflow DAGs** — MWAA
- **AWS serverless micro-pipelines** — Step Functions + Lambda/Glue jobs
- **AWS lakehouse Glue-only** — Glue Workflows for in-Glue jobs; Step Functions for external
- **Azure enterprise ETL** — ADF or Fabric pipelines with Purview lineage
- **B2B / SaaS integration workflows** — Logic Apps connectors
- **Portable multi-cloud batch** — Composer or MWAA; abstract operators behind internal library

---

## Operational complexity

| Service | Day-2 focus |
| --- | --- |
| Composer / MWAA | Worker autoscaling, DAG parse time, metadata DB performance, upgrade windows |
| Step Functions / Workflows | State transition debugging, IAM per step, execution history limits |
| ADF | Integration runtime health, trigger failures, activity concurrency limits |
| Logic Apps | Connector throttling, run history retention |

---

## Recommendation

Standardize on **one managed Airflow** (Composer or MWAA) per cloud environment for core data engineering DAGs. Use **serverless workflow** services for event-driven micro-orchestration and **ADF/Glue Workflows** where the team is already factory-centric on that cloud.

Full catalog: [Cloud Orchestration Reference Architecture](01_Cloud_Orchestration_Reference_Architecture.md).

## Related

- [Orchestration Strategy](../../01_Fundamentals/02_Strategy/01_Orchestration_Strategy.md)
- [Apache Airflow Learning Guide (Top 10)](../../03_Top_10/02_Apache_Airflow_Learning_Guide/README.md)
- [Multi-Cloud Orchestration Patterns](../05_Cross_Cloud/01_Multi_Cloud_Orchestration_Patterns.md)
