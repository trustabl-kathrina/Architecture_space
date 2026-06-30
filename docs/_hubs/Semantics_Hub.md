---
title: Semantics Hub
section: "00"
status: complete
template: hub
last_reviewed: 2026-06-30
owner: architecture-team
tags: [semantics, hub]
canonical: true
---

# Semantics Hub

Canonical navigation hub for business semantics—glossary, metrics, semantic layer, semantic data products, analytics consumption, and enterprise governance.

## Content split

| Concern | Where to maintain | Example content |
| --- | --- | --- |
| **What** terms and metrics mean | Modeling pillar | Definition of "Active Customer", revenue formula |
| **How** semantics are modeled | Modeling pillar | Semantic model structure, metric grain |
| **How** analytics consumes semantics | Analytics pillar | LookML patterns, KPI catalog, headless API |
| **Who** governs and approves | Governance pillar | Stewardship workflow, certification gates |
| **Strategic choices** | ADRs | Platform selection, build vs buy |

## Modeling pillar (canonical definitions)

Section **05.03.02** — [Semantic Modeling](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/README.md)

| Topic | Status | Description |
| --- | --- | --- |
| [Business Glossary](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/01_Business_Glossary.md) | complete | Enterprise business term catalog |
| [Metrics Layer](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/02_Metrics_Layer.md) | complete | Certified measure definitions and calculation logic |
| [Semantic Layer](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/03_Semantic_Layer.md) | complete | Logical consumption abstraction |
| [Business Semantic Model](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/04_Business_Semantic_Model.md) | stub | Entity-relationship business view |
| [Semantic Model](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/05_Semantic_Model.md) | stub | Detailed model structure |
| [Semantic Standards](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/06_Semantic_Standards.md) | stub | Naming and definition conventions |
| [Semantic Governance](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/07_Semantic_Governance.md) | stub | Modeling-side ownership |
| [Semantic Interoperability](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/08_Semantic_Interoperability.md) | stub | Cross-domain alignment |
| [Semantic Data Products](../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/09_Semantic_Data_Products.md) | complete | Semantics as governed data products |

Parent: [Modern Modeling](../04_Data_Modeling_Architecture/03_Modern/README.md) · [Data Modeling Architecture](../04_Data_Modeling_Architecture/README.md)

## Analytics pillar (implementation and consumption)

[Semantic Layer Architecture](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/)

| Topic | Canonical? | Description |
| --- | --- | --- |
| [Semantic Layer Strategy](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Semantic_Layer_Strategy.md) | analytics | Rollout and build vs buy |
| [Semantic Layer Platforms](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Semantic_Layer_Platforms.md) | analytics | Looker, Power BI, dbt, AtScale patterns |
| [Enterprise Metrics Layer](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Enterprise_Metrics_Layer.md) | links to modeling | Deploy certified metrics in BI |
| [Business Definitions](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Business_Definitions.md) | links to modeling | Surface glossary in dashboards |
| [KPI Standardization](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/KPI_Standardization.md) | links to modeling | KPI catalog in analytics |
| [Semantic Data Products](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Semantic_Data_Products.md) | links to modeling | Analytics consumption packaging |
| [Headless BI Architecture](../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Headless_BI_Architecture.md) | analytics | API-driven semantic consumption |

Parent: [Analytics Architecture](../06_Analytics_Architecture/README.md)

## Governance pillar (operating model)

[Semantic Governance](../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/)

| Topic | Description |
| --- | --- |
| [Enterprise Semantics](../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/Enterprise_Semantics.md) | Enterprise operating model |
| [Semantic Governance Framework](../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/Semantic_Governance_Framework.md) | Lifecycle and quality gates |
| [Business Definition Governance](../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/Business_Definition_Governance.md) | Term approval workflow |
| [Semantic Quality Framework](../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/Semantic_Quality_Framework.md) | Quality dimensions |
| [KPI Standardization (Governance)](../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/KPI_Standardization.md) | KPI certification rules |

Parent: [Data Governance And Metadata](../00_Architecture_Governance/10_Data_Governance_And_Metadata/README.md)

## Architecture decision records

- [ADR 009 Semantic Governance Strategy](../00_Architecture_Governance/03_Architecture_Decision_Records/Governance_And_Metadata/ADR_009_Semantic_Governance_Strategy.md)
- [ADR 007 Semantic Layer Strategy (Data)](../00_Architecture_Governance/03_Architecture_Decision_Records/Data_Architecture/ADR_007_Semantic_Layer_Strategy.md)
- [ADR 002 Semantic Layer Strategy (Analytics)](../00_Architecture_Governance/03_Architecture_Decision_Records/Analytics_Architecture/ADR_002_Semantic_Layer_Strategy.md)

## Related hubs and sections

- [Data Mesh Hub](Data_Mesh_Hub.md) — domain data products and federated governance
- [Data Product Architecture](../06_Data_Product_Architecture/README.md) — physical data product lifecycle
