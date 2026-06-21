---
title: Informatica Matillion Cross-Cloud
section: "02.02.01.02.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [informatica, matillion, cross-cloud]
canonical: true
---
# Informatica / Matillion Cross-Cloud

Enterprise iPaaS and cloud ELT tools support **multi-cloud targets** with push-down SQL.

| Tool | Strength | Cross-cloud pattern |
| --- | --- | --- |
| **Informatica IDMC** | Governance, lineage | Hybrid: on-prem extract â†’ cloud transform |
| **Matillion** | Warehouse push-down | Same design, deploy to BQ/Snowflake/Databricks |

## Selection criteria

- Existing Informatica skill base â†’ IDMC.
- Cloud-native ELT â†’ Matillion or dbt.
