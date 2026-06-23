---
title: Luigi Overview
section: "02.03.03.09"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [luigi, spotify, open-source, top-10, learning-guide]
canonical: true
---

# 1. Luigi Overview

## What is Luigi?

**Luigi** is Spotify's lightweight Python batch pipeline framework with dependency graphs and target abstractions. Category: **Lightweight Python batch framework**.

## Why Top 10 rank #8?

Ranked in [Top 10 Open Source Orchestration](../01_Overview/01_Top_10_Orchestration_Technologies.md) for adoption in data engineering, OSS community, and production fit â€” **excluding** hyperscaler managed services covered in [Cloud Services](../../02_Cloud_Services/README.md).

## When to use Luigi

| Use whenâ€¦ | Consider alternatives whenâ€¦ |
| --- | --- |
| Lightweight Python batch framework matches your platform strategy | Managed cloud-only standard â†’ [Cloud Services](../../02_Cloud_Services/README.md) |
| Team prefers Luigi model | Portable DAG mesh â†’ **Airflow** or **Prefect** |
| Self-host or bring-your-own K8s | Serverless cloud glue only â†’ Step Functions / Workflows in Cloud Services |

## Learning path

Continue to [Architecture](02.03.03.09.01_Architecture.md) or [Scenarios](02.03.03.09.01_Scenarios.md).
## Related

- [Top 10 README](../README.md)
- [Luigi hub](../README.md)
