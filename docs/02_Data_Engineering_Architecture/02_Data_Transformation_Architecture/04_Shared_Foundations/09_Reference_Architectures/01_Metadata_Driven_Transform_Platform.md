---
title: Metadata-Driven Transform Platform
section: "02.02.04.09"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [reference, metadata]
canonical: true
---
# Metadata-Driven Transform Platform Reference

## Concept

Transform definitions stored as **metadata** (YAML/JSON in Git); engine compiles to Spark SQL/dbt at runtime.

```mermaid
flowchart LR
  Meta[Transform_Metadata] --> Compiler[Pipeline_Compiler]
  Compiler --> Spark[Spark_Job]
  Compiler --> dbt[dbt_Models]
  Spark --> Lake[(Lakehouse)]
  dbt --> Lake
```

## Components

- **Registry** â€” entity/attribute business glossary.
- **Rules engine** â€” mapping source â†’ target columns.
- **Lineage** â€” automatic from metadata graph.
- **Orchestrator** â€” executes compiled artifacts.

## Benefits

- Reduce copy-paste across domains.
- Enforce naming and DQ standards centrally.
