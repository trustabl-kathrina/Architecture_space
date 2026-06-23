---
title: NRT Lakehouse Transform Reference
section: "02.02.03.09"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [reference, nrt, lakehouse]
canonical: true
---
# NRT Lakehouse Transform Reference Architecture

## Enterprise reference

```mermaid
flowchart TB
  subgraph sources [Sources]
    OLTP[OLTP_CDC]
    Events[Product_Events]
  end
  subgraph ingest [02.01_Ingestion]
    Broker[Managed_Broker]
    Bronze[Bronze_Lake]
  end
  subgraph transform [02.02.03_NRT]
    Trigger[Orchestrator_Trigger]
    Engine[Spark_Dataflow_DLT]
    Silver[Silver_MERGE]
    Gold[Gold_Aggregates]
  end
  subgraph consume [Consumption]
    BI[BI_Dashboards]
    ML[Feature_Store]
  end
  OLTP --> Broker
  Events --> Broker
  Broker --> Bronze
  Bronze --> Trigger
  Trigger --> Engine
  Engine --> Silver
  Silver --> Gold
  Gold --> BI
  Gold --> ML
```

## Component responsibilities

| Layer | Technology examples | SLA |
| --- | --- | --- |
| Ingest | Pub/Sub, Kinesis, Debezium | < 1m to bronze |
| NRT transform | DLT, Glue SS, Dataflow | 2â€“10m to silver |
| Quality | Great Expectations, DLT expectations | Block publish on fail |
| Serve | Direct Lake, BQ, Snowflake | Query freshness tag |

## Related

- [Cloud NRT Reference](../02_Cloud_Services/01_Overview/01_Cloud_NRT_Transformation_Reference.md)
