---
title: Athena SQL Scenarios
section: "02.02.01.02.03.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [batch transformation, learning-guide]
canonical: true
---
# 4. Athena SQL Scenarios

## Enterprise medallion scenario

```mermaid
flowchart TB
  Bronze[Bronze_Raw] --> Silver[Silver_Conformed]
  Silver --> Gold[Gold_Marts]
```

| Layer | 02.02.01.02.03.05 Athena SQL role |
| --- | --- |
| Bronze | Land raw with minimal validation |
| Silver | Dedup, conform types, apply business keys |
| Gold | Aggregates and KPI tables for BI |

## SCD scenario

- **Type 1** â€” overwrite attributes on match.
- **Type 2** â€” close current row, insert new version.
- Use CDC stream or nightly staging diff.

## CDC scenario

```mermaid
sequenceDiagram
  participant DB as Source_DB
  participant CDC as CDC_Reader
  participant T as 02.02.01.02.03.05 Athena SQL
  participant Lake as Silver_Table
  DB->>CDC: Change events
  CDC->>T: Stream/batch
  T->>Lake: MERGE
```

## Conformed dimensions

Shared dim_date, dim_customer built once; fact tables reference surrogate keys.

## Enterprise pattern checklist

- [ ] Business keys documented
- [ ] Quarantine path for bad records
- [ ] Lineage registered in catalog
- [ ] Cost tag per domain

## Related

- [Medallion Implementation](../../../04_Shared_Foundations/01_Fundamentals/03_Medallion_And_Zones/01_Medallion_Implementation.md)
