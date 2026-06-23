---
title: Autonomous Data Platforms
section: "02.03.04.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [ai, autonomous, orchestration]
canonical: true
---
# Autonomous Data Platforms

## Problem

The industry vision of **fully autonomous** data platforms - self-healing pipelines, auto-scaling, auto-remediation without humans - exceeds today's production safety bar. This doc frames **realistic autonomy levels** for orchestration architecture.

## Autonomy levels

| Level | Name | Orchestration behavior |
| ---: | --- | --- |
| 0 | Manual | Human operates UI |
| 1 | Automated | Cron, retries, alerts |
| 2 | Assisted | AI suggests; human approves |
| 3 | Conditional auto | Auto-remediation within policy (rerun, scale pool) |
| 4 | Fully autonomous | Rare; research / bounded domains only |

```mermaid
flowchart LR
  L1[Level_1_Scheduler]
  L2[Level_2_AI_assist]
  L3[Level_3_Policy_engine]
  L4[Level_4_Agents]
  L1 --> L2 --> L3 --> L4
```

## Required building blocks

- [Active Metadata](../../01_Fundamentals/06_Active_Metadata/01_Active_Metadata.md) for closed-loop control
- Policy engine (OPA) with hard limits on agent actions
- Full audit trail and rollback DAGs
- Cost caps on compute and LLM API spend

## Realistic 2026 target

Most enterprises should aim for **Level 2-3**: AI accelerates build and triage; orchestrator executes deterministic graphs; agents only act within pre-approved tool lists.

## Related

- [Agentic Data Engineering](02_Agentic_Data_Engineering.md)
- [AI Data Engineering Overview](01_AI_Data_Engineering_Overview.md)
- [Metadata Orchestration](../02_Metadata_Driven/07_Metadata_Orchestration.md)
