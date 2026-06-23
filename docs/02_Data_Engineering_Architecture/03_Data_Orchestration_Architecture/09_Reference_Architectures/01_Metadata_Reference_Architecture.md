---
title: Metadata-Driven Orchestration Reference Architecture
section: "02.03.09.01"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [reference-architecture, metadata, orchestration]
canonical: true
---
# Metadata-Driven Orchestration Reference Architecture

## Purpose

End-to-end reference for **metadata-driven batch orchestration** - catalog, lineage, and scheduler closed loop.

## Architecture

```mermaid
flowchart TB
  subgraph sources [Data_Sources]
    SaaS[SaaS_APIs]
    Files[Object_Storage]
    DB[Operational_DBs]
  end
  subgraph orchestration [Orchestration_Layer]
    Orch[Airflow_Dagster_or_Kestra]
    Factory[Metadata_Factory]
  end
  subgraph metadata [Active_Metadata]
    Cat[Data_Catalog]
    OL[OpenLineage]
    DQ[Quality_Signals]
  end
  subgraph consume [Consumption]
    WH[Warehouse_Lakehouse]
    BI[BI_and_ML]
  end
  MetaDB[(Pipeline_Metadata_DB)]
  sources --> Orch
  MetaDB --> Factory --> Orch
  Orch --> WH
  Orch --> OL --> Cat
  DQ --> Cat
  Cat -->|dataset_triggers| Orch
  WH --> BI
```

## Components

| Layer | Responsibility |
| --- | --- |
| **Pipeline metadata DB** | Sources, schedules, SLAs, mappings |
| **Factory / compiler** | Generates DAGs or assets from metadata |
| **Orchestrator** | Schedules, retries, pools |
| **Catalog** | Datasets, lineage, ownership |
| **Quality** | Checks feed active metadata |
| **Warehouse** | Bronze/silver/gold execution target |

## Non-functional requirements

| NFR | Target |
| --- | --- |
| T0 SLA | 99.5% on-time completion |
| Lineage coverage | 100% prod tasks emit OpenLineage |
| Deploy frequency | Daily per team with CI gates |
| RTO control plane | < 1 h |

## Related

- [Metadata-Driven Framework](../04_Architecture_Patterns/02_Metadata_Driven/01_Metadata_Driven_Framework.md)
- [Catalog Integration](../08_Integration_Patterns/03_Catalog_And_Lineage_Integration.md)