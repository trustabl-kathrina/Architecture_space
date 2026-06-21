---
title: SCD Type 2 Implementation Patterns
section: "02.02.04.01.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [scd, type-2]
canonical: true
---
# SCD Type 2 Implementation Patterns

Track full history with **valid_from**, **valid_to**, **is_current**.

## MERGE logic

```sql
MERGE INTO dim.product t
USING changes s ON t.product_id = s.product_id AND t.is_current = TRUE
WHEN MATCHED AND t.price <> s.price THEN UPDATE SET valid_to = s.change_ts, is_current = FALSE;
-- Follow with INSERT for new current row
```

## dbt snapshots

```yaml
snapshots:
  - name: product_snapshot
    strategy: timestamp
    updated_at: updated_at
    unique_key: product_id
```

## Storage considerations

- Index on `(business_key, is_current)`.
- Periodic archive of expired rows to cold storage.
