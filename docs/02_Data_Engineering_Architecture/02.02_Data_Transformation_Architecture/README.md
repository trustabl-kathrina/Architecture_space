---
title: README
section: "02.02"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [transformation, etl, elt, spark, dbt]
canonical: true
---

# 02.02 Data Transformation Architecture

> Status: expert learning guides - batch, streaming, near-real-time, and shared foundations (464 topics)

## Purpose

How data is **cleansed, enriched, conformed, aggregated, and modeled** across latency classes: batch, streaming, and near-real-time transformation, plus shared ETL/ELT, medallion, and SCD frameworks.

## Numbering standard

Mirrors `02.01` ingestion structure:

```
02.02.MM                    Transformation mode (01 batch, 02 streaming, 03 near-RT, 04 shared)
02.02.MM.SS_Subsection/     Top subsection (.01-.09)
02.02.MM.SS.TT_TopicGroup/  Topic group or learning guide folder
02.02.MM.SS.TT.NN_Topic.md  Topic file (9-module learning guides use .01-.09)
```

**Cloud Services provider slots** (`.02` subsection): `.01` Overview | `.02` GCP | `.03` AWS | `.04` Azure | `.05` Cross-Cloud

**Learning guide module pattern** (9 modules): Overview | Architecture | How To Use | Scenarios | Limitations | Costing | Production Configuration | Evaluation Criteria | Benchmarking

**Front matter:** mode READMEs use `section: "02.02.0N"`; nested topic files use `section: "02.02"` or granular guide IDs.

## Transformation modes

| # | Mode | Path | Description |
| --- | --- | --- | --- |
| 02.02.01 | [Batch Transformation](02.02.01_Batch_Transformation/README.md) | `02.02.01_*` | Spark batch, dbt, Glue ETL, warehouse SQL, medallion batch layers |
| 02.02.02 | [Streaming Transformation](02.02.02_Streaming_Transformation/README.md) | `02.02.02_*` | Flink, Spark Structured Streaming, Kafka Streams, Dataflow, stream-table duality |
| 02.02.03 | [Near-Real-Time Transformation](02.02.03_Near_Real_Time_Transformation/README.md) | `02.02.03_*` | Micro-batch, trigger-based transforms, latency-sensitive silver/gold |

## Shared foundations

| # | Topic | Path | Description |
| --- | --- | --- | --- |
| 02.02.04 | [Shared Foundations](02.02.04_Shared_Foundations/README.md) | `02.02.04_*` | ETL vs ELT strategy, medallion, SCD, enterprise standards, cross-mode patterns |

## Top 10 and cloud learning guides

| Category | Hub | Count |
| --- | --- | ---: |
| Batch Top 10 | [Top 10 Batch Technologies](02.02.01_Batch_Transformation/02.02.01.03_Open_Source/02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md) | 10 guides |
| Streaming Top 10 | [Top 10 Streaming Technologies](02.02.02_Streaming_Transformation/02.02.02.03_Open_Source/02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md) | 10 guides |
| Batch cloud | [Batch Cloud Services](02.02.01_Batch_Transformation/02.02.01.02_Cloud_Services/README.md) | 8 guides (GCP/AWS/Azure) |
| Streaming cloud | [Streaming Cloud Services](02.02.02_Streaming_Transformation/02.02.02.02_Cloud_Services/README.md) | 5 guides |

## Subsection slot map

| Slot | Batch | Streaming | Near-RT | Shared |
| --- | --- | --- | --- | --- |
| .01 | Fundamentals | Fundamentals | Fundamentals | Fundamentals |
| .02 | Cloud Services | Cloud Services | Cloud Services | Cloud overview |
| .03 | Open Source / Top 10 | Open Source / Top 10 | - | - |
| .04 | Architecture Patterns | Architecture Patterns | Architecture Patterns | Patterns |
| .05 | Benchmarks | Benchmarks | Benchmarks | - |
| .06 | Comparisons | Comparisons | Comparisons | - |
| .07 | Interview Questions | Interview Questions | Interview Questions | - |
| .08 | Integration Patterns | Integration Patterns | Integration Patterns | - |
| .09 | Reference Architectures | Reference Architectures | Reference Architectures | Reference |

## Start here

- [Batch Transformation Overview](02.02.01_Batch_Transformation/02.02.01.01_Fundamentals/02.02.01.01.01_Overview/02.02.01.01.01.01_Batch_Transformation_Overview.md)
- [Apache Spark Learning Guide](02.02.01_Batch_Transformation/02.02.01.03_Open_Source/02.02.01.03.02_Apache_Spark_Learning_Guide/README.md)
- [dbt Learning Guide](02.02.01_Batch_Transformation/02.02.01.03_Open_Source/02.02.01.03.03_dbt_Learning_Guide/README.md)
- [Apache Flink Learning Guide](02.02.02_Streaming_Transformation/02.02.02.03_Open_Source/02.02.02.03.02_Apache_Flink_Learning_Guide/README.md)
- [Cloud Batch Reference](02.02.01_Batch_Transformation/02.02.01.02_Cloud_Services/02.02.01.02.01_Overview/02.02.01.02.01.01_Cloud_Batch_Transformation_Reference.md)

## Related

- [02 Data Engineering Architecture](../README.md)
- [02.01 Data Ingestion](../02.01_Data_Ingestion_Architecture/README.md)
- [02.03 Data Orchestration](../02.03_Data_Orchestration_Architecture/README.md)
- [02.05 Data Storage](../02.05_Data_Storage_Architecture/README.md)
