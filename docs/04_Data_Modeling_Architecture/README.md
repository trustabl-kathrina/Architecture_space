---
title: README
section: "05"
status: stub
template: overview
last_reviewed: 2026-06-19
owner: architecture-team
tags: [data-modeling]
canonical: true
---

# 05 Data Modeling Architecture

> Status: 0 complete / 0 draft / 0 review / 93+ stub topics

## Purpose

Enterprise data modeling across traditional warehouse patterns, enterprise canonical and MDM models, modern semantic/event/AI modeling, and industry reference models.

## Numbering standard

```
05                    Section
05.01–05.04           Pillar (Traditional, Enterprise, Modern, Industry)
05.01.01              Approach (e.g. Relational, Kimball, Data Vault)
05.01.01.01_Topic.md  Topic file
```

## Pillars

| # | Pillar | Path | Description |
| --- | --- | --- | --- |
| 05.01 | [Traditional](05.01_Traditional/README.md) | Relational, Kimball, Inmon, Data Vault | Classic warehouse and relational modeling |
| 05.02 | [Enterprise](05.02_Enterprise/README.md) | DDD, Canonical, MDM, Data Products | Enterprise-wide models and party/product semantics |
| 05.03 | [Modern](05.03_Modern/README.md) | Event, Semantic, Knowledge Graph, AI | Event-driven, semantic layer, graphs, and AI/RAG modeling |
| 05.04 | [Industry Reference Models](05.04_Industry_Reference_Models/README.md) | SID, BIAN, verticals | Industry-standard reference models |
| 05.05 | [Cross-Cutting Standards](05.05_Cross_Cutting_Standards/README.md) | Naming, modeling standards | Shared modeling standards and information architecture |

## Structure

```
Data Modeling
├── Traditional (05.01)
│   ├── Relational — ER, Normalization, 3NF, BCNF
│   ├── Kimball Dimensional — Star, Snowflake, Facts, Dimensions, SCD
│   ├── Inmon EDW — CIF, Subject Areas, Data Marts
│   └── Data Vault — DV 1.0/2.0, Hubs, Links, Satellites
├── Enterprise (05.02)
│   ├── Domain Driven — Bounded Context, Domain Model, Aggregate, Events
│   ├── Canonical — Enterprise/Common/Harmonized models
│   ├── MDM / Party — Customer/Product 360, Party, Golden Record, Hierarchy
│   └── Data Product — Contracts, Schema, SLA, Ownership
├── Modern (05.03)
│   ├── Event — Event Storming, Sourcing, CQRS, Stream
│   ├── Semantic — Metrics, Glossary, Semantic Layer
│   ├── Knowledge Graph — Ontology, RDF, Property Graph, EKG
│   └── AI — RAG, Vector, Embedding, Chunk, Agent Memory
└── Industry Reference Models (05.04)
    └── TM Forum SID, BIAN, Healthcare, Retail, Insurance
```

## Start here

- [ER Modeling](05.01_Traditional/05.01.01_Relational/05.01.01.01_ER_Modeling.md)
- [Star Schema](05.01_Traditional/05.01.02_Kimball_Dimensional/05.01.02.01_Star_Schema.md)
- [Enterprise Data Model](05.02_Enterprise/05.02.02_Canonical/05.02.02.01_Enterprise_Data_Model.md)
- [Metrics Layer](05.03_Modern/05.03.02_Semantic_Modeling/05.03.02.01_Metrics_Layer.md)
- [TM Forum SID](05.04_Industry_Reference_Models/05.04.01_TM_Forum_SID.md)

## Related

- [Architecture Space](../README.md)
- [06 Data Product Architecture](../06_Data_Product_Architecture/README.md)
- [02.01 Data Ingestion](../02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/README.md)
