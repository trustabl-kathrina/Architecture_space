---
title: Databricks Feature Store
section: "08.05.07.04"
status: stub
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [feature-store, mlops, cloud-implementations]
canonical: true
---
# Databricks Feature Store

## Context

Unity Catalog–integrated feature store for lakehouse training and serving. This topic is part of **08.05 Feature Store Architecture** under `07_Cloud_Implementations`.

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

Extend this diagram for `Databricks Feature Store`-specific components, storage engines, and control-plane integrations as the topic is elaborated.

## Related

- [Batch Features](../05_Feature_Engineering/01_Batch_Features.md)
- [Multi Cloud](../10_Reference_Architectures/04_Multi_Cloud.md)
