# Generate 02.03.04 Architecture Patterns content
$Base = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture\02.03.04_Architecture_Patterns"))

function FM($title, $section, $template, $tags) {
@"
---
title: $title
section: "$section"
status: complete
template: $template
last_reviewed: 2026-06-20
owner: architecture-team
tags: [$tags]
canonical: true
---

"@
}

$patterns = @{
    "02.03.04.01_DataOps_Patterns\02.03.04.01.01_CI_CD_For_Data.md" = @{
        section="02.03.04.01"; title="CI/CD for Data Pipelines"; template="concept"; tags="dataops, ci-cd, orchestration"
        body=@"
# CI/CD for Data Pipelines

## Problem

Data pipelines change as often as application code, but **bad deploys corrupt datasets** — not just uptime. Without CI/CD, orchestration becomes a manual UI sport: DAGs promoted without parse tests, secrets drift, and prod backfills run from unreviewed branches.

## Pattern

Treat orchestration definitions (DAGs, flows, assets, YAML workflows) as **versioned artifacts** in Git. CI validates; CD promotes to orchestrator environments with the same rigor as microservices.

```mermaid
flowchart LR
  Dev[Author_DAG_in_Git] --> CI[CI_Parse_Test_Scan]
  CI --> Stg[Deploy_to_Staging_Orch]
  Stg --> Val[Integration_and_DQ_Smoke]
  Val --> CD[CD_Promote_to_Prod]
  CD --> Orch[Production_Orchestrator]
```

## Pipeline stages

| Stage | Orchestration checks |
| --- | --- |
| **Lint / parse** | `airflow dags test`, `dagster definitions validate`, YAML schema |
| **Unit** | Task logic, mock connections, `@task` isolation |
| **Integration** | Staging run against sandbox warehouse |
| **Security** | No secrets in repo; connection IDs only |
| **Deploy** | Sync to object storage / API / Helm; pause old DAG version |

## Environment model

| Environment | Orchestrator | Data |
| --- | --- | --- |
| Dev | Local or shared dev cluster | Synthetic / sampled |
| Staging | Mirror prod topology | Anonymized prod subset |
| Prod | HA control plane | Full datasets |

## Tooling map

| Layer | Examples |
| --- | --- |
| CI | GitHub Actions, GitLab CI, Azure DevOps |
| DAG sync | Astronomer CI, MWAA S3 sync, Composer GCS, Prefect deploy |
| IaC | Terraform for MWAA/Composer/ADF linked services |
| Policy | OPA on DAG metadata before merge |

## Anti-patterns

- Deploying directly from laptop to prod orchestrator
- Skipping staging because "it's just a schedule change"
- Same connection credentials across environments

## Related

- [GitOps for Data](02.03.04.01.02_GitOps_For_Data.md)
- [Data Deployment Strategy](02.03.04.01.03_Data_Deployment_Strategy.md)
- [Orchestration Governance](../../02.03.01_Fundamentals/02.03.01.04_Governance/02.03.01.04.01_Orchestration_Governance.md)
- [Cloud Services](../../02.03.02_Cloud_Services/README.md)
"@
    }
    "02.03.04.01_DataOps_Patterns\02.03.04.01.02_GitOps_For_Data.md" = @{
        section="02.03.04.01"; title="GitOps for Data"; template="concept"; tags="dataops, gitops, orchestration"
        body=@"
# GitOps for Data

## Problem

Orchestration state diverges from Git when operators change schedules, variables, or connections in the UI. **GitOps** makes the repository the single source of truth; the orchestrator **reconciles** to declared desired state.

## Pattern

```mermaid
flowchart LR
  Git[Git_Repo_DAGs_Config] --> Agent[GitOps_Agent_or_CI]
  Agent --> Orch[Orchestrator_API_or_Sync]
  Orch --> Run[Scheduled_Executions]
  Drift[UI_Change] -.->|blocked or reverted| Git
```

## What belongs in Git

| Artifact | Examples |
| --- | --- |
| Workflow definitions | DAGs, Prefect deployments, Kestra flows |
| Config | `airflow.cfg` overlays, pool definitions as code |
| Variables (non-secret) | Feature flags, dataset URIs |
| Infrastructure | Helm values, Terraform for orchestrator |

Secrets stay in vault / cloud secret manager; Git references **connection names** only.

## Reconciliation modes

| Mode | Behavior | Fit |
| --- | --- | --- |
| **Sync on merge** | CI pushes to orchestrator on main | Airflow S3/GCS DAG folder |
| **Pull reconcile** | Agent polls Git every N minutes | Self-hosted Airflow + git-sync sidecar |
| **Declarative API** | Controller applies CRDs | Argo CD + K8s-native workflows |

## Orchestrator notes

| Platform | GitOps approach |
| --- | --- |
| Airflow / MWAA / Composer | DAG folder in Git → S3/GCS sync |
| Dagster | Code locations from Git tag via CI |
| Prefect | `prefect deploy` from GitHub Action |
| Kestra | Flow files in Git; server loads from repository backend |

## Related

- [CI/CD for Data](02.03.04.01.01_CI_CD_For_Data.md)
- [Data Release Management](02.03.04.01.04_Data_Release_Management.md)
"@
    }
    "02.03.04.01_DataOps_Patterns\02.03.04.01.03_Data_Deployment_Strategy.md" = @{
        section="02.03.04.01"; title="Data Deployment Strategy"; template="concept"; tags="dataops, deployment, orchestration"
        body=@"
# Data Deployment Strategy

## Problem

Application blue/green does not map cleanly to data: **schema changes**, **backfills**, and **dual writes** require orchestration-aware deployment strategies.

## Deployment strategies

| Strategy | Orchestration behavior | When to use |
| --- | --- | --- |
| **Big bang** | Pause DAG → deploy → resume | Low-risk config-only changes |
| **Parallel pipeline** | New DAG version runs alongside old | Major logic rewrite with compare window |
| **Feature flag task** | Single DAG branches on variable | Incremental task rollout |
| **Expand–contract** | Additive schema first; cutover task later | Warehouse schema migrations |
| **Backfill-first** | Deploy idle; run historical backfill before cutover | Partition model changes |

```mermaid
flowchart TB
  subgraph parallel [Parallel Pipeline Cutover]
    Old[DAG_v1_prod_schedule]
    New[DAG_v2_shadow_or_manual]
    Compare[Reconciliation_Task]
    Old --> Compare
    New --> Compare
    Compare --> Switch[Flip_schedule_to_v2]
  end
```

## Rollback

| Failure type | Rollback action |
| --- | --- |
| Parse error | Revert Git; previous DAG bundle still in object storage |
| Logic bug | Pause new DAG; re-enable previous version |
| Bad data written | Run compensating DAG; quarantine partition |

Orchestrator metadata (run history) is **not** rolled back — plan idempotent compensating tasks.

## Related

- [CI/CD for Data](02.03.04.01.01_CI_CD_For_Data.md)
- [Data Release Management](02.03.04.01.04_Data_Release_Management.md)
- [Scheduling Patterns](../../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.01_Scheduling_Patterns.md)
"@
    }
    "02.03.04.01_DataOps_Patterns\02.03.04.01.04_Data_Release_Management.md" = @{
        section="02.03.04.01"; title="Data Release Management"; template="concept"; tags="dataops, release-management, orchestration"
        body=@"
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

- [Data Deployment Strategy](02.03.04.01.03_Data_Deployment_Strategy.md)
- [SLA Management](../../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.04_SLA_Management.md)
- [Orchestration Governance](../../02.03.01_Fundamentals/02.03.01.04_Governance/02.03.01.04.01_Orchestration_Governance.md)
"@
    }
    "02.03.04.01_DataOps_Patterns\02.03.04.01.05_Data_Testing_Strategy.md" = @{
        section="02.03.04.01"; title="Data Testing Strategy"; template="concept"; tags="dataops, testing, orchestration"
        body=@"
# Data Testing Strategy

## Problem

Orchestration proves **tasks ran**; testing proves **data is correct**. A testing strategy embeds validation at every layer the orchestrator touches.

## Test pyramid for orchestrated pipelines

```mermaid
flowchart TB
  E2E[E2E_Staging_Pipeline_Run]
  Int[Integration_Task_Chain]
  Unit[Unit_Task_Logic]
  Static[Static_DAG_Parse_and_Contract]
  E2E --> Int --> Unit --> Static
```

| Layer | What | Where |
| --- | --- | --- |
| **Static** | DAG cycle-free, naming standards, no import errors | CI |
| **Unit** | Transform functions with fixtures | CI |
| **Contract** | Schema expectations vs registry | CI + pre-prod |
| **Integration** | Task against sandbox DB | Staging orchestrator |
| **E2E** | Full DAG run + row counts | Staging |
| **Production monitors** | Freshness, volume, null rate | Observability |

## Orchestration integration

| Pattern | Implementation |
| --- | --- |
| **Test DAG** | `dag_id` suffix `_test` triggered on PR |
| **Branching** | `@task.branch` on quality result |
| **Blocking gate** | dbt test task before publish task |
| **Sensor test mode** | Short-circuit external sensors in CI |

## Tools

| Tool | Role |
| --- | --- |
| dbt tests | Transform validation inside DAG |
| Great Expectations | Checkpoint task in workflow |
| Soda / Monte Carlo | Observability hooks post-run |

## Related

- [Automated Validation](02.03.04.01.06_Automated_Validation.md)
- [CI/CD for Data](02.03.04.01.01_CI_CD_For_Data.md)
"@
    }
    "02.03.04.01_DataOps_Patterns\02.03.04.01.06_Automated_Validation.md" = @{
        section="02.03.04.01"; title="Automated Validation"; template="concept"; tags="dataops, validation, orchestration"
        body=@"
# Automated Validation

## Problem

Manual spot-checks after nightly batches do not scale. **Automated validation** runs inside or immediately after orchestrated tasks and **blocks downstream** on failure.

## Pattern

```mermaid
flowchart LR
  Extract[Extract_Task] --> Transform[Transform_Task]
  Transform --> Validate[Validation_Task]
  Validate -->|pass| Publish[Publish_Task]
  Validate -->|fail| Quarantine[Quarantine_and_Alert]
```

## Validation types

| Type | Example | Orchestration hook |
| --- | --- | --- |
| **Row count** | ±5% vs prior day | Task fails → skip publish |
| **Schema** | Required columns present | Branch to remediation DAG |
| **Referential** | FK match rate > 99.9% | Block gold layer sensor |
| **Business rule** | Revenue >= 0 | PagerDuty on fail |
| **Cross-pipeline** | Staging count = prod input | Dataset dependency gate |

## Fail-fast vs fail-safe

| Policy | Behavior | Use when |
| --- | --- | --- |
| **Fail-fast** | Stop DAG; no partial publish | Financial, regulatory |
| **Fail-safe** | Publish to quarantine schema | Exploratory analytics |
| **Degrade** | Publish with quality flag column | Consumer can filter |

## Active metadata loop

Failed validation emits event → catalog marks dataset **degraded** → [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md) pauses downstream DAGs.

## Related

- [Data Testing Strategy](02.03.04.01.05_Data_Testing_Strategy.md)
- [Retry and Idempotency](../../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.03_Retry_And_Idempotency.md)
"@
    }
}

