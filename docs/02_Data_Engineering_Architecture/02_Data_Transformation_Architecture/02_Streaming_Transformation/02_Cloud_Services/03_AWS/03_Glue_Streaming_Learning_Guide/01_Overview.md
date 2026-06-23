---
title: AWS Glue Streaming ETL Overview
section: "02.02.02.02.03.03"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, glue, streaming, learning-guide]
canonical: true
---
# 1. AWS Glue Streaming ETL Overview

## What is 

**AWS Glue Streaming ETL** is managed Spark Structured Streaming jobs on Glue 4.0+.

## Mental model

`mermaid
flowchart LR
  In[Raw_or_Staged_Input] --> T[Glue Streaming_Transform]
  T --> Out[Curated_Output]
`

- **You own** business rules, schema contracts, test suites, and deployment pipelines.
- **Platform owns** compute scheduling, optimizer, and managed runtime (where applicable).

## When to use Glue Streaming

| Use when... | Consider alternatives when... |
| --- | --- |
| Transform workload matches engine strengths | Simpler SQL-only path exists in warehouse |
| Team has platform expertise | Sub-second streaming only -> dedicated stream processor |
| Medallion or dimensional modeling at scale | Lightweight one-off scripts -> simpler tooling |

## Learning path

Continue to [Architecture](02_Architecture.md) or [Scenarios](04_Scenarios.md).

## Related

- [Official documentation](https://docs.aws.amazon.com/glue/latest/dg/add-job-streaming.html)
- [Streaming Cloud Services](../../README.md)
