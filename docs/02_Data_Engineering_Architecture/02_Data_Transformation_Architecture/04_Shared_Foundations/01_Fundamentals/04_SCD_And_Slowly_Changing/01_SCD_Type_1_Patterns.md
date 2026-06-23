---
title: SCD Type 1 Implementation Patterns
section: "02.02.04.01.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [scd, type-1]
canonical: true
---
# SCD Type 1 Implementation Patterns

**Type 1** overwrites attribute values â€” no history preserved.

## SQL pattern

```sql
MERGE INTO dim.customer t
USING staging.customer s ON t.customer_id = s.customer_id
WHEN MATCHED THEN UPDATE SET name = s.name, email = s.email, updated_at = CURRENT_TIMESTAMP();
```

## When to use

- Correcting errors, not tracking history.
- Attributes where history has no analytic value (e.g., current phone number display).

## Batch vs NRT

| Mode | Approach |
| --- | --- |
| Batch | Nightly MERGE from staging |
| NRT | Micro-batch MERGE on CDC stream |
| Streaming | Flink temporal table join + upsert sink |