# Metadata-driven patterns
$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.01_Metadata_Driven_Framework.md"] = @{
    section="02.03.04.02"; title="Metadata-Driven Framework"; template="concept"; tags="metadata-driven, orchestration, framework"
    body=@"
# Metadata-Driven Framework

## Problem

Hard-coded pipelines multiply: every new source means copy-paste DAGs. A **metadata-driven framework** generates or configures orchestration from **declarative metadata** (YAML, catalog tables, registry APIs).

## Reference architecture

```mermaid
flowchart TB
  Meta[Metadata_Store_Sources_Schemas_SLAs]
  Gen[Generator_or_Factory_Layer]
  Orch[Orchestrator_Airflow_Dagster_Kestra]
  Exec[Compute_Spark_dbt_Warehouse]
  Meta --> Gen --> Orch --> Exec
  Exec --> Lineage[OpenLineage_Events]
  Lineage --> Meta
```

## Core metadata entities

| Entity | Drives |
| --- | --- |
| **Source** | Ingest task template, schedule, connection |
| **Dataset** | Asset key, partitions, dependencies |
| **Transformation** | dbt model ref, SQL template params |
| **SLA** | Priority pool, alert routing |
| **Lineage edge** | Upstream/downstream in DAG |

## Framework layers

1. **Metadata model** — canonical schema (often catalog or internal DB)
2. **Template library** — Jinja/YAML/Python factory for task patterns
3. **Compiler** — emits DAGs or registers assets at deploy time
4. **Runtime adapter** — target orchestrator plugin
5. **Feedback** — run outcomes update freshness in metadata

