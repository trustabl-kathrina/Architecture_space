---
title: Snowflake Overview
section: "02.02.01.03.05"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [snowflake, sql, top-10]
canonical: true
---
# 1. Snowflake Overview

## What is 

**Snowflake** is the cloud data warehouse with elastic SQL transforms, streams/tasks, and Snowpark.

## Mental model

`mermaid
flowchart LR
  In[Raw_or_Staged_Input] --> T[Snowflake_Transform]
  T --> Out[Curated_Output]
`

- **You own** business rules, schema contracts, test suites, and deployment pipelines.
- **Platform owns** compute scheduling, optimizer, and managed runtime (where applicable).

## When to use Snowflake

| Use when... | Consider alternatives when... |
| --- | --- |
| Transform workload matches engine strengths | Simpler SQL-only path exists in warehouse |
| Team has platform expertise | Sub-second streaming only -> dedicated stream processor |
| Medallion or dimensional modeling at scale | Lightweight one-off scripts -> simpler tooling |

## Learning path

Continue to [Architecture](02_Architecture.md) or [Scenarios](04_Scenarios.md).

## Related

- [Official documentation](https://docs.snowflake.com/)
- [Transformation mode](../../README.md)
