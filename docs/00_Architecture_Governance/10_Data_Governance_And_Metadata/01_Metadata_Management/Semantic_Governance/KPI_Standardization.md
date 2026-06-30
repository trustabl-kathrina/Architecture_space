---
title: KPI Standardization
section: "00.10.01"
status: complete
template: concept
last_reviewed: 2026-06-30
owner: architecture-team
tags: [governance, semantics, kpi]
canonical: false
---

# KPI Standardization

## Context

This document defines **governance-side KPI standards**—enterprise rules for KPI registration, ownership, and certification. Analytics implementation patterns are documented separately.

**Canonical metric definitions:** [Metrics Layer](../../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/02_Metrics_Layer.md)

**Analytics implementation:** [KPI Standardization (Analytics)](../../../../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/KPI_Standardization.md)

## Governance rules

1. Every enterprise KPI must register in the KPI catalog before appearing in executive reporting.
2. Each KPI maps to exactly one **certified metric** in the metrics layer.
3. KPI `tier` (executive / operational / exploratory) determines certification requirements.
4. Business executive sponsors own KPI meaning; data stewards own catalog metadata quality.
5. New KPI requests require duplicate check against existing catalog entries.

## Certification requirements by tier

| Tier | Business owner approval | Metric certification | Dashboard review |
| --- | --- | --- | --- |
| **Executive** | Required | Required | Required before publish |
| **Operational** | Required | Required | Recommended |
| **Exploratory** | Optional | Not required | Sandbox only |

## Related topics

- [KPI Standardization (Analytics)](../../../../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/KPI_Standardization.md)
- [Metrics Layer (modeling)](../../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/02_Metrics_Layer.md)
- [Business Definition Governance](Business_Definition_Governance.md)
- [Semantic Governance Framework](Semantic_Governance_Framework.md)