## When to adopt

| Signal | Action |
| --- | --- |
| >50 similar pipelines | Invest in factory |
| Frequent onboardings | Self-service metadata forms |
| Multi-orchestrator estate | Metadata abstraction layer |

## Related

- [Metadata-Driven ETL](02.03.04.02.02_Metadata_Driven_ETL.md)
- [Dynamic Pipeline Generation](02.03.04.02.05_Dynamic_Pipeline_Generation.md)
- [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
"@
}

$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.02_Metadata_Driven_ETL.md"] = @{
    section="02.03.04.02"; title="Metadata-Driven ETL"; template="concept"; tags="metadata-driven, etl, orchestration"
    body=@"
# Metadata-Driven ETL

## Problem

ELT pipelines share structure (extract → stage → transform → publish) but differ in sources. Metadata-driven ETL **parameterizes** the pattern instead of rewriting DAGs.

## Pattern

Each pipeline row in metadata defines:

| Field | Example |
| --- | --- |
| `source_system` | `salesforce` |
| `landing_path` | `s3://raw/salesforce/{table}/` |
| `cadence` | `0 2 * * *` |
| `transform_package` | `dbt_salesforce` |
| `target_dataset` | `catalog://prod/analytics/customers` |

Generator emits standard DAG:

```mermaid
flowchart LR
  Ingest[Ingest_from_source] --> Stage[Land_to_bronze]
  Stage --> dbt[dbt_run_models]
  dbt --> Publish[Register_in_catalog]
```

## Implementation options

| Approach | Orchestrator |
| --- | --- |
| **Factory DAG** | Single Python module loops metadata rows → dynamic tasks |
| **Asset factory** | Dagster `@asset` generated from catalog export |
| **Declarative flows** | Kestra YAML templated from metadata API |
| **ADF metadata** | Dataset + pipeline templates in ARM/Bicep |

## Benefits

- Onboard source in hours (metadata row + connection)
- Consistent retry, SLA, and lineage tags
- Central policy: all bronze paths encrypted, all tasks emit OpenLineage

## Related

- [Metadata-Driven Framework](02.03.04.02.01_Metadata_Driven_Framework.md)
- [Configuration-Driven Processing](02.03.04.02.04_Configuration_Driven_Processing.md)
"@
}

$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.03_Metadata_Driven_Transformations.md"] = @{
    section="02.03.04.02"; title="Metadata-Driven Transformations"; template="concept"; tags="metadata-driven, transformations, orchestration"
    body=@"
# Metadata-Driven Transformations

## Problem

Transform logic scattered across SQL files, notebooks, and DAG tasks lacks a **single contract** for inputs, outputs, and dependencies. Metadata-driven transformations bind **what changes** to **orchestration order**.

## Pattern

Transform metadata (dbt `schema.yml`, catalog columns, or internal registry) declares:

- Input datasets / models
- Output datasets / models
- Materialization strategy
- Tests and owners

Orchestrator **derives** run order from metadata graph — not manual `>>` operators.

| System | Mechanism |
| --- | --- |
| **dbt + Airflow** | Cosmos / Astronomer dbt tasks from manifest |
| **Dagster** | Assets from dbt project or `@asset` defs |
| **Spark** | Delta table properties → dependency sensor |

```mermaid
flowchart LR
  Meta[dbt_manifest_or_asset_defs]
  Orch[Orchestrator_resolves_DAG]
  WH[Warehouse_runs_SQL]
  Meta --> Orch --> WH
```

## Partition alignment

