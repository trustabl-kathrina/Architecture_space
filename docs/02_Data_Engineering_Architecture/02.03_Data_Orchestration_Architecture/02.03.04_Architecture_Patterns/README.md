---
title: Architecture Patterns
section: "02.03.04"
status: complete
template: hub
last_reviewed: 2026-06-20
owner: architecture-team
tags: [orchestration, patterns, dataops, metadata-driven, ai]
canonical: true
---
# 02.03.04 Architecture Patterns

Orchestration **architecture patterns** for DataOps, metadata-driven pipelines, platform engineering, and AI-assisted workflows.

## Start here

- [Metadata-Driven Framework](02.03.04.02_Metadata_Driven/02.03.04.02.01_Metadata_Driven_Framework.md) - core pattern for scalable pipeline factories
- [CI/CD for Data](02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md) - deploy DAGs like application code
- [AI Data Engineering Overview](02.03.04.04_AI_Assisted/02.03.04.04.01_AI_Data_Engineering_Overview.md) - AI in the orchestration lifecycle

## Subsections

### 02.03.04.01 DataOps Patterns

| Doc | Focus |
| --- | --- |
| [CI/CD for Data](02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md) | Pipeline CI/CD stages and gates |
| [GitOps for Data](02.03.04.01_DataOps_Patterns/02.03.04.01.02_GitOps_For_Data.md) | Git as source of truth for orchestrator |
| [Data Deployment Strategy](02.03.04.01_DataOps_Patterns/02.03.04.01.03_Data_Deployment_Strategy.md) | Parallel, backfill, rollback |
| [Data Release Management](02.03.04.01_DataOps_Patterns/02.03.04.01.04_Data_Release_Management.md) | Releases, freezes, bundles |
| [Data Testing Strategy](02.03.04.01_DataOps_Patterns/02.03.04.01.05_Data_Testing_Strategy.md) | Test pyramid for pipelines |
| [Automated Validation](02.03.04.01_DataOps_Patterns/02.03.04.01.06_Automated_Validation.md) | In-DAG validation gates |

### 02.03.04.02 Metadata-Driven

| Doc | Focus |
| --- | --- |
| [Metadata-Driven Framework](02.03.04.02_Metadata_Driven/02.03.04.02.01_Metadata_Driven_Framework.md) | Reference framework |
| [Metadata-Driven ETL](02.03.04.02_Metadata_Driven/02.03.04.02.02_Metadata_Driven_ETL.md) | Parameterized ELT |
| [Metadata-Driven Transformations](02.03.04.02_Metadata_Driven/02.03.04.02.03_Metadata_Driven_Transformations.md) | dbt/asset-driven order |
| [Configuration-Driven Processing](02.03.04.02_Metadata_Driven/02.03.04.02.04_Configuration_Driven_Processing.md) | Externalized config |
| [Dynamic Pipeline Generation](02.03.04.02_Metadata_Driven/02.03.04.02.05_Dynamic_Pipeline_Generation.md) | Runtime/parse-time DAGs |
| [Metadata Automation](02.03.04.02_Metadata_Driven/02.03.04.02.06_Metadata_Automation.md) | Catalog sync |
| [Metadata Orchestration](02.03.04.02_Metadata_Driven/02.03.04.02.07_Metadata_Orchestration.md) | Dataset-triggered schedules |

### 02.03.04.03 Platform Patterns

| Doc | Focus |
| --- | --- |
| [Internal Developer Platform](02.03.04.03_Platform_Patterns/02.03.04.03.01_Internal_Developer_Platform.md) | Golden-path self-service |

### 02.03.04.04 AI-Assisted

| Doc | Focus |
| --- | --- |
| [AI Data Engineering Overview](02.03.04.04_AI_Assisted/02.03.04.04.01_AI_Data_Engineering_Overview.md) | Scope and guardrails |
| [Agentic Data Engineering](02.03.04.04_AI_Assisted/02.03.04.04.02_Agentic_Data_Engineering.md) | Agents + orchestrator tools |
| [AI Code Generation](02.03.04.04_AI_Assisted/02.03.04.04.03_AI_Code_Generation.md) | Task/DAG codegen |
| [AI Data Mapping](02.03.04.04_AI_Assisted/02.03.04.04.04_AI_Data_Mapping.md) | Mapping → ingest tasks |
| [AI Data Quality](02.03.04.04_AI_Assisted/02.03.04.04.05_AI_Data_Quality.md) | Anomaly and NL rules |
| [AI Lineage Generation](02.03.04.04_AI_Assisted/02.03.04.04.06_AI_Lineage_Generation.md) | Inferred dependencies |
| [AI Metadata Management](02.03.04.04_AI_Assisted/02.03.04.04.07_AI_Metadata_Management.md) | Catalog enrichment |
| [AI Pipeline Generation](02.03.04.04_AI_Assisted/02.03.04.04.08_AI_Pipeline_Generation.md) | End-to-end drafts |
| [AI Test Generation](02.03.04.04_AI_Assisted/02.03.04.04.09_AI_Test_Generation.md) | Test cases in CI/DAG |
| [Autonomous Data Platforms](02.03.04.04_AI_Assisted/02.03.04.04.10_Autonomous_Data_Platforms.md) | Autonomy levels |

## Related

- [02.03 Data Orchestration Architecture](../README.md)
- [Fundamentals](../02.03.01_Fundamentals/README.md)
- [Active Metadata](../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
- [Cloud Services](../02.03.02_Cloud_Services/README.md)