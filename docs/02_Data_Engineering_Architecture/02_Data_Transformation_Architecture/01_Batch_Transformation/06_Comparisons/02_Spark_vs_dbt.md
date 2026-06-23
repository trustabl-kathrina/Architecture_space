---
title: Spark vs dbt Comparison
section: "02.02.01.06"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [spark, dbt]
canonical: true
---
# Spark vs dbt

| Dimension | Apache Spark | dbt |
| --- | --- | --- |
| Primary API | Python/Scala/SQL DataFrames | SQL + Jinja |
| Data location | Lake files (Parquet/Delta) | Warehouse tables |
| Best scale | TB+ distributed file processing | Warehouse-native TB via push-down |
| Lineage/tests | External (OpenLineage, custom) | Built-in |
| Streaming | Structured Streaming | Streams/tasks (warehouse-specific) |
| Portability | High across clouds | Tied to warehouse dialect |
| Team profile | Data engineering / ML | Analytics engineering |

## Hybrid pattern

Spark builds silver lake tables; dbt builds gold marts in warehouse over external/silver tables.
