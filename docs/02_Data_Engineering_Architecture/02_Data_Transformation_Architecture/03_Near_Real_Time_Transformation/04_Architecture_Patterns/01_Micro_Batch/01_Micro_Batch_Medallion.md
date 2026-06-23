---
title: Micro-Batch Medallion
section: "02.02.03.04.01"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [medallion, nrt]
canonical: true
---
# Micro-Batch Medallion Architecture

## Layer flow

```mermaid
flowchart TB
  B[Bronze_raw_append] --> S[Silver_dedup_MERGE]
  S --> G[Gold_aggregates]
```

| Layer | NRT behavior | Storage |
| --- | --- | --- |
| Bronze | Append-only, minimal transform | Raw Delta/Iceberg |
| Silver | MERGE, conform, DQ gates | Curated Delta |
| Gold | Windowed aggregates or batch refresh | Mart tables |

## Incremental silver rules

- **Primary key** enforced at silver MERGE.
- **Late events** handled via watermark + optional side output quarantine.
- **Schema evolution** â€” additive columns only without migration window.

## Related

- [Medallion Implementation](../../../04_Shared_Foundations/01_Fundamentals/03_Medallion_And_Zones/01_Medallion_Implementation.md)
