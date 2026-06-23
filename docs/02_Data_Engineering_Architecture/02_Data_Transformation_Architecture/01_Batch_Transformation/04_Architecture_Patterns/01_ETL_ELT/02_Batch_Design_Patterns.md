---
title: Batch Design Patterns
section: "02.02.01.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [batch, patterns, etl]
canonical: true
---
# Batch Design Patterns

## Core patterns

| Pattern | Description |
| --- | --- |
| **Full refresh** | Rebuild table each run; simple, costly at scale |
| **Incremental append** | New partitions only; requires late-data handling |
| **Merge/upsert** | SCD and CDC silver with business keys |
| **Snapshot** | Point-in-time copy for regulatory reporting |
| **Partition swap** | Build new partition then atomic swap |

## Medallion alignment

- **Bronze**: append-only, minimal transform
- **Silver**: dedup, conform, merge CDC
- **Gold**: aggregate, denormalize for consumption

## Related

- [Medallion Implementation](../../../04_Shared_Foundations/01_Fundamentals/03_Medallion_And_Zones/01_Medallion_Implementation.md)
