---
title: Kafka Streams Overview
section: "02.02.02.03.04"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [kafka, streaming, top-10]
canonical: true
---
# 1. Kafka Streams Overview

## What is 

**Kafka Streams** is the lightweight stream processing library embedded in Kafka applications.

## Mental model

`mermaid
flowchart LR
  In[Raw_or_Staged_Input] --> T[Kafka Streams_Transform]
  T --> Out[Curated_Output]
`

- **You own** business rules, schema contracts, test suites, and deployment pipelines.
- **Platform owns** compute scheduling, optimizer, and managed runtime (where applicable).

## When to use Kafka Streams

| Use when... | Consider alternatives when... |
| --- | --- |
| Transform workload matches engine strengths | Simpler SQL-only path exists in warehouse |
| Team has platform expertise | Sub-second streaming only -> dedicated stream processor |
| Medallion or dimensional modeling at scale | Lightweight one-off scripts -> simpler tooling |

## Learning path

Continue to [Architecture](02_Architecture.md) or [Scenarios](04_Scenarios.md).

## Related

- [Official documentation](https://kafka.apache.org/documentation/streams/)
- [Transformation mode](../../README.md)
