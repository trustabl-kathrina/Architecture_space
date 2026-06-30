---
title: Semantic Governance Framework
section: "00.10.01"
status: complete
template: concept
last_reviewed: 2026-06-30
owner: architecture-team
tags: [governance, semantics]
canonical: true
---

# Semantic Governance Framework

## Context

Semantic artifacts—glossary terms, metrics, semantic models, and semantic data products—require lifecycle governance distinct from physical data governance. This framework defines **processes, quality gates, and versioning rules** for enterprise semantics.

**Canonical modeling references:** [Semantic Modeling README](../../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/README.md)

## Definition

The **semantic governance framework** is the set of intake, review, certification, publication, change management, and retirement processes applied to business glossary entries, certified metrics, semantic models, and semantic data products.

## Lifecycle stages

| Stage | Actor | Activities | Exit criteria |
| --- | --- | --- | --- |
| **Propose** | Business or analyst | Submit term, metric, or model request | Complete intake form with business justification |
| **Draft** | Data steward | Author definition; link to physical sources | Draft in catalog; peer review scheduled |
| **Review** | Steward + architect | Validate alignment with standards and glossary | No conflicts with existing approved terms |
| **Approve** | Business owner | Sign off on meaning and calculation | Status set to `approved` or `certified` |
| **Publish** | Analytics / domain team | Deploy to semantic layer and catalog | Consumption interface available |
| **Change** | Steward | Version change; impact assessment | Consumers notified per SLA |
| **Retire** | Business owner | Deprecate with migration path | Sunset date communicated; dashboards updated |

## Quality gates

| Artifact | Gate before `approved` |
| --- | --- |
| **Glossary term** | Unique preferred name; business owner assigned; no conflicting approved term |
| **Certified metric** | Links to glossary terms; grain documented; formula validated against source |
| **Semantic model** | All measures certified; relationships tested for fan-out; RLS defined |
| **Semantic data product** | Contract complete; lineage to physical product; reconciliation passed |

Detailed quality dimensions: [Semantic Quality Framework](Semantic_Quality_Framework.md).

## Change management

| Change type | Notice period | Approval |
| --- | --- | --- |
| **Non-breaking** (description clarification) | None | Steward |
| **Breaking** (formula, grain, or join change) | 30 days minimum | Business owner + analytics COE |
| **Retirement** | 90 days minimum | Business owner + enterprise council |

Breaking changes require impact analysis listing affected dashboards, APIs, and semantic data products.

## Roles and RACI

| Activity | Business owner | Data steward | Data architect | Analytics COE |
| --- | --- | --- | --- | --- |
| Define term meaning | A | R | C | I |
| Certify metric | A | R | C | C |
| Approve semantic model | A | R | A | C |
| Deploy to BI platform | I | C | C | R |
| Resolve cross-domain conflict | A | C | R | I |

*R = Responsible, A = Accountable, C = Consulted, I = Informed*

## Tooling integration

| Tool | Role in framework |
| --- | --- |
| **Data catalog** | Glossary authoring, workflow, discovery |
| **Git / CI** | Version control for semantic models (LookML, dbt, YAML) |
| **BI platform** | Deployment target for certified semantic models |
| **Lineage system** | Impact analysis for change management |

## Related topics

- [Enterprise Semantics](Enterprise_Semantics.md) — operating model
- [Business Definition Governance](Business_Definition_Governance.md) — term-specific workflow
- [Semantic Quality Framework](Semantic_Quality_Framework.md) — quality checks
- [Semantic Governance (Modeling)](../../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/07_Semantic_Governance.md) — modeling-side ownership
- [Semantics Hub](../../../../_hubs/Semantics_Hub.md) — navigation index

## ADR reference

- [ADR 009 Semantic Governance Strategy](../../../../03_Architecture_Decision_Records/Governance_And_Metadata/ADR_009_Semantic_Governance_Strategy.md)
