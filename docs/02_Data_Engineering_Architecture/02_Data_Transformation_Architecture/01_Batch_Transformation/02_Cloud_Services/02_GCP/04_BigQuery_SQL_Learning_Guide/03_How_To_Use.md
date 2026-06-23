---
title: BigQuery SQL How To Use
section: "02.02.01.02.02.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [batch transformation, learning-guide]
canonical: true
---
# 3. BigQuery SQL How To Use

## Prerequisites

- Cloud/project access with transform admin role
- Source and sink endpoints provisioned
- Git repo or artifact store for pipeline code

## Setup workflow

| Step | Action |
| ---: | --- |
| 1 | Create service account / IAM role with least privilege |
| 2 | Configure network (VPC peering / private endpoints) |
| 3 | Author transform in dev environment |
| 4 | Unit test on sample partition |
| 5 | Deploy via CI/CD to staging |
| 6 | Soak test with production-like volume |
| 7 | Promote to prod with rollback tag |

## IAM checklist (02.02.01.02.02.04 BigQuery SQL)

| Permission | Purpose |
| --- | --- |
| Read source | Input datasets/topics |
| Write sink | Curated output tables/files |
| Secrets | API keys, JDBC passwords |
| Logging | Metrics and audit trail |

## CLI / code example

```bash
# Deploy transform job (adapt per platform)
export TRANSFORM_ENV=prod
./deploy.sh --job 02.02.01.02.02.04_BigQuery_SQL_silver_merge
```

```python
# Incremental transform skeleton
def transform_batch(df):
    return df.filter("status IS NOT NULL").dropDuplicates(["id"])
```

## Deployment pipeline

``` mermaid
flowchart LR
  Dev[Dev] --> CI[CI_Tests]
  CI --> Stg[Staging]
  Stg --> Prod[Production]
```

## Testing

- **Unit** - pure functions on fixture DataFrames.
- **Integration** - write to temp schema, assert row counts.
- **Regression** - compare checksum vs golden partition.

## Operate

- Monitor runtime, shuffle spill, failed records.
- Alert when duration > 2x baseline.
- Document backfill: same MERGE logic, wider partition filter.
- Run weekly cost review against budget tags.
- Rotate credentials via secrets manager every 90 days.
- Keep runbook for rollback to prior artifact version in Git tag.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Job timeout | Skew / too much shuffle | Repartition, salting |
| Auth failure | Expired SA key | Rotate secret |
| Empty output | Wrong filter predicate | Validate staging row counts |
| Duplicate rows | Missing dedup key | Add MERGE on business key |

## Related

- [Overview](README.md)
- [Official documentation](https://cloud.google.com/bigquery/docs)
