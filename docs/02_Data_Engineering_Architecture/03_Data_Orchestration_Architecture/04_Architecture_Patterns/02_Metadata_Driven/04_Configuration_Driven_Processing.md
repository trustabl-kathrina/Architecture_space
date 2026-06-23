---
title: Configuration-Driven Processing
section: "02.03.04.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [metadata-driven, configuration, orchestration]
canonical: true
---
# Configuration-Driven Processing

## Problem

Business users need pipeline changes (filters, thresholds, file paths) **without** Python commits. Configuration-driven processing externalizes knobs to **YAML/JSON/feature stores** read at runtime.

## Pattern

```mermaid
flowchart LR
  Config[Config_Repo_or_ConfigMap]
  Orch[Orchestrator_loads_at_parse_or_runtime]
  Task[Generic_Processor_Task]
  Config --> Orch --> Task
```

## Config vs code boundary

| In config | In code |
| --- | --- |
| Source paths, cron, batch size | Connection handling, retry policy |
| Column mappings, filters | Error taxonomy |
| Feature flags | Security boundaries |

## Orchestrator patterns

| Pattern | Example |
| --- | --- |
| **Airflow Variables/Params** | dag_run.conf for backfill dates |
| **External config sensor** | Reload DAG when config hash changes |
| **Kestra inputs** | Flow inputs from API trigger |
| **Step Functions input** | JSON payload drives Map state |

## Governance

Version config in Git; CI diff alerts on SLA-critical threshold changes. Separate **config deploy** from **code deploy** for faster business tuning.

## Related

- [Metadata-Driven Framework](01_Metadata_Driven_Framework.md)
- [Dynamic Pipeline Generation](05_Dynamic_Pipeline_Generation.md)
