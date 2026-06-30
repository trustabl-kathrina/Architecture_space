---
title: Semantic Modeling README
section: "05.03.02"
status: complete
template: overview
last_reviewed: 2026-06-30
owner: architecture-team
tags: [data-modeling, semantics]
canonical: true
---

# Semantic Modeling

Canonical home for business semantics modeling—glossary, metrics, semantic layer, and semantic data products.

**Navigation hub:** [Semantics Hub](../../../_hubs/Semantics_Hub.md)

## Semantics pipeline

Topics follow a **glossary-first** capability chain: shared vocabulary → governed measures → consumption views → formal models → standards and operations → packaged delivery.

```mermaid
flowchart LR
  A[01 Business Glossary] --> B[02 Metrics Layer]
  B --> C[03 Semantic Layer]
  C --> D[04 Business Semantic Model]
  D --> E[05 Semantic Model]
  E --> F[06 Standards]
  F --> G[07 Governance]
  G --> H[08 Interoperability]
  H --> I[09 Semantic Data Products]
```

## Topics

| Topic | Status | Description |
| --- | --- | --- |
| [Business Glossary](01_Business_Glossary.md) | complete | Enterprise business terms |
| [Metrics Layer](02_Metrics_Layer.md) | complete | Certified measure definitions |
| [Semantic Layer](03_Semantic_Layer.md) | complete | Logical consumption model |
| [Business Semantic Model](04_Business_Semantic_Model.md) | stub | Entity-relationship business view |
| [Semantic Model](05_Semantic_Model.md) | stub | Detailed model structure |
| [Semantic Standards](06_Semantic_Standards.md) | stub | Naming and definition conventions |
| [Semantic Governance](07_Semantic_Governance.md) | stub | Modeling-side ownership |
| [Semantic Interoperability](08_Semantic_Interoperability.md) | stub | Cross-domain alignment |
| [Semantic Data Products](09_Semantic_Data_Products.md) | complete | Governed semantic packages |

## Related sections

- [Semantic Layer Architecture (Analytics)](../../../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/) — platform implementation
- [Semantic Governance (Governance)](../../../00_Architecture_Governance/10_Data_Governance_And_Metadata/01_Metadata_Management/Semantic_Governance/) — enterprise operating model
- [Industry Reference Models](../04_Industry_Reference_Models/README.md) — TM Forum SID, BIAN, FIBO, and vertical reference patterns
