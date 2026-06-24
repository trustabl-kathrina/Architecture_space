---
title: Hybrid Feature Store
section: "08.05.03.03"
status: stub
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [feature-store, mlops, architectural-patterns]
canonical: true
---
# Hybrid Feature Store

## Context

Combined batch historical and real-time speed layers with reconciliation policies. This topic is part of **08.05 Feature Store Architecture** under `03_Architectural_Patterns`.

## Scope

| In scope | Out of scope |
| --- | --- |
| Architectural patterns, integration points, and enterprise design choices | Vendor pricing, license negotiations, and hands-on CLI tutorials |
| How this capability fits offline/online feature lifecycles | Individual model hyperparameter tuning |
| Governance, security, and operational considerations | One-off notebook experiments without platform promotion |

## Key design considerations

- Align **entity keys** and **event time** semantics with upstream data products.
- Define **freshness SLAs** and monitoring for materialization jobs affecting this area.
- Plan **schema evolution** and backward-compatible feature view versions.
- Document **ownership** and escalation paths for production incidents.
- Validate **training-serving consistency** when promoting feature changes.

## Architecture notes

```mermaid
flowchart LR
    Sources[Data Sources] --> Transform[Feature Pipelines]
    Transform --> Offline[(Offline Store)]
    Transform --> Online[(Online Store)]
    Registry[Feature Registry] --> Transform
    Offline --> Training[Training]
    Online --> Serving[Inference]
```

Extend this diagram for `Hybrid Feature Store`-specific components, storage engines, and control-plane integrations as the topic is elaborated.

## Related

- [Online vs Offline](../01_Fundamentals/03_Online_vs_Offline.md)
- [Streaming Feature Store](04_Streaming_Feature_Store.md)
