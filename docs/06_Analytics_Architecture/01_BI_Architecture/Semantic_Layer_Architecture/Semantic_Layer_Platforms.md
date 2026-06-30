---
title: Semantic Layer Platforms
section: "08.01"
status: complete
template: concept
last_reviewed: 2026-06-30
owner: architecture-team
tags: [analytics, semantics, platforms]
canonical: true
---

# Semantic Layer Platforms

## Context

The semantic layer pattern is implemented differently across BI and metrics platforms. This document compares **how analytics tools realize** the semantic layer—not the abstract modeling pattern.

**Canonical modeling reference:** [Semantic Layer](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/03_Semantic_Layer.md)

## Platform patterns

| Platform | Semantic artifact | Strengths | Considerations |
| --- | --- | --- | --- |
| **Looker (LookML)** | LookML models and explores | Git-based, reusable views, strong embedding | Looker-centric; multi-BI requires export or API |
| **Power BI** | Dataset / semantic model (Tabular) | Microsoft ecosystem, DAX measures, wide adoption | Logic can fragment across workspaces without governance |
| **Tableau** | Logical layer + relationships | Visual modeling, broad connector support | Less headless; metric logic in calculated fields risk |
| **dbt + MetricFlow** | dbt models + YAML metrics | Warehouse-native, version-controlled, headless-ready | Requires SQL literacy; BI is downstream |
| **AtScale** | Universal semantic layer | Multi-BI, OLAP acceleration, enterprise scale | Additional platform cost and ops |
| **Cube** | Semantic layer + API | Headless, dev-friendly, open source option | Smaller enterprise support ecosystem |

## Selection criteria

| Criterion | Weight for most enterprises |
| --- | --- |
| Alignment with primary BI tool | High |
| Headless / API consumption need | Medium–High (growing with AI) |
| Multi-cloud / multi-warehouse support | Medium |
| Git-based versioning and CI/CD | High |
| Row-level security integration | High |
| Total cost of ownership | Medium |

## Implementation patterns by platform

### Looker / LookML

- Define **views** mapped to warehouse tables; **explores** join views.
- Certified measures in LookML; prohibit duplicate calculations in dashboards.
- Use `description` fields linked to [Business Glossary](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/01_Business_Glossary.md) term IDs.

### Power BI

- Centralize certified datasets in a **shared workspace** or Fabric semantic model.
- Use **calculation groups** and named measures; avoid report-level DAX for enterprise KPIs.
- Deploy via XMLA/TMSL pipelines for version control.

### dbt + MetricFlow

- Physical layer in dbt models; metrics in `metrics:` YAML referencing [Metrics Layer](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/02_Metrics_Layer.md) IDs.
- Expose via MetricFlow API for headless and multi-BI consumption.

## Anti-patterns

| Anti-pattern | Platform symptom |
| --- | --- |
| Report-level calculations | DAX/LOD in individual Tableau workbooks or Power BI reports |
| Unmanaged dataset sprawl | Hundreds of Power BI datasets with overlapping measures |
| LookML fork per team | Duplicate `revenue` definitions across models |

## Related topics

- [Semantic Layer Strategy](Semantic_Layer_Strategy.md) — build vs buy and rollout
- [Semantic Layer (modeling)](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/03_Semantic_Layer.md) — canonical pattern
- [Headless BI Architecture](Headless_BI_Architecture.md) — API consumption
- [Business Definitions](Business_Definitions.md) — surfacing glossary in BI tools

## ADR reference

- [ADR 002 Semantic Layer Strategy](../../../00_Architecture_Governance/03_Architecture_Decision_Records/Analytics_Architecture/ADR_002_Semantic_Layer_Strategy.md)
