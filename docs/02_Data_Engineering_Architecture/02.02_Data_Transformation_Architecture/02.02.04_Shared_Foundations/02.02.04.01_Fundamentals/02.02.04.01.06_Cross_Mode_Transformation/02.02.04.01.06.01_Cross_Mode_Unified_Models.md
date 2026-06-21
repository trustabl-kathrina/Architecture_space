---
title: Cross-Mode Unified Models
section: "02.02.04.01.06"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [batch, streaming, unified]
canonical: true
---
# Cross-Mode Transformation (Batch + Stream Unified Models)

## Lambda vs Kappa vs unified

| Architecture | Description |
| --- | --- |
| **Lambda** | Batch + speed layer merge |
| **Kappa** | Single stream reprocess for history |
| **Unified (lakehouse)** | Same Delta/Iceberg tables; batch backfill + stream incremental |

## Unified silver table

```mermaid
flowchart TB
  Batch[Batch_MERGE] --> Silver[(Silver_Delta)]
  Stream[Stream_MERGE] --> Silver
  Silver --> Gold[Gold_Marts]
```

## Rules

1. Same MERGE keys and column contracts for batch and stream writers.
2. Batch reconciles stream gaps nightly.
3. Single catalog registration for both paths.
