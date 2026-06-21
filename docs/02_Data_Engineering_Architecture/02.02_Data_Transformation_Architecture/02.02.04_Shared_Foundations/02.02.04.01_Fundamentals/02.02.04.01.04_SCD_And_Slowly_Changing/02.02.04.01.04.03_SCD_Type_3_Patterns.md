---
title: SCD Type 3 Implementation Patterns
section: "02.02.04.01.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [scd, type-3]
canonical: true
---
# SCD Type 3 Implementation Patterns

Store **limited prior value** in additional columns (e.g., `previous_price`, `price_change_date`).

## Use cases

- Regulatory need for one prior state only.
- Small dimension where Type 2 row explosion is unacceptable.

## Limitation

Not a substitute for full audit trail â€” combine with immutable bronze CDC log.
