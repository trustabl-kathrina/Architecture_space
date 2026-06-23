---
title: Dependency Management for Transforms
section: "02.02.01.08"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dependencies, dag, batch]
canonical: true
---
# Dependency Management for Transforms

## Dependency types

| Type | Example |
| --- | --- |
| **Data** | Silver depends on bronze partition |
| **Schema** | Mart depends on dimension SCD completion |
| **Operational** | Quality gate pass before gold publish |
| **Cross-domain** | Finance mart after GL close event |

## DAG design

```mermaid
flowchart LR
  Bronze --> Silver
  Silver --> Quality[Quality_Gate]
  Quality --> Gold
  Gold --> Mart
```

## Failure handling

- Block downstream on upstream failure
- Allow partial partition success with quarantine tables
- Document explicit vs implicit dependencies in catalog
