---
title: Catalog and Lineage Integration
section: "02.03.08.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [integration, catalog, lineage, openlineage]
canonical: true
---
# Catalog and Lineage Integration

## Problem

Orchestration without catalog integration produces **orphan runs** - no impact analysis, no dataset-triggered schedules, weak governance.

## Reference flow

```mermaid
flowchart LR
  Task[Orchestrator_Task]
  OL[OpenLineage_Emitter]
  Bus[Metadata_Bus_optional]
  Cat[Data_Catalog]
  Task --> OL --> Cat
  Bus --> Cat
  Cat --> Trigger[Dataset_Schedule_or_Alert]
  Trigger --> Task
```

## Integration patterns

| Pattern | Description |
| --- | --- |
| **Emit on task success** | Operator wrapper posts OpenLineage event |
| **Register on deploy** | CI creates/updates dataset stubs |
| **Sync run freshness** | Last success timestamp -> catalog SLA field |
| **Impact on failure** | Catalog notifies downstream owners from lineage |
| **Dataset-triggered DAG** | Airflow Datasets / Dagster assets from catalog URI |

## Catalog platforms

| Platform | Integration approach |
| --- | --- |
| DataHub | OpenLineage ingestion, Airflow plugin |
| Unity Catalog | Table FQN in lineage facets |
| Purview | ADF + custom lineage from Airflow |
| Collibra | API sync from metadata automation job |

## Required metadata contract

- Dataset URI / FQN stable across systems
- `dag_id`, task id, run id in lineage facets
- Owner and tier for alert routing

## Related

- [Active Metadata](../01_Fundamentals/06_Active_Metadata/01_Active_Metadata.md)
- [Metadata Automation](../04_Architecture_Patterns/02_Metadata_Driven/06_Metadata_Automation.md)
- [Metadata Reference Architecture](../09_Reference_Architectures/01_Metadata_Reference_Architecture.md)