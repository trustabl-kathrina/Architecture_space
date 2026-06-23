---
title: BigQuery Transformation Architecture
section: "02.02.01.02.02.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, bigquery]
canonical: true
---
# 2. BigQuery Transformation Architecture

## Compute models

| Model | Character |
| --- | --- |
| **On-demand** | Pay per bytes scanned; simple start |
| **Editions / reservations** | Slot capacity; predictable cost at scale |
| **Autoscaling** | Burst within reservation |

## Storage layout

- **Partitioned tables** - `DATE`/`TIMESTAMP` partition pruning.
- **Clustering** - co-locate filter columns within partitions.
- **Materialized views** - pre-aggregated refresh (auto or manual).

## ELT topology on GCP

```mermaid
flowchart TB
  GCS[(GCS_Landing)] --> BQ_Load[Load_External_BQ]
  BQ_Load --> Staging[staging_*]
  Staging --> dbt[dbt_Dataform]
  dbt --> Marts[analytics_*]
```

## Related

- [dbt Learning Guide](../../03_Open_Source/03_dbt_Learning_Guide/README.md)
