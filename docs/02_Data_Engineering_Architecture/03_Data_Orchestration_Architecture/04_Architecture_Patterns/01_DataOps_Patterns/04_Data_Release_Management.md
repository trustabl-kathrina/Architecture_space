---
title: Data Release Management
section: "02.03.04.01"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dataops, release-management, orchestration]
canonical: true
---
# Data Release Management

## Problem

Data products ship on **cadence** (daily mart refresh, monthly regulatory feed) but also need **emergency fixes**. Release management coordinates orchestrator changes with downstream consumers and SLAs.

## Release types

| Type | Trigger | Orchestration gate |
| --- | --- | --- |
| **Scheduled release** | Calendar (e.g. sprint) | Change window; T0 DAG freeze |
| **Standard change** | Ticket + approval | CI green + staging run |
| **Emergency** | P1 incident | Break-glass deploy; post-incident review |

## Release artifact bundle

A data release should include:

1. Git tag / commit SHA deployed to orchestrator
2. Changelog of DAG/asset IDs affected
3. Backfill plan (date range, pools, cost estimate)
4. Consumer notification (catalog + Slack)
5. Rollback DAG version pointer

## Freeze windows

Align orchestration deploy freezes with:

- Finance close (T0 DAGs locked)
- Black Friday / peak retail
- Regulatory submission dates

During freeze: **hotfix-only** with dual approval.

## Related

- [Data Deployment Strategy](03_Data_Deployment_Strategy.md)
- [SLA Management](../../01_Fundamentals/03_Core_Concepts/04_SLA_Management.md)
- [Orchestration Governance](../../01_Fundamentals/04_Governance/01_Orchestration_Governance.md)