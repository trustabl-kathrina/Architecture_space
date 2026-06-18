---
title: README
section: "02.01"
status: stub
template: overview
last_reviewed: 2026-06-19
owner: architecture-team
tags: []
canonical: true
---

# 02.01 Data Ingestion Architecture

> Status: see ingestion mode and shared foundation folders below

## Purpose

How data enters the platform — by latency class: **batch**, **streaming**, and **near-real-time** ingestion, plus shared pipeline and framework guidance.

## Numbering standard

All modes use hierarchical IDs aligned with `02.01.02_Streaming`:

```
02.01.MM                    Ingestion mode (01 batch, 02 streaming, 03 near-RT, 04 shared)
02.01.MM.SS_Subsection/     Top subsection (01–09)
02.01.MM.SS.TT_TopicGroup/  Topic group folder
02.01.MM.SS.TT.NN_Topic.md  Topic file
```

**Cloud Services provider slots** (`.02` subsection): `.01` Overview · `.02` GCP · `.03` AWS · `.04` Azure · `.05` Cross-Cloud

**Front matter:** mode READMEs use `section: "02.01.0N"`; all nested topic files use `section: "02.01"`.

## Ingestion modes

| # | Mode | Path | Description |
| --- | --- | --- | --- |
| 02.01.01 | [Batch Ingestion](02.01.01_Batch_Ingestion/README.md) | `02.01.01_*` | Scheduled bulk loads, file landing zones, ETL/ELT batch connectors |
| 02.01.02 | [Streaming](02.01.02_Streaming/README.md) | `02.01.02_*` | Event-driven architecture, Kafka/Pub/Sub, CDC, stream processing, benchmarks |
| 02.01.03 | [Near-Real-Time Ingestion](02.01.03_Near_Real_Time_Ingestion/README.md) | `02.01.03_*` | Micro-batch, latency-sensitive pipelines between batch and streaming |

## Shared foundations

| # | Topic | Path | Description |
| --- | --- | --- | --- |
| 02.01.04 | [Shared Foundations](02.01.04_Shared_Foundations/README.md) | `02.01.04_*` | Vision, strategy, pipeline architecture, enterprise frameworks, cross-mode ingestion |

## Subsection slot map (batch / streaming / near-RT)

| Slot | Batch | Streaming | Near-RT |
| --- | --- | --- | --- |
| .01 | Fundamentals | Fundamentals | Fundamentals |
| .02 | Cloud Services | Cloud Services | Cloud Services |
| .03 | Open Source | Open Source | — |
| .04 | Architecture Patterns | Architecture Patterns | Architecture Patterns |
| .05 | Benchmarks | Benchmarks | Benchmarks |
| .06 | Comparisons | Comparisons | Comparisons |
| .07 | Interview Questions | Interview Questions | Interview Questions |
| .08 | Integration Patterns | Integration Patterns | Integration Patterns |
| .09 | Reference Architectures | Reference Architectures | Reference Architectures |

## Related

- [02 Data Engineering Architecture](../README.md)
- [Architecture Space](../../README.md)
