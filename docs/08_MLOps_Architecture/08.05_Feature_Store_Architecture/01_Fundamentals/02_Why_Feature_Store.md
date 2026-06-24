---
title: Why Feature Store
section: "08.05.01.02"
status: complete
template: overview
last_reviewed: 2026-06-24
owner: architecture-team
tags: [feature-store, mlops, fundamentals]
canonical: true
---
# Why Feature Store

## Problem

Without a feature store, ML teams repeatedly rebuild the same transformations in notebooks, ad hoc SQL, and serving microservices. Training pipelines read historical snapshots while serving code recomputes features at request time — divergent logic causes **training-serving skew**, silent model degradation, and slow time-to-production for new models.

## Business drivers

| Driver | Without feature store | With feature store |
| --- | --- | --- |
| **Time to market** | Weeks to wire features per model | Hours: bind registered feature views |
| **Model quality** | Skew and leakage from inconsistent joins | Point-in-time correct training data |
| **Reuse** | Siloed feature code per squad | Shared catalog across fraud, churn, recommenders |
| **Governance** | Unknown lineage and ownership | Registered owners, SLAs, and quality gates |
| **Cost** | Duplicate batch jobs and serving compute | Centralized materialization and caching |

## Technical drivers

- **Consistent semantics**: One transformation definition for offline and online paths.
- **Low-latency serving**: Pre-materialized online features instead of on-the-fly joins at inference.
- **Reproducibility**: Versioned feature definitions tied to model training runs.
- **Operational safety**: Schema evolution, backfill, and monitoring as first-class operations.

## Anti-patterns the feature store replaces

1. **Notebook-only features** — logic never promoted to production pipelines.
2. **Serving-time mega-joins** — 50 ms budgets blown by warehouse queries per request.
3. **Copy-paste SQL** — `SUM(amount_7d)` rewritten in five repos with subtle differences.
4. **Shadow datasets** — training exports that no longer match production feature timing.

## Adoption path

| Maturity | Characteristics |
| --- | --- |
| **L1 Central catalog** | Documented features; manual pipelines |
| **L2 Offline store** | Batch materialization + point-in-time training API |
| **L3 Online store** | Real-time serving with sync from streaming/batch |
| **L4 Governed mesh** | Domain-owned feature products with platform guardrails |

## Related

- [What Is Feature Store](01_What_Is_Feature_Store.md)
- [Training Serving Skew](04_Training_Serving_Skew.md)
- [Feature Governance](../06_Feature_Governance/04_Ownership.md)
