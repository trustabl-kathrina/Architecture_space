# Generate 02.03.08-02.03.09 orchestration sections
$OrchRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture"))
$utf8 = New-Object System.Text.UTF8Encoding $false

function FM($title, $section, $template, $tags) {
    return @"
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

function Write-Doc($relPath, $title, $section, $template, $tags, $body) {
    $path = Join-Path $OrchRoot $relPath
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllText($path, (FM $title $section $template $tags) + $body.TrimStart(), $utf8)
}

# --- 02.03.08 Integration Patterns ---
Write-Doc "02.03.08_Integration_Patterns\02.03.08.01_Self_Service_Platform.md" "Self-Service Platform Integration" "02.03.08.01" "concept" "integration, self-service, platform" @'
# Self-Service Platform Integration

## Problem

Data engineers need pipelines **without ticketing every connection and deploy**. Self-service integrates orchestration with **portal, templates, and policy** so teams onboard safely.

## Integration architecture

```mermaid
flowchart TB
  Eng[Data_Engineer]
  Portal[Backstage_or_Internal_Portal]
  Git[Git_Template_Repo]
  CI[CI_CD]
  Orch[Shared_Orchestrator]
  IAM[Secrets_and_RBAC]
  Eng --> Portal --> Git --> CI --> Orch
  Portal --> IAM
  Orch --> IAM
```

## Integration points

| System | Integration | Orchestration outcome |
| --- | --- | --- |
| **Portal** | Scaffolds repo, registers team namespace | New DAG repo in 15 min |
| **IAM / vault** | Auto-provision connection stubs | No shared prod credentials |
| **CI** | Team pipeline from template | Parse test on every PR |
| **Orchestrator API** | Sync on merge to team folder | DAG live in dev then prod |
| **Catalog** | Register datasets on deploy | Lineage from day one |
| **Cost tags** | Mandatory `cost_center`, `domain` | Chargeback reports |

## Self-service guardrails

| Guardrail | Enforcement |
| --- | --- |
| Approved operators only | CI allow-list import scan |
| Max runtime / retries | Policy on DAG default args |
| Prod deploy approval | Environment protection rules |
| Connection scope | Team cannot use other team conn ids |

## Related

- [Self-Service Engineering](02.03.08.02_Self_Service_Engineering.md)
- [Internal Developer Platform](../02.03.04_Architecture_Patterns/02.03.04.03_Platform_Patterns/02.03.04.03.01_Internal_Developer_Platform.md)
- [Multi-Tenant Platform Reference](../02.03.09_Reference_Architectures/02.03.09.04_Multi_Tenant_Data_Platform_Reference.md)
'@

Write-Doc "02.03.08_Integration_Patterns\02.03.08.02_Self_Service_Engineering.md" "Self-Service Engineering Integration" "02.03.08.02" "concept" "integration, platform-engineering, self-service" @'
# Self-Service Engineering Integration

## Problem

**Platform engineering** teams expose orchestration as a **product** with SLAs, docs, and paved roads - not raw Airflow UI access.

## Platform API surface

| Capability | Consumer experience |
| --- | --- |
| `create_pipeline(repo)` | Cookiecutter + CI webhook |
| `request_connection(type, env)` | Ticket or automated vault path |
| `trigger_backfill(dag, dates)` | Portal form -> orchestrator API |
| `get_run_status(dag_run_id)` | Unified status API |
| `list_lineage(dataset)` | Catalog deep-link from run |

## Integration with engineering tools

| Tool | Pattern |
| --- | --- |
| **Backstage** | Software template + orchestrator plugin |
| **ServiceNow / Jira** | Connection requests, prod deploy approvals |
| **Slack / Teams** | Run failure notifications with lineage context |
| **Datadog / Grafana** | Orchestrator metrics dashboards per team |
| **Terraform** | MWAA/Composer environment as code |

## SLOs for internal platform

| SLO | Target example |
| --- | --- |
| Orchestrator availability | 99.9% control plane |
| Deploy latency | p95 < 15 min after merge |
| Support response | P1 platform < 1 h |

## Related

- [Self-Service Platform](02.03.08.01_Self_Service_Platform.md)
- [Platform Engineering](../02.03.02_Cloud_Services/02.03.02.06_Platform_Engineering/README.md)
- [CI/CD for Data](../02.03.04_Architecture_Patterns/02.03.04.01_DataOps_Patterns/02.03.04.01.01_CI_CD_For_Data.md)
'@

Write-Doc "02.03.08_Integration_Patterns\02.03.08.03_Catalog_And_Lineage_Integration.md" "Catalog and Lineage Integration" "02.03.08.03" "concept" "integration, catalog, lineage, openlineage" @'
# Catalog and Lineage Integration

## Problem

Orchestration without catalog integration produces **orphan runs** - no impact analysis, no dataset-triggered schedules, weak governance.

## Reference flow

```mermaid
flowchart LR
  Task[Orchestrator_Task]
  OL[OpenLineage_Emitter]
  Bus[Metadata_Bus_optional]
  Cat[Data_Catalog]
  Task --> OL --> Cat
  Bus --> Cat
  Cat --> Trigger[Dataset_Schedule_or_Alert]
  Trigger --> Task
```

## Integration patterns

| Pattern | Description |
| --- | --- |
| **Emit on task success** | Operator wrapper posts OpenLineage event |
| **Register on deploy** | CI creates/updates dataset stubs |
| **Sync run freshness** | Last success timestamp -> catalog SLA field |
| **Impact on failure** | Catalog notifies downstream owners from lineage |
| **Dataset-triggered DAG** | Airflow Datasets / Dagster assets from catalog URI |

## Catalog platforms

| Platform | Integration approach |
| --- | --- |
| DataHub | OpenLineage ingestion, Airflow plugin |
| Unity Catalog | Table FQN in lineage facets |
| Purview | ADF + custom lineage from Airflow |
| Collibra | API sync from metadata automation job |

## Required metadata contract

- Dataset URI / FQN stable across systems
- `dag_id`, task id, run id in lineage facets
- Owner and tier for alert routing

## Related

- [Active Metadata](../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md)
- [Metadata Automation](../02.03.04_Architecture_Patterns/02.03.04.02_Metadata_Driven/02.03.04.02.06_Metadata_Automation.md)
- [Metadata Reference Architecture](../02.03.09_Reference_Architectures/02.03.09.01_Metadata_Reference_Architecture.md)
'@

Write-Doc "02.03.08_Integration_Patterns\02.03.08.04_Observability_Integration.md" "Observability Integration" "02.03.08.04" "concept" "integration, observability, monitoring" @'
# Observability Integration

## Problem

Task **success/fail in UI** is insufficient for enterprise ops. Integrate orchestration with **metrics, logs, traces, and data quality** observability.

## Three pillars mapping

| Pillar | Orchestration signals | Integration |
| --- | --- | --- |
| **Metrics** | Task duration, queue depth, SLA miss | Prometheus statsd, CloudWatch, OTel |
| **Logs** | Task stdout, scheduler logs | ELK, Cloud Logging, Loki |
| **Traces** | Cross-service pipeline steps | OTel spans from operators |

## Key metrics (golden signals)

| Metric | Alert when |
| --- | --- |
| `orchestrator_task_queue_depth` | High for > 30 min |
| `dag_run_duration_seconds` p99 | Exceeds SLA budget |
| `task_failure_rate` | Spike vs 7-day baseline |
| `scheduler_heartbeat` | Missing |
| `metadata_db_connections` | Near pool limit |

## Data observability bridge

| Tool | Integration |
| --- | --- |
| Monte Carlo / Bigeye | Ingest orchestrator run ids on incidents |
| dbt Cloud / Elementary | Test failures trigger DAG branch |
| Great Expectations | Checkpoint task -> observability event |

## Related

- [02.04 Data Observability Architecture](../../02.04_Data_Observability_Architecture/README.md)
- [Automated Validation](../02.03.04_Architecture_Patterns/02.03.04.01_DataOps_Patterns/02.03.04.01.06_Automated_Validation.md)
- [SLA Management](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.04_SLA_Management.md)
'@

Write-Doc "02.03.08_Integration_Patterns\02.03.08.05_Event_Driven_Trigger_Integration.md" "Event-Driven Trigger Integration" "02.03.08.05" "concept" "integration, event-driven, triggers" @'
# Event-Driven Trigger Integration

## Problem

Batch pipelines should start when **events** occur - file landed, stream checkpoint, catalog freshness - not only at fixed cron.

## Trigger sources

| Source | Event | Orchestrator action |
| --- | --- | --- |
| **Object storage** | S3/GCS blob created | Lambda/Cloud Function -> trigger DAG |
| **Message bus** | Kafka/Pub/Sub message | Consumer calls orchestrator REST |
| **Catalog** | Dataset updated | Dataset schedule / sensor |
| **CI/CD** | Deploy complete | Smoke test DAG |
| **Webhook** | SaaS callback | Airflow HTTP trigger / Kestra webhook |

```mermaid
flowchart LR
  Event[S3_PubSub_Catalog]
  Bridge[Trigger_Bridge]
  API[Orchestrator_API]
  DAG[DAG_Run]
  Event --> Bridge --> API --> DAG
```

## Idempotency and dedup

| Concern | Pattern |
| --- | --- |
| Duplicate events | `dag_run_id` dedup key, execution date logic |
| Partial files | Wait for manifest or multi-part complete flag |
| Storm of triggers | Rate limit queue, pool cap |

## Cloud mappings

| Cloud | Bridge pattern |
| --- | --- |
| AWS | EventBridge -> Lambda -> MWAA API |
| GCP | Eventarc -> Cloud Run -> Composer API |
| Azure | Event Grid -> Function -> ADF trigger |

## Related

- [Metadata Orchestration](../02.03.04_Architecture_Patterns/02.03.04.02_Metadata_Driven/02.03.04.02.07_Metadata_Orchestration.md)
- [Scheduling Patterns](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.01_Scheduling_Patterns.md)
'@

Write-Doc "02.03.08_Integration_Patterns\README.md" "Integration Patterns" "02.03.08" "hub" "integration, orchestration" @'
# 02.03.08 Integration Patterns

How orchestration **integrates** with platform, catalog, observability, and event systems.

## Patterns

| Doc | Focus |
| --- | --- |
| [Self-Service Platform](02.03.08.01_Self_Service_Platform.md) | Portal, CI, RBAC integration |
| [Self-Service Engineering](02.03.08.02_Self_Service_Engineering.md) | Platform API and SLOs |
| [Catalog and Lineage](02.03.08.03_Catalog_And_Lineage_Integration.md) | OpenLineage, dataset triggers |
| [Observability](02.03.08.04_Observability_Integration.md) | Metrics, logs, data observability |
| [Event-Driven Triggers](02.03.08.05_Event_Driven_Trigger_Integration.md) | S3, Pub/Sub, webhooks |

## Related

- [Architecture Patterns](../02.03.04_Architecture_Patterns/README.md)
- [Reference Architectures](../02.03.09_Reference_Architectures/README.md)
'@

# --- 02.03.09 Reference Architectures ---
Write-Doc "02.03.09_Reference_Architectures\02.03.09.01_Metadata_Reference_Architecture.md" "Metadata-Driven Orchestration Reference Architecture" "02.03.09.01" "concept" "reference-architecture, metadata, orchestration" @'
# Metadata-Driven Orchestration Reference Architecture

## Purpose

End-to-end reference for **metadata-driven batch orchestration** - catalog, lineage, and scheduler closed loop.

## Architecture

```mermaid
flowchart TB
  subgraph sources [Data_Sources]
    SaaS[SaaS_APIs]
    Files[Object_Storage]
    DB[Operational_DBs]
  end
  subgraph orchestration [Orchestration_Layer]
    Orch[Airflow_Dagster_or_Kestra]
    Factory[Metadata_Factory]
  end
  subgraph metadata [Active_Metadata]
    Cat[Data_Catalog]
    OL[OpenLineage]
    DQ[Quality_Signals]
  end
  subgraph consume [Consumption]
    WH[Warehouse_Lakehouse]
    BI[BI_and_ML]
  end
  MetaDB[(Pipeline_Metadata_DB)]
  sources --> Orch
  MetaDB --> Factory --> Orch
  Orch --> WH
  Orch --> OL --> Cat
  DQ --> Cat
  Cat -->|dataset_triggers| Orch
  WH --> BI
```

## Components

| Layer | Responsibility |
| --- | --- |
| **Pipeline metadata DB** | Sources, schedules, SLAs, mappings |
| **Factory / compiler** | Generates DAGs or assets from metadata |
| **Orchestrator** | Schedules, retries, pools |
| **Catalog** | Datasets, lineage, ownership |
| **Quality** | Checks feed active metadata |
| **Warehouse** | Bronze/silver/gold execution target |

## Non-functional requirements

| NFR | Target |
| --- | --- |
| T0 SLA | 99.5% on-time completion |
| Lineage coverage | 100% prod tasks emit OpenLineage |
| Deploy frequency | Daily per team with CI gates |
| RTO control plane | < 1 h |

## Related

- [Metadata-Driven Framework](../02.03.04_Architecture_Patterns/02.03.04.02_Metadata_Driven/02.03.04.02.01_Metadata_Driven_Framework.md)
- [Catalog Integration](../02.03.08_Integration_Patterns/02.03.08.03_Catalog_And_Lineage_Integration.md)
'@

Write-Doc "02.03.09_Reference_Architectures\02.03.09.02_Enterprise_Batch_Orchestration_Reference.md" "Enterprise Batch Orchestration Reference Architecture" "02.03.09.02" "concept" "reference-architecture, enterprise, batch" @'
# Enterprise Batch Orchestration Reference Architecture

## Purpose

Reference for **large-scale nightly/hourly ELT** - multi-team Airflow (or equivalent) on managed Kubernetes with shared services.

## Architecture

```mermaid
flowchart TB
  subgraph cicd [GitOps_CI_CD]
    Git[DAG_Repos]
    CI[Parse_Test_Deploy]
  end
  subgraph control [Control_Plane_HA]
    Sch[Scheduler_HA]
    Web[Webserver]
    Meta[(Postgres_Metadata)]
  end
  subgraph exec [Execution]
    Celery[Celery_or_K8s_Workers]
    Spark[Spark_EMR_Dataproc]
    dbt[dbt_Warehouse]
  end
  subgraph shared [Shared_Services]
    Vault[Secrets]
    Obs[Observability]
    Cat[Catalog]
  end
  Git --> CI --> Sch
  Sch --> Meta
  Sch --> Celery
  Celery --> Spark
  Celery --> dbt
  Celery --> Obs
  Celery --> Cat
  Vault --> Celery
```

## Design decisions

| Decision | Rationale |
| --- | --- |
| Managed Airflow (Composer/MWAA) or K8s Airflow | Reduce scheduler ops |
| Celery or K8s executor | Burst parallelism for ELT |
| dbt in DAG | Transform standardization |
| Per-team pools | Noisy neighbor isolation |
| Central observability | Single pane for 1000+ DAGs |

## Scaling guidelines

| Scale | DAGs | Workers | Metadata DB |
| --- | ---: | ---: | --- |
| Medium | 50-200 | 10-30 | db.r6g.large |
| Large | 200-1000 | 30-100 | db.r6g.xlarge+ HA |
| Very large | 1000+ | 100+ sharded teams | Dedicated DBA tuning |

## Related

- [Composer vs MWAA comparison](../02.03.06_Comparisons/02.03.06.02_Composer_vs_MWAA_vs_Self_Hosted_Airflow.md)
- [Enterprise Batch system design case](../02.03.07_Interview_Questions/02.03.07.05_System_Design_Orchestration_Cases.md)
'@

Write-Doc "02.03.09_Reference_Architectures\02.03.09.03_Serverless_Orchestration_Reference.md" "Serverless Orchestration Reference Architecture" "02.03.09.03" "concept" "reference-architecture, serverless" @'
# Serverless Orchestration Reference Architecture

## Purpose

Reference for **low-ops glue workflows** - event triggers, short chains, no persistent worker fleet.

## Architecture

```mermaid
flowchart LR
  Event[EventBridge_or_Eventarc]
  WF[Step_Functions_or_Cloud_Workflows]
  L[Lambda_CloudRun_Functions]
  WH[Warehouse_or_API]
  Event --> WF --> L --> WH
```

## When this fits

| Fit | Not fit |
| --- | --- |
| < 30 min steps, API calls | Multi-hour Spark jobs |
| Spiky, infrequent runs | 500+ interdependent batch DAGs |
| Cloud-native IAM | Portable multi-cloud DAG mesh |

## AWS reference stack

EventBridge -> Step Functions -> Lambda / Glue / Batch -> S3/Redshift. Heavy ELT delegated to **MWAA** separately.

## GCP reference stack

Eventarc -> Cloud Workflows -> Cloud Run / BigQuery jobs. Batch analytics on **Composer**.

## Hybrid pattern

**Serverless for edges**, **Airflow for core ELT** - linked via orchestrator API triggers.

## Related

- [Step Functions vs Cloud Workflows](../02.03.06_Comparisons/02.03.06.05_Cloud_Workflows_vs_Step_Functions.md)
- [Event-Driven Triggers](../02.03.08_Integration_Patterns/02.03.08.05_Event_Driven_Trigger_Integration.md)
'@

Write-Doc "02.03.09_Reference_Architectures\02.03.09.04_Multi_Tenant_Data_Platform_Reference.md" "Multi-Tenant Data Platform Reference Architecture" "02.03.09.04" "concept" "reference-architecture, multi-tenant, platform" @'
# Multi-Tenant Data Platform Reference Architecture

## Purpose

Reference for **shared orchestration platform** serving many data product teams with isolation, quotas, and self-service.

## Architecture

```mermaid
flowchart TB
  subgraph teams [Data_Teams]
    T1[Team_A_Repo]
    T2[Team_B_Repo]
    T3[Team_C_Repo]
  end
  subgraph platform [Platform_Layer]
    Portal[Self_Service_Portal]
    CI[Shared_CI_Templates]
    Orch[Multi_Tenant_Orchestrator]
  end
  subgraph isolate [Isolation]
    RBAC[RBAC_and_Namespaces]
    Pools[Pools_and_Quotas]
    Tags[Cost_and_Domain_Tags]
  end
  T1 --> CI
  T2 --> CI
  T3 --> CI
  CI --> Orch
  Portal --> Orch
  Orch --> RBAC
  Orch --> Pools
  Orch --> Tags
```

## Tenancy models

| Model | Isolation | Complexity |
| --- | --- | --- |
| **Folder + RBAC** | DAG prefix per team | Low |
| **Namespace / deployment** | Prefect work pools, Dagster code locations | Medium |
| **Cluster per team** | Separate MWAA/Composer env | High cost, strong isolation |

## Platform mandates

- Golden path template repos only for prod
- Mandatory tags: `domain`, `cost_center`, `tier`, `owner`
- No shared production connections across teams
- Per-team pool slot caps

## Related

- [Self-Service Platform](../02.03.08_Integration_Patterns/02.03.08.01_Self_Service_Platform.md)
- [Internal Developer Platform](../02.03.04_Architecture_Patterns/02.03.04.03_Platform_Patterns/02.03.04.03.01_Internal_Developer_Platform.md)
'@

Write-Doc "02.03.09_Reference_Architectures\README.md" "Reference Architectures" "02.03.09" "hub" "reference-architecture, orchestration" @'
# 02.03.09 Reference Architectures

**End-to-end reference diagrams** for common orchestration estates.

## Architectures

| Doc | Scenario |
| --- | --- |
| [Metadata-Driven Orchestration](02.03.09.01_Metadata_Reference_Architecture.md) | Catalog + factory + active metadata |
| [Enterprise Batch](02.03.09.02_Enterprise_Batch_Orchestration_Reference.md) | Large-scale ELT, HA Airflow |
| [Serverless Orchestration](02.03.09.03_Serverless_Orchestration_Reference.md) | Step Functions / Cloud Workflows glue |
| [Multi-Tenant Platform](02.03.09.04_Multi_Tenant_Data_Platform_Reference.md) | Shared platform, team isolation |

## Related

- [Cloud Orchestration Reference](../02.03.02_Cloud_Services/02.03.02.01_Overview/02.03.02.01.01_Cloud_Orchestration_Reference_Architecture.md)
- [Integration Patterns](../02.03.08_Integration_Patterns/README.md)
- [Architecture Patterns](../02.03.04_Architecture_Patterns/README.md)
'@

Write-Host "02.03.08-09 done"
