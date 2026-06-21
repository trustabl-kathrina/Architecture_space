---
title: ETL vs ELT Comparison
section: "02.02.01.06"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [etl, elt]
canonical: true
---
# ETL vs ELT

| Dimension | ETL | ELT |
| --- | --- | --- |
| Transform location | External engine before load | Inside target warehouse/lake |
| Typical tools | Spark, Glue, Informatica | dbt, BigQuery SQL, Snowflake |
| Best when | Heavy cleansing on files, PII masking pre-load | Warehouse compute elastic and cheap |
| Data residency | Transform in controlled VPC | Raw lands first; policy in warehouse |
| Testing | Engine-specific + integration tests | dbt tests + warehouse CI |
| Cost driver | Cluster DPUs / EMR hours | Warehouse credits / slot hours |
| Latency | Extra hop before query | Faster time-to-query on raw |
| Skill set | Spark/Python + SQL | SQL-first analytics engineering |

## Decision guide

Use **ETL** when compliance requires transform before persistence. Use **ELT** when warehouse is the system of record and SQL suffices.
