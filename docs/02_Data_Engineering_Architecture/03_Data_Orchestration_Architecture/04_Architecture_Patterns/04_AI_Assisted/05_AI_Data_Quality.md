---
title: AI Data Quality
section: "02.03.04.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [ai, data-quality, orchestration]
canonical: true
---
# AI Data Quality

## Problem

Rule-based DQ misses subtle drift (distribution shift, new enum values). **AI-assisted quality** augments orchestrated checkpoints with anomaly detection and natural-language rule authoring.

## Pattern

```mermaid
flowchart LR
  Run[Pipeline_run_completes]
  Stats[Profile_stats_to_monitor]
  ML[Anomaly_model_or_LLM_rule]
  Gate[Orchestrator_branch]
  Run --> Stats --> ML --> Gate
  Gate -->|ok| Downstream[Downstream_DAG]
  Gate -->|fail| Alert[Alert_and_quarantine]
```

## Integration with orchestration

| Approach | Implementation |
| --- | --- |
| **LLM-authored rules** | Prompt → GE expectation JSON → validation task |
| **Anomaly scores** | Write score to metadata; Active Metadata blocks publish |
| **Root cause** | LLM summarizes failed checks + recent deploys |

Embed validation as **first-class tasks** - not ad-hoc notebooks after the fact.

## Related

- [Automated Validation](../01_DataOps_Patterns/06_Automated_Validation.md)
- [Active Metadata](../../01_Fundamentals/06_Active_Metadata/01_Active_Metadata.md)
