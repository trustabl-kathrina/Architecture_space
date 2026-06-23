---
title: Showback Model
section: "04.06"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [finops, showback]
canonical: true
---
# Showback Model

## Context

Showback allocates cloud and platform costs to consuming teams without actual financial chargeback. It builds cost awareness and accountability while avoiding the organizational friction of full chargeback during early FinOps maturity.

## Definition

**Showback** is a financial transparency practice where infrastructure and platform costs are attributed to business units, products, or domains and reported regularly â€” without transferring actual budget liability.

## Key principles

1. **Transparency** â€” Every team sees what they consume.
2. **Attribution** â€” Costs map to tags, namespaces, or data products.
3. **Education** â€” Reports drive optimization conversations, not invoices.
4. **Progression** â€” Showback precedes chargeback in FinOps maturity.

## Implementation model

| Step | Activity |
| --- | --- |
| 1 | Define cost allocation dimensions (BU, product, environment) |
| 2 | Enforce tagging standards across cloud and data platforms |
| 3 | Publish monthly showback reports via FinOps tooling |
| 4 | Review with platform and product owners quarterly |

## Domain applications

- **Cloud (16):** Per-account and per-workload showback via cloud cost tools.
- **Data platform (10):** Per-warehouse, per-query, or per-data-product attribution.
- **Data engineering (04):** Pipeline and cluster cost attribution.
- **Platform engineering (17):** Shared platform costs distributed by consumption.
- **Strategy (01):** Funding model alignment and executive reporting.

## Related

- [FinOps Hub](../../hubs/FinOps_Hub.md)
- [Chargeback Model](Chargeback_Model.md)
- [Cost Allocation Framework](Cost_Allocation_Framework.md)
