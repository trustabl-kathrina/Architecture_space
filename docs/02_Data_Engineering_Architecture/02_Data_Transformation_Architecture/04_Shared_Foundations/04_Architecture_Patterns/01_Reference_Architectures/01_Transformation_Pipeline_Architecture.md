---
title: Transformation Pipeline Architecture
section: "02.02.04.04.01"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [pipeline, architecture]
canonical: true
---
# Transformation Pipeline Architecture

## Layers

| Stage | Responsibility |
| --- | --- |
| **Ingest handoff** | Bronze landing complete signal |
| **Transform** | Business rules, conform, SCD |
| **Quality** | Tests, quarantine |
| **Publish** | Gold marts, API export |
| **Observe** | Metrics, lineage, cost |

## CI/CD

Git â†’ PR â†’ unit tests â†’ deploy to dev â†’ integration â†’ prod promotion with schema compatibility check.
