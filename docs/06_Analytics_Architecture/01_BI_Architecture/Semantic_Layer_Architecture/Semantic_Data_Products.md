---
title: Semantic Data Products
section: "08.01"
status: complete
template: concept
last_reviewed: 2026-06-30
owner: architecture-team
tags: [analytics, semantics, data-products]
canonical: false
---

# Semantic Data Products

## Context

This document covers how **analytics teams consume and publish** semantic data products—connecting domain semantics to BI workspaces, dashboards, and APIs. The modeling definition and contract structure are canonical elsewhere.

**Canonical source:** [Semantic Data Products (Modeling)](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/09_Semantic_Data_Products.md)

## Analytics consumption patterns

| Pattern | Description | Example |
| --- | --- | --- |
| **Imported semantic model** | Connect BI tool to domain-published model | Power BI dataset from Finance semantic product |
| **Certified explore** | Looker explore backed by domain LookML | `finance_revenue` explore |
| **Metrics API** | Headless consumption for apps | REST/GraphQL endpoint from MetricFlow |
| **Catalog discovery** | Find and request access via data marketplace | Collibra shopping experience |

## Publishing checklist for domain teams

1. Package glossary slice, certified metrics, and semantic model per [modeling spec](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/09_Semantic_Data_Products.md).
2. Register product in catalog with contract, owner, and SLA.
3. Expose consumption interface (BI connection string, API endpoint, or explore name).
4. Document breaking-change policy and version.
5. Provide sample dashboards using only product-certified measures.

## Analytics-specific quality gates

| Gate | Check before publish |
| --- | --- |
| **Reconciliation** | Semantic model totals match physical data product |
| **Certification** | All measures are certified; no exploratory fields in executive tier |
| **Access** | RLS and workspace permissions configured |
| **Lineage** | Catalog shows semantic → physical lineage |
| **Adoption** | At least one certified dashboard references the product |

## Related topics

- [Semantic Data Products (Modeling)](../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/09_Semantic_Data_Products.md) — canonical definition
- [Semantic Layer Strategy](Semantic_Layer_Strategy.md) — rollout strategy
- [Analytics Data Products](../Analytics_Data_Products/KPI_Products.md) — KPI-focused data products
- [Semantic Governance Framework](../../../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/Semantic_Governance_Framework.md)
