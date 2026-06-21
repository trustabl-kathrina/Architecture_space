---
title: Cloud Services README
section: "02.03.02"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [orchestration, cloud, gcp, aws, azure]
canonical: true
---
# 02.03.02 Cloud Services

> Status: 79 complete / 0 draft / 0 review / 7 stub (86 topics)

## Purpose

Managed cloud orchestration services across GCP, AWS, and Azure — reference architecture, service catalog, per-hyperscaler architecture docs, and multi-cloud patterns.

## Start here

- [Cloud Orchestration Reference Architecture](02.03.02.01_Overview/02.03.02.01.01_Cloud_Orchestration_Reference_Architecture.md)
- [Managed Workflows](02.03.02.01_Overview/02.03.02.01.02_Managed_Workflows.md)

## Service catalog (by cloud)

### Google Cloud (GCP)

| Service | Doc |
| --- | --- |
| Cloud Composer (managed Airflow) | [Architecture](02.03.02.02_GCP/02.03.02.02.01_Cloud_Composer_Architecture.md) · [Learning Guide](02.03.02.02_GCP/02.03.02.02.03_Cloud_Composer_Learning_Guide/README.md) |
| Cloud Workflows (serverless) | [Architecture](02.03.02.02_GCP/02.03.02.02.02_Cloud_Workflows_Architecture.md) · [Learning Guide](02.03.02.02_GCP/02.03.02.02.04_Cloud_Workflows_Learning_Guide/README.md) |
| Cloud Scheduler | Trigger only — see [Reference Architecture](02.03.02.01_Overview/02.03.02.01.01_Cloud_Orchestration_Reference_Architecture.md) |

### GCP learning guides

| Guide | Modules | Hub |
| --- | ---: | --- |
| Cloud Composer | 9 | [README](02.03.02.02_GCP/02.03.02.02.03_Cloud_Composer_Learning_Guide/README.md) |
| Cloud Workflows | 9 | [README](02.03.02.02_GCP/02.03.02.02.04_Cloud_Workflows_Learning_Guide/README.md) |

### Amazon Web Services (AWS)

| Service | Doc |
| --- | --- |
| MWAA (managed Airflow) | [Architecture](02.03.02.03_AWS/02.03.02.03.01_MWAA_Architecture.md) · [Learning Guide](02.03.02.03_AWS/02.03.02.03.04_MWAA_Learning_Guide/README.md) |
| Step Functions (serverless) | [Architecture](02.03.02.03_AWS/02.03.02.03.02_Step_Functions_Architecture.md) · [Learning Guide](02.03.02.03_AWS/02.03.02.03.05_Step_Functions_Learning_Guide/README.md) |
| Glue Workflows (Glue ETL) | [Architecture](02.03.02.03_AWS/02.03.02.03.03_Glue_Workflows_Architecture.md) · [Learning Guide](02.03.02.03_AWS/02.03.02.03.06_Glue_Workflows_Learning_Guide/README.md) |
| EventBridge | Trigger only — see [Reference Architecture](02.03.02.01_Overview/02.03.02.01.01_Cloud_Orchestration_Reference_Architecture.md) |

### AWS learning guides

| Guide | Modules | Hub |
| --- | ---: | --- |
| Amazon MWAA | 9 | [README](02.03.02.03_AWS/02.03.02.03.04_MWAA_Learning_Guide/README.md) |
| AWS Step Functions | 9 | [README](02.03.02.03_AWS/02.03.02.03.05_Step_Functions_Learning_Guide/README.md) |
| AWS Glue Workflows | 9 | [README](02.03.02.03_AWS/02.03.02.03.06_Glue_Workflows_Learning_Guide/README.md) |

### Microsoft Azure

| Service | Doc |
| --- | --- |
| Azure Data Factory | [Architecture](02.03.02.04_Azure/02.03.02.04.01_Azure_Data_Factory_Architecture.md) · [Learning Guide](02.03.02.04_Azure/02.03.02.04.03_Azure_Data_Factory_Learning_Guide/README.md) |
| Logic Apps | [Architecture](02.03.02.04_Azure/02.03.02.04.02_Logic_Apps_Architecture.md) · [Learning Guide](02.03.02.04_Azure/02.03.02.04.04_Logic_Apps_Learning_Guide/README.md) |
| Microsoft Fabric Data Factory | Fabric-native — see [ADF Architecture](02.03.02.04_Azure/02.03.02.04.01_Azure_Data_Factory_Architecture.md) and [ADF Learning Guide](02.03.02.04_Azure/02.03.02.04.03_Azure_Data_Factory_Learning_Guide/README.md) |

### Azure learning guides

| Guide | Modules | Hub |
| --- | ---: | --- |
| Azure Data Factory | 9 | [README](02.03.02.04_Azure/02.03.02.04.03_Azure_Data_Factory_Learning_Guide/README.md) |
| Azure Logic Apps | 9 | [README](02.03.02.04_Azure/02.03.02.04.04_Logic_Apps_Learning_Guide/README.md) |

### Cross-cloud

| Topic | Doc |
| --- | --- |
| Multi-cloud patterns | [Patterns](02.03.02.05_Cross_Cloud/02.03.02.05.01_Multi_Cloud_Orchestration_Patterns.md) |

## Subsections

| # | Topic | Services / topics | Key doc | Status |
| --- | --- | ---: | --- | --- |
| 02.03.02.01 | Overview | 2 | [Cloud Orchestration Reference Architecture](02.03.02.01_Overview/02.03.02.01.01_Cloud_Orchestration_Reference_Architecture.md) | complete |
| 02.03.02.02 | GCP | 20 | [Cloud Composer Learning Guide](02.03.02.02_GCP/02.03.02.02.03_Cloud_Composer_Learning_Guide/README.md) | complete |
| 02.03.02.03 | AWS | 31 | [Glue Workflows Learning Guide](02.03.02.03_AWS/02.03.02.03.06_Glue_Workflows_Learning_Guide/README.md) | complete |
| 02.03.02.04 | Azure | 22 | [ADF Learning Guide](02.03.02.04_Azure/02.03.02.04.03_Azure_Data_Factory_Learning_Guide/README.md) | complete |
| 02.03.02.05 | Cross Cloud | 1 | [Multi-Cloud Patterns](02.03.02.05_Cross_Cloud/02.03.02.05.01_Multi_Cloud_Orchestration_Patterns.md) | complete |
| 02.03.02.06 | Platform Engineering | 7 | [Platform Provisioning](02.03.02.06_Platform_Engineering/02.03.02.06.01_Platform_Provisioning.md) | stub |

## Related

- [Top 10 Orchestration Technologies](../02.03.03_Top_10/README.md)
- [02.03 Data Orchestration Architecture](../README.md)
- [Orchestration Strategy](../02.03.01_Fundamentals/02.03.01.02_Strategy/02.03.01.02.01_Orchestration_Strategy.md)
- [Cloud Streaming Reference Architecture](../../02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.02_Cloud_Services/02.01.02.02.01_Overview/02.01.02.02.01.01_Cloud_Streaming_Reference_Architecture.md)
