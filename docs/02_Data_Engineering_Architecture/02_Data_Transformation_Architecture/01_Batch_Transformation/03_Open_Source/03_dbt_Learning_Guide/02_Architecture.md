---
title: dbt Architecture
section: "02.02.01.03.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dbt, architecture]
canonical: true
---
# 2. dbt Architecture

## Project structure

| Artifact | Purpose |
| --- | --- |
| `dbt_project.yml` | Project config, materializations defaults |
| `models/` | Layered SQL (`staging/`, `intermediate/`, `marts/`) |
| `seeds/` | CSV reference data |
| `snapshots` | SCD Type 2 for changing sources |
| `tests/` | Schema + singular tests |
| `macros/` | Jinja SQL functions |

## Execution flow

```mermaid
flowchart TB
  Parse[Parse_Project] --> Compile[Jinja_Expand]
  Compile --> DAG[Model_DAG]
  DAG --> Run[Execute_SQL]
  Run --> Test[Run_Tests]
  Test --> Docs[Generate_Docs]
```

## Materialization strategies

| Strategy | Use case |
| --- | --- |
| `view` | Lightweight staging |
| `table` | Full rebuild marts |
| `incremental` | Append/merge large fact tables |
| `ephemeral` | CTE-like intermediate (no object) |

## Incremental patterns

- **`merge` strategy** - upsert on unique key (Snowflake, BQ, Databricks).
- **`delete+insert`** - partition replace.
- **`microbatch`** - dbt 1.9+ time-window incremental.

## Related

- [BigQuery dbt Learning Guide](../../02_Cloud_Services/02_GCP/04_BigQuery_SQL_Learning_Guide/README.md)