Metadata carries `partition_key` / `incremental_strategy` so orchestrator schedules **aligned backfills** across upstream and downstream transforms.

## Related

- [Metadata-Driven ETL](02.03.04.02.02_Metadata_Driven_ETL.md)
- [Dependency Management](../../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.02_Dependency_Management.md)
"@
}

$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.04_Configuration_Driven_Processing.md"] = @{
    section="02.03.04.02"; title="Configuration-Driven Processing"; template="concept"; tags="metadata-driven, configuration, orchestration"
    body=@"
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
| **Airflow Variables/Params** | `dag_run.conf` for backfill dates |
| **External config sensor** | Reload DAG when config hash changes |
| **Kestra inputs** | Flow inputs from API trigger |
| **Step Functions input** | JSON payload drives Map state |

## Governance

Version config in Git; CI diff alerts on SLA-critical threshold changes. Separate **config deploy** from **code deploy** for faster business tuning.

## Related

- [Metadata-Driven Framework](02.03.04.02.01_Metadata_Driven_Framework.md)
- [Dynamic Pipeline Generation](02.03.04.02.05_Dynamic_Pipeline_Generation.md)
"@
}

$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.05_Dynamic_Pipeline_Generation.md"] = @{
    section="02.03.04.02"; title="Dynamic Pipeline Generation"; template="concept"; tags="metadata-driven, dynamic, orchestration"
    body=@"
# Dynamic Pipeline Generation

## Problem

Static DAG files cannot represent **tenant-specific**, **region-specific**, or **schema-evolving** workloads at scale. Dynamic generation creates orchestration graphs **at parse time or runtime** from metadata.

## Generation timing

| When | Mechanism | Example |
| --- | --- | --- |
| **Parse time** | Python loop in DAG file | Airflow dynamic task mapping |
| **Deploy time** | CI compiler | YAML → 500 Kestra flows |
| **Runtime** | API-triggered subflows | Prefect subflows per customer |
| **Event time** | Metadata event | New table → auto-register ingest DAG |

```mermaid
flowchart TB
  Meta[Metadata_change_event]
  Gen[Generator_service]
  Orch[Register_new_DAG_or_asset]
  Meta --> Gen --> Orch
```

## Airflow 2.x dynamic task mapping

Single DAG definition expands to N task instances from metadata query — reduces DAG proliferation.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Scheduler overload | Cap max dynamic tasks; pool limits |
| Opaque graphs | Emit generated manifest to catalog |
| Untested combos | Property-based tests on generator |

## Related

- [Metadata-Driven Framework](02.03.04.02.01_Metadata_Driven_Framework.md)
- [Metadata Automation](02.03.04.02.06_Metadata_Automation.md)
"@
}

$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.06_Metadata_Automation.md"] = @{
    section="02.03.04.02"; title="Metadata Automation"; template="concept"; tags="metadata-driven, automation, orchestration"
    body=@"
# Metadata Automation

## Problem

Catalog entries, lineage, and SLA tags lag reality when updated manually after each deploy. **Metadata automation** syncs orchestrator state ↔ catalog continuously.

## Automation flows

| Trigger | Automated action |
| --- | --- |
| DAG deploy (CI) | Register/update dataset stubs in catalog |
| Task success | Update `last_refreshed`, row count stats |
| Schema change task | Bump schema version in registry |
| New dependency in code | OpenLineage → lineage graph edge |
| SLA breach | Tag dataset `at_risk`; notify owner |

```mermaid
flowchart LR
  Orch[Orchestrator_events]
  OL[OpenLineage]
  Cat[Catalog_API]
  Orch --> OL --> Cat
  Cat --> Rules[Policy_rules]
  Rules --> Orch
```

## Implementation stack

| Component | Options |
| --- | --- |
| Lineage | OpenLineage, Dagster events, native asset materializations |
| Catalog | DataHub, Alation, Collibra, Unity Catalog |
| Sync worker | Custom lambda, Marquez, catalog ingestion jobs |

## Related

- [Metadata Orchestration](02.03.04.02.07_Metadata_Orchestration.md)
- [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
"@
}

