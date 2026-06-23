---
title: Cloud Batch Transformation Reference Architecture
section: "02.02.01.02.01"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [cloud, batch]
canonical: true
---
# Cloud Batch Transformation Reference Architecture

```mermaid
flowchart TB
  subgraph GCP
    BQ[BigQuery_SQL]
    DP[Dataproc_Spark]
  end
  subgraph AWS
    Glue[Glue_ETL]
    EMR[EMR_Spark]
    ATH[Athena]
  end
  subgraph Azure
    SYN[Synapse_Spark]
    ADF[ADF_Data_Flows]
  end
  Lake[(Object_Storage)] --> DP & Glue & EMR & SYN
  WH[(Warehouse)] --> BQ & ATH
```

| Provider | Primary transform services | Learning guides |
| --- | --- | --- |
| GCP | BigQuery, Dataproc | [BigQuery](../02.02.02_GCP/04_BigQuery_SQL_Learning_Guide/README.md), [Dataproc](../02.02.02_GCP/03_Dataproc_Spark_Learning_Guide/README.md) |
| AWS | Glue, EMR, Athena | [Glue ETL](../02.02.03_AWS/03_Glue_ETL_Learning_Guide/README.md), [EMR](../02.02.03_AWS/04_EMR_Spark_Learning_Guide/README.md) |
| Azure | Synapse, ADF, Fabric | [Synapse](../02.02.04_Azure/03_Synapse_Spark_Learning_Guide/README.md), [ADF Flows](../02.02.04_Azure/04_ADF_Mapping_Data_Flows_Learning_Guide/README.md) |
