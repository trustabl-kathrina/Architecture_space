---
title: Business Definition Governance
section: "00.10.01"
status: complete
template: concept
last_reviewed: 2026-06-30
owner: architecture-team
tags: [governance, semantics, glossary]
canonical: true
---

# Business Definition Governance

## Context

Business definitions fail when IT writes them without business authority, or when every department maintains a local dictionary. **Business definition governance** establishes who may propose, approve, and change glossary terms—and how conflicts are resolved.

**Canonical glossary structure:** [Business Glossary](../../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/01_Business_Glossary.md)

**Analytics surfacing:** [Business Definitions](../../../../06_Analytics_Architecture/01_BI_Architecture/Semantic_Layer_Architecture/Business_Definitions.md)

## Definition

**Business definition governance** is the approval workflow, stewardship rules, and conflict resolution process for enterprise business glossary terms and their linkage to metrics, data elements, and policies.

## Intake workflow

```mermaid
flowchart LR
  Submit[Submit Term Request] --> Triage[Steward Triage]
  Triage --> DupCheck[Duplicate Check]
  DupCheck --> Draft[Draft Definition]
  Draft --> Review[Peer Review]
  Review --> Approve[Business Owner Approval]
  Approve --> Publish[Publish to Catalog]
  Publish --> Sync[Sync to BI Metadata]
```

## Request requirements

Every term intake must include:

| Field | Required |
| --- | --- |
| Proposed preferred name | Yes |
| Draft definition | Yes |
| Business domain | Yes |
| Business owner (approver) | Yes |
| Synonyms and related terms | If known |
| Justification / use case | Yes |
| Linked metrics or data elements | If applicable |

## Approval rules

1. **Business owner approval is mandatory** — IT cannot set status to `approved` unilaterally.
2. **One preferred term per concept** — Synonyms are aliases, not separate approved entries.
3. **Conflict escalation** — Overlapping definitions escalate to enterprise data council within 10 business days.
4. **Deprecation over deletion** — Retired terms remain in catalog with `deprecated` status and successor link.
5. **Quarterly review** — Stewards validate top 100 terms by usage; stale terms are reviewed or deprecated.

## Stewardship responsibilities

| Steward action | Frequency |
| --- | --- |
| Triage new term requests | Within 3 business days |
| Resolve synonym proposals | Within 5 business days |
| Link new certified metrics to terms | Before metric certification |
| Sync definition changes to BI metadata | Within 1 business day of approval |
| Report glossary health metrics | Monthly |

## Conflict resolution

| Scenario | Resolution |
| --- | --- |
| Two domains claim same term with different meanings | Enterprise council picks enterprise definition; domain-specific terms get qualified names |
| Source system name conflicts with glossary | Synonym mapping; source name documented as alias |
| Acquired company terminology | Mapping project; transitional synonyms for 12 months |

## Metrics

| Metric | Target |
| --- | --- |
| Term request triage SLA | ≤ 3 business days |
| Approved terms with assigned owner | 100% |
| Certified metrics linked to glossary | 100% |
| Duplicate approved terms | 0 |

## Related topics

- [Business Glossary](../../../../04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling/01_Business_Glossary.md) — canonical glossary model
- [Semantic Governance Framework](Semantic_Governance_Framework.md) — full semantic lifecycle
- [Enterprise Semantics](Enterprise_Semantics.md) — operating model
- [KPI Standardization](KPI_Standardization.md) — governance-side KPI standards

## ADR reference

- [ADR 009 Semantic Governance Strategy](../../../../03_Architecture_Decision_Records/Governance_And_Metadata/ADR_009_Semantic_Governance_Strategy.md)
