---
title: Databricks Trigger Transforms
section: "02.02.03.02.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [databricks, trigger, nrt]
canonical: true
---
# Databricks Trigger-Based Transforms

## Delta Live Tables (DLT)

DLT pipelines support **triggered** or **continuous** execution for bronzeâ†’silverâ†’gold with declarative expectations.

```python
@dlt.table(name="silver_customers")
@dlt.expect_or_drop("valid_id", "customer_id IS NOT NULL")
def silver_customers():
    return dlt.read_stream("bronze_customers").dropDuplicates(["customer_id"])
```

## Trigger modes

| Mode | Latency | Cost |
| --- | --- | --- |
| Continuous | Lowest | Highest |
| Triggered (1â€“30m) | NRT tiers | Predictable |
| Scheduled (batch) | Hours | Lowest |

## MERGE streaming sink

Use `foreachBatch` with Delta `merge` for CDC silver:

```python
def upsert_batch(batch_df, batch_id):
    batch_df.createOrReplaceTempView("updates")
    spark.sql("""
        MERGE INTO silver.orders t USING updates s ON t.id = s.id
        WHEN MATCHED THEN UPDATE SET *
        WHEN NOT MATCHED THEN INSERT *
    """)
```

## Related

- [CDC Silver Merge](../../04_Architecture_Patterns/01_Micro_Batch/02_CDC_Silver_Merge.md)