$patterns["02.03.04.02_Metadata_Driven\02.03.04.02.07_Metadata_Orchestration.md"] = @{
    section="02.03.04.02"; title="Metadata Orchestration"; template="concept"; tags="metadata-driven, orchestration, scheduling"
    body=@"
# Metadata Orchestration

## Problem

Time-based cron schedules ignore **data readiness**. Metadata orchestration schedules and prioritizes work from **dataset state** in the catalog — freshness, partitions, quality gates.

## Pattern

```mermaid
flowchart LR
  DS[Dataset_A_updated]
  Cat[Catalog_event]
  Orch[Trigger_downstream_DAG_or_asset]
  DS --> Cat --> Orch
```

## Scheduling modes

| Mode | Description |
| --- | --- |
| **Dataset-triggered** | Airflow Datasets, Dagster asset sensors |
| **Freshness SLA** | Run when upstream SLA met or breach escalates |
| **Quality-gated** | Downstream starts only if quality score ≥ threshold |
| **Cost-aware** | Defer non-critical assets to off-peak via metadata tier |

## Metadata required

- Stable dataset URI / FQN
- Partition keys and last successful partition
- Orchestrator mapping (`dag_id`, asset key)
- Dependency graph (transitive closure)

## vs time-based cron

| Cron | Metadata-driven |
| --- | --- |
| Simple, predictable | Reactive to actual data arrival |
| May run too early/late | Reduces wasted runs and SLA misses |
| Good for external API windows | Good for internal DAG meshes |

Hybrid: cron **deadline** + metadata **trigger** (run when ready, fail if not ready by deadline).

## Related

- [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
- [Scheduling Patterns](../../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.01_Scheduling_Patterns.md)
"@
}

# Platform pattern
$patterns["02.03.04.03_Platform_Patterns\02.03.04.03.01_Internal_Developer_Platform.md"] = @{
    section="02.03.04.03"; title="Internal Developer Platform for Data"; template="concept"; tags="platform-engineering, idp, orchestration"
    body=@"
# Internal Developer Platform for Data

## Problem

Every team rolling its own Airflow namespace, secrets, and CI leads to **fragmented operations** and inconsistent SLAs. An **Internal Developer Platform (IDP)** offers golden-path orchestration self-service.

## Platform architecture

```mermaid
flowchart TB
  Dev[Data_Engineer]
  Portal[Platform_Portal_Backstage]
  Templates[Golden_Path_Templates]
  Orch[Shared_Orchestrator_Cluster]
  Obs[Observability_and_Catalog]
  Dev --> Portal --> Templates --> Orch
  Orch --> Obs
```

## Platform capabilities

| Capability | Developer experience |
| --- | --- |
| **Pipeline scaffold** | `cookiecutter` → Git repo with CI + sample DAG |
| **Environment provision** | Namespace, pools, connections via ticket or self-service |
| **Deploy** | Merge to main → auto-sync to dev/stg/prod |
| **Operate** | Unified dashboard: runs, logs, costs, lineage |
| **Policy** | Guardrails: naming, tags, max runtime, approved operators |

## Orchestration choices for IDP

| Model | Notes |
| --- | --- |
| **Shared multi-tenant Airflow** | RBAC per team; pool quotas |
| **Dagster code locations** | Strong asset boundaries per repo |
| **Namespace-per-team K8s** | Argo / Flyte for container-native teams |

## Team topology

Platform team owns control plane, CI templates, SLOs. Product data teams own DAG logic and data quality.

## Related

- [Platform Engineering stubs](../../02.03.02_Cloud_Services/02.03.02.06_Platform_Engineering/README.md)
- [Self-Service Platform](../../02.03.08_Integration_Patterns/02.03.08.01_Self_Service_Platform.md)
- [CI/CD for Data](../02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md)
"@
}

# AI-assisted patterns
$patterns["02.03.04.04_AI_Assisted\02.03.04.04.01_AI_Data_Engineering_Overview.md"] = @{
    section="02.03.04.04"; title="AI-Assisted Data Engineering Overview"; template="overview"; tags="ai, orchestration, data-engineering"
    body=@"
# AI-Assisted Data Engineering Overview

## Problem

Data teams spend cycles on boilerplate: DAG scaffolding, mapping docs, test cases, and incident triage. **AI-assisted data engineering** embeds LLM and agent capabilities into the **orchestration lifecycle** — design, build, test, operate — with human review gates.

## Scope in orchestration

| Phase | AI assist |
| --- | --- |
| **Design** | Pipeline suggestions from metadata |
| **Build** | Code generation for tasks and dbt models |
| **Test** | Synthetic data and test case generation |
| **Operate** | Root-cause hints from failed runs + lineage |
| **Govern** | Auto-tagging, lineage enrichment, policy checks |

```mermaid
flowchart LR
  Meta[Catalog_and_Runs_Metadata]
  AI[AI_Assist_Layer]
  Orch[Orchestrator]
  Human[Human_Review_and_Approve]
  Meta --> AI --> Human --> Orch
  Orch --> Meta
```

## Guardrails

- Never auto-deploy to prod without CI and human approval
- PII masking before sending logs/SQL to external models
- Audit trail for generated artifacts

## Pattern docs in this section

| Doc | Focus |
| --- | --- |
| [Agentic Data Engineering](02.03.04.04.02_Agentic_Data_Engineering.md) | Autonomous agents in workflows |
| [AI Code Generation](02.03.04.04.03_AI_Code_Generation.md) | Task and DAG codegen |
| [AI Pipeline Generation](02.03.04.04.08_AI_Pipeline_Generation.md) | End-to-end pipeline drafts |
| [Autonomous Data Platforms](02.03.04.04.10_Autonomous_Data_Platforms.md) | Vision and limits |

## Related

- [Orchestration Strategy](../../02.03.01_Fundamentals/02.03.01.02_Strategy/02.03.01.02.01_Orchestration_Strategy.md)
- [Metadata-Driven Framework](../02.03.04.02_Metadata_Driven/02.03.04.02.01_Metadata_Driven_Framework.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.02_Agentic_Data_Engineering.md"] = @{
    section="02.03.04.04"; title="Agentic Data Engineering"; template="concept"; tags="ai, agents, orchestration"
    body=@"
# Agentic Data Engineering

## Problem

Static DAGs cannot adapt to **unexpected schema drift**, **partial file arrivals**, or **multi-step remediation** without human intervention. **Agentic** patterns use LLM agents with **tools** (orchestrator API, catalog, SQL runner) to decide next steps within guardrails.

## Pattern

```mermaid
flowchart TB
  Trigger[Failed_run_or_event]
  Agent[Agent_with_tools]
  Tools[Orchestrator_API_Catalog_Warehouse]
  Action[Proposed_remediation]
  Human[Human_approve_optional]
  Trigger --> Agent --> Tools
  Agent --> Action --> Human
  Human --> Tools
```

## Agent tool examples

| Tool | Use |
| --- | --- |
| `list_failed_tasks(dag_id)` | Triage |
| `get_lineage(dataset)` | Blast radius |
| `trigger_dag(conf)` | Rerun with params |
| `run_sql_readonly(query)` | Investigate |
| `create_jira_ticket()` | Escalate |

## Orchestration integration

| Level | Maturity |
| --- | --- |
| **L1 Copilot** | Suggest fix in PR comment | 
| **L2 Semi-auto** | Agent opens PR with patch |
| **L3 Auto-remediate** | Retry with dynamic conf (bounded) |
| **L4 Autonomous** | Not recommended for prod without strict policy |

Use **Temporal** or **Step Functions** for durable agent workflows with timeouts and compensation.

## Risks

- Unbounded API calls → cost and blast radius
- Hallucinated SQL → read-only sandboxes first
- Compliance → no prod credentials to external agents

## Related

- [AI Data Engineering Overview](02.03.04.04.01_AI_Data_Engineering_Overview.md)
- [Autonomous Data Platforms](02.03.04.04.10_Autonomous_Data_Platforms.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.03_AI_Code_Generation.md"] = @{
    section="02.03.04.04"; title="AI Code Generation for Pipelines"; template="concept"; tags="ai, code-generation, orchestration"
    body=@"
# AI Code Generation for Pipelines

## Problem

Writing Airflow operators, dbt models, and Kestra tasks is repetitive. **AI code generation** accelerates authoring from natural language or metadata — but output must pass the same CI/CD gates as human code.

## Workflow

```mermaid
flowchart LR
  Spec[Spec_or_metadata]
  LLM[LLM_generates_code]
  CI[CI_lint_test_parse]
  Review[Human_PR_review]
  Deploy[Deploy_to_orchestrator]
  Spec --> LLM --> CI --> Review --> Deploy
```

## High-value use cases

| Use case | Input | Output |
| --- | --- | --- |
| New ingest DAG | Source schema JSON | Python DAG with operators |
| dbt model | Business rule text | SQL + YAML tests |
| Backfill script | Date range + table | Parameterized DAG conf |
| Operator migration | Airflow 2.x deprecations | Refactored imports |

## Quality gates (mandatory)

1. Static parse (`airflow dags list-import-errors`)
2. Unit tests on generated transform logic
3. No secrets in generated code
4. Style/lint (ruff, sqlfluff)

## Related

- [CI/CD for Data](../02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md)
- [AI Pipeline Generation](02.03.04.04.08_AI_Pipeline_Generation.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.04_AI_Data_Mapping.md"] = @{
    section="02.03.04.04"; title="AI Data Mapping"; template="concept"; tags="ai, data-mapping, orchestration"
    body=@"
# AI Data Mapping

## Problem

Source-to-target column mapping for new integrations is slow and error-prone. **AI data mapping** proposes mappings from schema samples and glossary terms; orchestration **materializes** approved mappings into ingest/transform tasks.

## Pattern

| Step | Actor |
| --- | --- |
| 1. Profile source | Automated crawler |
| 2. Propose mapping | LLM + business glossary RAG |
| 3. Review | Data steward in catalog UI |
| 4. Emit config | Mapping YAML in Git |
| 5. Generate tasks | Metadata factory → orchestrator |

```mermaid
flowchart LR
  Src[Source_schema]
  AI[Mapping_suggestions]
  Steward[Steward_approval]
  Meta[Mapping_metadata]
  Orch[Ingest_DAG]
  Src --> AI --> Steward --> Meta --> Orch
```

## Orchestration hook

Mapping version `v3` tagged in metadata → CI regenerates ingest DAG → staged run validates row-level hash compare before prod.

## Related

- [Metadata-Driven ETL](../02.03.04.02_Metadata_Driven/02.03.04.02.02_Metadata_Driven_ETL.md)
- [Configuration-Driven Processing](../02.03.04.02_Metadata_Driven/02.03.04.02.04_Configuration_Driven_Processing.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.05_AI_Data_Quality.md"] = @{
    section="02.03.04.04"; title="AI Data Quality"; template="concept"; tags="ai, data-quality, orchestration"
    body=@"
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

Embed validation as **first-class tasks** — not ad-hoc notebooks after the fact.

## Related

- [Automated Validation](../02.03.04.01_DataOps_Patterns/02.03.04.01.06_Automated_Validation.md)
- [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.06_AI_Lineage_Generation.md"] = @{
    section="02.03.04.04"; title="AI Lineage Generation"; template="concept"; tags="ai, lineage, orchestration"
    body=@"
# AI Lineage Generation

## Problem

Incomplete lineage breaks impact analysis and dataset scheduling. **AI lineage generation** infers edges from SQL, logs, and code when OpenLineage emitters are missing — then **feeds** the orchestrator dependency graph.

## Sources for inference

| Source | Inference |
| --- | --- |
| SQL AST | Table read/write edges |
| dbt manifest | Model dependencies |
| Airflow DAG parse | Task → dataset heuristics |
| Run logs | Actual tables touched |

```mermaid
flowchart LR
  Code[SQL_DAG_code]
  AI[Lineage_inference]
  Cat[Catalog_graph]
  Orch[Dataset_schedules]
  Code --> AI --> Cat --> Orch
```

## Human-in-the-loop

Suggested edges marked `confidence: low` until steward confirms — then bind Airflow Dataset or Dagster asset dependency.

## Related

- [Metadata Automation](../02.03.04.02_Metadata_Driven/02.03.04.02.06_Metadata_Automation.md)
- [Metadata Orchestration](../02.03.04.02_Metadata_Driven/02.03.04.02.07_Metadata_Orchestration.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.07_AI_Metadata_Management.md"] = @{
    section="02.03.04.04"; title="AI Metadata Management"; template="concept"; tags="ai, metadata, orchestration"
    body=@"
# AI Metadata Management

## Problem

Catalogs suffer from stale descriptions, missing owners, and inconsistent tags. **AI metadata management** auto-enriches documentation and links orchestrator objects to catalog entities.

## Capabilities

| Capability | Orchestration link |
| --- | --- |
| Auto-description | From DAG docstring → catalog dataset |
| Tag suggestion | `domain:finance`, `tier:T0` from path and SLA |
| Owner inference | Git blame → steward assignment |
| Duplicate detection | Merge duplicate dataset URIs affecting triggers |

## Sync loop

On each prod DAG deploy, CI job extracts metadata → LLM enriches → catalog PR for steward approval → approved URI used in [Metadata Orchestration](../02.03.04.02_Metadata_Driven/02.03.04.02.07_Metadata_Orchestration.md).

## Related

- [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
- [Orchestration Governance](../../02.03.01_Fundamentals/02.03.01.04_Governance/02.03.01.04.01_Orchestration_Governance.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.08_AI_Pipeline_Generation.md"] = @{
    section="02.03.04.04"; title="AI Pipeline Generation"; template="concept"; tags="ai, pipeline-generation, orchestration"
    body=@"
# AI Pipeline Generation

## Problem

Greenfield pipelines require days of scaffolding. **AI pipeline generation** produces end-to-end drafts: ingest → transform → test → publish, from requirements or source analysis.

## Generation inputs

- Natural language requirement ("daily customer 360 from CRM and orders")
- Source connection metadata
- Target catalog zone (bronze/silver/gold)
- SLA tier and orchestrator target (Airflow, Dagster, Kestra)

## Output bundle

| Artifact | Purpose |
| --- | --- |
| Orchestrator definition | DAG / flow / assets |
| dbt project slice | Transform models |
| CI workflow | Parse and staging deploy |
| Config | Connections template (no secrets) |
| DQ checks | Starter expectations |

```mermaid
flowchart TB
  Req[Requirements]
  Gen[AI_pipeline_generator]
  Bundle[Git_repo_PR]
  CI[CI_and_staging]
  Req --> Gen --> Bundle --> CI
```

## Maturity path

Start with **internal templates + LLM fill** (constrained) before fully free-form generation.

## Related

- [AI Code Generation](02.03.04.04.03_AI_Code_Generation.md)
- [Dynamic Pipeline Generation](../02.03.04.02_Metadata_Driven/02.03.04.02.05_Dynamic_Pipeline_Generation.md)
- [Internal Developer Platform](../02.03.04.03_Platform_Patterns/02.03.04.03.01_Internal_Developer_Platform.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.09_AI_Test_Generation.md"] = @{
    section="02.03.04.04"; title="AI Test Generation"; template="concept"; tags="ai, testing, orchestration"
    body=@"
# AI Test Generation

## Problem

Data tests lag pipeline development. **AI test generation** proposes unit, contract, and integration tests from schemas, samples, and business rules — integrated as orchestrated test tasks.

## Pattern

| Test type | AI role | Orchestration |
| --- | --- | --- |
| **Column constraints** | Infer min/max, uniqueness | dbt test YAML in CI |
| **Regression** | Compare prod vs staging stats | Staging DAG gate task |
| **Edge cases** | Synthetic null/spike rows | Unit test fixtures |
| **Integration** | Suggest task mocks | CI workflow |

Embed generated tests in **CI before deploy** and as **tasks before publish** in prod DAGs.

## Related

- [Data Testing Strategy](../02.03.04.01_DataOps_Patterns/02.03.04.01.05_Data_Testing_Strategy.md)
- [Automated Validation](../02.03.04.01_DataOps_Patterns/02.03.04.01.06_Automated_Validation.md)
"@
}

$patterns["02.03.04.04_AI_Assisted\02.03.04.04.10_Autonomous_Data_Platforms.md"] = @{
    section="02.03.04.04"; title="Autonomous Data Platforms"; template="concept"; tags="ai, autonomous, orchestration"
    body=@"
# Autonomous Data Platforms

## Problem

The industry vision of **fully autonomous** data platforms — self-healing pipelines, auto-scaling, auto-remediation without humans — exceeds today's production safety bar. This doc frames **realistic autonomy levels** for orchestration architecture.

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

- [Active Metadata](../../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md) for closed-loop control
- Policy engine (OPA) with hard limits on agent actions
- Full audit trail and rollback DAGs
- Cost caps on compute and LLM API spend

## Realistic 2026 target

Most enterprises should aim for **Level 2–3**: AI accelerates build and triage; orchestrator executes deterministic graphs; agents only act within pre-approved tool lists.

## Related

- [Agentic Data Engineering](02.03.04.04.02_Agentic_Data_Engineering.md)
- [AI Data Engineering Overview](02.03.04.04.01_AI_Data_Engineering_Overview.md)
- [Metadata Orchestration](../02.03.04.02_Metadata_Driven/02.03.04.02.07_Metadata_Orchestration.md)
"@
}

# Write all pattern files
foreach ($rel in $patterns.Keys) {
    $p = $patterns[$rel]
    $path = Join-Path $Base $rel
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $content = (FM $p.title $p.section $p.template $p.tags) + $p.body
    [IO.File]::WriteAllText($path, $content)
}

# Section README
$readme = (FM "Architecture Patterns" "02.03.04" "hub" "orchestration, patterns, dataops, metadata-driven, ai") + @"
# 02.03.04 Architecture Patterns

Orchestration **architecture patterns** for DataOps, metadata-driven pipelines, platform engineering, and AI-assisted workflows.

## Start here

- [Metadata-Driven Framework](02.03.04.02_Metadata_Driven/02.03.04.02.01_Metadata_Driven_Framework.md) — core pattern for scalable pipeline factories
- [CI/CD for Data](02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md) — deploy DAGs like application code
- [AI Data Engineering Overview](02.03.04.04_AI_Assisted/02.03.04.04.01_AI_Data_Engineering_Overview.md) — AI in the orchestration lifecycle

## Subsections

### 02.03.04.01 DataOps Patterns

| Doc | Focus |
| --- | --- |
| [CI/CD for Data](02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md) | Pipeline CI/CD stages and gates |
| [GitOps for Data](02.03.04.01_DataOps_Patterns/02.03.04.01.02_GitOps_For_Data.md) | Git as source of truth for orchestrator |
| [Data Deployment Strategy](02.03.04.01_DataOps_Patterns/02.03.04.01.03_Data_Deployment_Strategy.md) | Parallel, backfill, rollback |
| [Data Release Management](02.03.04.01_DataOps_Patterns/02.03.04.01.04_Data_Release_Management.md) | Releases, freezes, bundles |
| [Data Testing Strategy](02.03.04.01_DataOps_Patterns/02.03.04.01.05_Data_Testing_Strategy.md) | Test pyramid for pipelines |
| [Automated Validation](02.03.04.01_DataOps_Patterns/02.03.04.01.06_Automated_Validation.md) | In-DAG validation gates |

### 02.03.04.02 Metadata-Driven

| Doc | Focus |
| --- | --- |
| [Metadata-Driven Framework](02.03.04.02_Metadata_Driven/02.03.04.02.01_Metadata_Driven_Framework.md) | Reference framework |
| [Metadata-Driven ETL](02.03.04.02_Metadata_Driven/02.03.04.02.02_Metadata_Driven_ETL.md) | Parameterized ELT |
| [Metadata-Driven Transformations](02.03.04.02_Metadata_Driven/02.03.04.02.03_Metadata_Driven_Transformations.md) | dbt/asset-driven order |
| [Configuration-Driven Processing](02.03.04.02_Metadata_Driven/02.03.04.02.04_Configuration_Driven_Processing.md) | Externalized config |
| [Dynamic Pipeline Generation](02.03.04.02_Metadata_Driven/02.03.04.02.05_Dynamic_Pipeline_Generation.md) | Runtime/parse-time DAGs |
| [Metadata Automation](02.03.04.02_Metadata_Driven/02.03.04.02.06_Metadata_Automation.md) | Catalog sync |
| [Metadata Orchestration](02.03.04.02_Metadata_Driven/02.03.04.02.07_Metadata_Orchestration.md) | Dataset-triggered schedules |

### 02.03.04.03 Platform Patterns

| Doc | Focus |
| --- | --- |
| [Internal Developer Platform](02.03.04.03_Platform_Patterns/02.03.04.03.01_Internal_Developer_Platform.md) | Golden-path self-service |

### 02.03.04.04 AI-Assisted

| Doc | Focus |
| --- | --- |
| [AI Data Engineering Overview](02.03.04.04_AI_Assisted/02.03.04.04.01_AI_Data_Engineering_Overview.md) | Scope and guardrails |
| [Agentic Data Engineering](02.03.04.04_AI_Assisted/02.03.04.04.02_Agentic_Data_Engineering.md) | Agents + orchestrator tools |
| [AI Code Generation](02.03.04.04_AI_Assisted/02.03.04.04.03_AI_Code_Generation.md) | Task/DAG codegen |
| [AI Data Mapping](02.03.04.04_AI_Assisted/02.03.04.04.04_AI_Data_Mapping.md) | Mapping → ingest tasks |
| [AI Data Quality](02.03.04.04_AI_Assisted/02.03.04.04.05_AI_Data_Quality.md) | Anomaly and NL rules |
| [AI Lineage Generation](02.03.04.04_AI_Assisted/02.03.04.04.06_AI_Lineage_Generation.md) | Inferred dependencies |
| [AI Metadata Management](02.03.04.04_AI_Assisted/02.03.04.04.07_AI_Metadata_Management.md) | Catalog enrichment |
| [AI Pipeline Generation](02.03.04.04_AI_Assisted/02.03.04.04.08_AI_Pipeline_Generation.md) | End-to-end drafts |
| [AI Test Generation](02.03.04.04_AI_Assisted/02.03.04.04.09_AI_Test_Generation.md) | Test cases in CI/DAG |
| [Autonomous Data Platforms](02.03.04.04_AI_Assisted/02.03.04.04.10_Autonomous_Data_Platforms.md) | Autonomy levels |

## Related

- [02.03 Data Orchestration Architecture](../README.md)
- [Fundamentals](../02.03.01_Fundamentals/README.md)
- [Active Metadata](../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
- [Cloud Services](../02.03.02_Cloud_Services/README.md)
"@
[IO.File]::WriteAllText((Join-Path $Base "README.md"), $readme)

Write-Host "Wrote $($patterns.Count) pattern docs + README"
