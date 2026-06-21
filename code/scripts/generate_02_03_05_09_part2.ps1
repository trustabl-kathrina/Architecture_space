# Generate 02.03.06-02.03.09 orchestration sections
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

# --- 02.03.06 Comparisons ---
Write-Doc "02.03.06_Comparisons\02.03.06.01_Airflow_vs_Prefect_vs_Dagster.md" "Airflow vs Prefect vs Dagster" "02.03.06.01" "evaluation" "comparison, airflow, prefect, dagster" @'
# Apache Airflow vs Prefect vs Dagster

## Summary

Three leading **open source Python orchestrators** for data engineering. **Airflow** is the incumbent DAG standard. **Prefect** emphasizes dynamic flows and hybrid execution. **Dagster** centers on software-defined assets and built-in lineage.

| Lens | Airflow | Prefect | Dagster |
| --- | --- | --- | --- |
| Primary model | DAG of tasks | Flows and tasks | Assets and ops |
| Best fit | Largest ecosystem, portable | Modern Python, dynamic | Data platform, lineage-first |
| Learning curve | Medium (operators, executors) | Medium-low | Medium-high (assets) |
| Managed options | Composer, MWAA, Astronomer | Prefect Cloud | Dagster Cloud |

## Architecture

| Criterion | Airflow | Prefect | Dagster |
| --- | --- | --- | --- |
| Control plane | Scheduler + webserver + DB | Server or Cloud API | Webserver + daemon + DB |
| Execution | Workers (Celery/K8s/local) | Agents / work pools | Run coordinators, K8s/Docker |
| Definition | Python DAG files | Python `@flow` | Python assets/ops |
| Scheduling | Cron, datasets, timetables | Deployments, schedules | Schedules, sensors, partitions |
| Lineage | Datasets (2.4+), OpenLineage | Metadata API | Native asset lineage |

## Developer experience

| Criterion | Airflow | Prefect | Dagster |
| --- | --- | --- | --- |
| Local dev | airflow standalone | `prefect flow serve` | `dagster dev` |
| Dynamic DAGs | TaskFlow, dynamic mapping | Native | Partitions, dynamic ops |
| Testing | DAG tests, task unit tests | Flow tests | Asset/op tests |
| UI | Mature graph view | Run-centric | Asset graph, runs |

## Operations

| Criterion | Airflow | Prefect | Dagster |
| --- | --- | --- | --- |
| Self-host complexity | High | Medium | Medium |
| Upgrade cadence | Major versions need planning | Faster iteration | Medium |
| Community / hiring | Largest | Growing | Growing |

## Recommendation

| Scenario | Pick |
| --- | --- |
| Maximum operators, MWAA/Composer path | **Airflow** |
| Dynamic Python, hybrid workers | **Prefect** |
| Asset catalog alignment, partitions | **Dagster** |

## Related

- [Top 10 guides](../02.03.03_Top_10/README.md)
- [Orchestrator Selection Framework](02.03.06.06_Orchestrator_Selection_Framework.md)
'@

Write-Doc "02.03.06_Comparisons\02.03.06.02_Composer_vs_MWAA_vs_Self_Hosted_Airflow.md" "Composer vs MWAA vs Self-Hosted Airflow" "02.03.06.02" "evaluation" "comparison, composer, mwaa, airflow" @'
# Cloud Composer vs MWAA vs Self-Hosted Airflow

## Summary

All three run **Apache Airflow** with different operational models. Choice is driven by **cloud anchor**, **ops appetite**, and **network topology**.

| Lens | Cloud Composer (GCP) | Amazon MWAA (AWS) | Self-hosted Airflow |
| --- | --- | --- | --- |
| Ops model | Google-managed GKE + Airflow | AWS-managed control plane | You operate all layers |
| Best fit | GCP-native data stack | AWS-native, private VPC | Multi-cloud, full control |
| Cost predictability | Environment + GKE + workers | Environment + workers | Infra + staff time |

## Comparison matrix

| Criterion | Composer 2/3 | MWAA | Self-hosted |
| --- | --- | --- | --- |
| Airflow versioning | Google-supported runtime | AWS-supported runtime | Pin any version |
| Executor | Celery/K8s (env dependent) | Celery (default) | Any executor |
| DAG storage | GCS sync | S3 sync | Git, S3, PVC |
| Networking | VPC-SC, Private IP | VPC, SG | Custom |
| IAM integration | GCP IAM | AWS IAM | Custom |
| Upgrade control | Google schedule | AWS schedule | Full control |
| Day-2 burden | Low-medium | Low-medium | High |

## When to choose

| Choose Composer when | Choose MWAA when | Choose self-hosted when |
| --- | --- | --- |
| BigQuery, GCS, Dataproc hub | Glue, Redshift, S3 hub | Multi-cloud DAGs, custom executors |
| GCP org standards | AWS landing zone | Astronomer/Helm already standardized |

## Related

- [Composer Learning Guide](../02.03.02_Cloud_Services/02.03.02.02_GCP/02.03.02.02.03_Cloud_Composer_Learning_Guide/README.md)
- [MWAA Learning Guide](../02.03.02_Cloud_Services/02.03.02.03_AWS/02.03.02.03.04_MWAA_Learning_Guide/README.md)
'@

Write-Doc "02.03.06_Comparisons\02.03.06.03_Step_Functions_vs_Temporal_vs_Airflow.md" "Step Functions vs Temporal vs Airflow" "02.03.06.03" "evaluation" "comparison, step-functions, temporal, airflow" @'
# AWS Step Functions vs Temporal vs Airflow

## Summary

**Airflow** = batch DAG orchestration. **Step Functions** = AWS-native state machines. **Temporal** = durable execution for long-lived, failure-prone workflows.

| Lens | Step Functions | Temporal | Airflow |
| --- | --- | --- | --- |
| Primary model | JSON/ASL state machine | Code-first workflows + activities | Python DAG |
| Best fit | AWS glue, short chains | Sagas, human-in-loop, micro-batch coordination | ELT, schedules, data deps |
| Max duration | 1 year (Standard) | Unlimited (with continue-as-new) | Worker-bound (hours-days) |
| Portability | AWS only | Self-host + Temporal Cloud | High |

## Feature matrix

| Criterion | Step Functions | Temporal | Airflow |
| --- | --- | --- | --- |
| Language | ASL + optional SDKs | Go/Java/Python/TS | Python (primary) |
| State durability | Managed by AWS | Event-sourced history | Task instance metadata |
| Visual design | Workflow Studio | Web UI (history) | Graph view |
| Pricing | Per state transition | Self-host infra or Cloud | Self-host or MWAA/Composer |
| Data pipeline ops | Limited operators | Custom activities | Rich operator ecosystem |

## Recommendation

| Use case | Pick |
| --- | --- |
| Nightly warehouse ELT | **Airflow** |
| Lambda/Batch chain in AWS only | **Step Functions** |
| Order fulfillment saga, durable timers | **Temporal** |
| Hybrid: ELT + saga | Airflow + Step Functions (bounded) |

## Related

- [Step Functions Learning Guide](../02.03.02_Cloud_Services/02.03.02.03_AWS/02.03.02.03.05_Step_Functions_Learning_Guide/README.md)
- [Temporal Top 10 guide](../02.03.03_Top_10/02.03.03.05_Temporal_Learning_Guide/README.md)
'@

Write-Doc "02.03.06_Comparisons\02.03.06.04_ADF_vs_Airflow.md" "Azure Data Factory vs Airflow" "02.03.06.04" "evaluation" "comparison, adf, airflow, azure" @'
# Azure Data Factory vs Apache Airflow

## Summary

**ADF** is Azure's visual **data factory** with copy/transform activities and tight Fabric/Synapse integration. **Airflow** is code-first DAG orchestration portable across clouds.

| Lens | Azure Data Factory | Airflow (incl. self-host) |
| --- | --- | --- |
| Authoring | UI + JSON/ARM/Bicep | Python DAGs |
| Best fit | Azure-centric ETL, SSIS migration | Custom logic, multi-cloud, dbt-in-DAG |
| Integration | Synapse, Fabric, Azure SQL, Blob | Operators for any system |
| Git / CI | ARM templates, ADF Git integration | Native GitOps patterns |

## Comparison

| Criterion | ADF | Airflow |
| --- | --- | --- |
| Learning curve for DE | Low (visual) | Medium |
| Complex branching | Activity chains | Full Python |
| On-prem / hybrid | SHIR, SSIS IR | Agents anywhere |
| Lineage | Purview integration | OpenLineage plugins |
| Cost model | Pipeline activity runs | Infra + compute |
| OSS portability | Azure-bound | High |

## Recommendation

| Scenario | Pick |
| --- | --- |
| Microsoft-first lakehouse, low-code | **ADF / Fabric Data Factory** |
| dbt + Python transforms + GCP/AWS too | **Airflow** |
| Lift-and-shift SSIS | **ADF with IR** |

## Related

- [ADF Learning Guide](../02.03.02_Cloud_Services/02.03.02.04_Azure/02.03.02.04.03_Azure_Data_Factory_Learning_Guide/README.md)
- [Airflow Top 10 guide](../02.03.03_Top_10/02.03.03.02_Apache_Airflow_Learning_Guide/README.md)
'@

Write-Doc "02.03.06_Comparisons\02.03.06.05_Cloud_Workflows_vs_Step_Functions.md" "Cloud Workflows vs Step Functions" "02.03.06.05" "evaluation" "comparison, cloud-workflows, step-functions" @'
# Google Cloud Workflows vs AWS Step Functions

## Summary

Both are **serverless workflow** engines for short orchestration glue. Workflows uses **YAML** and GCP APIs; Step Functions uses **ASL/JSON** and AWS services.

| Lens | Cloud Workflows | AWS Step Functions |
| --- | --- | --- |
| Definition | YAML workflows | ASL state machine |
| Best fit | GCP microservice glue | AWS Lambda/Batch/Glue chains |
| Pricing | Per step + external calls | Per state transition |
| Data ELT | Not primary | Not primary (use Glue Workflows + MWAA) |

## Matrix

| Criterion | Cloud Workflows | Step Functions |
| --- | --- | --- |
| Max duration | 1 year | 1 year (Standard) |
| Express / sync | HTTP callbacks | Express workflows |
| Connectors | GCP APIs, HTTP | 220+ AWS service integrations |
| Human approval | Callback patterns | Task tokens |
| Local dev | Limited | Step Functions Local |
| IAM | GCP IAM | AWS IAM |

## Recommendation

| Scenario | Pick |
| --- | --- |
| Orchestrate Cloud Run + Pub/Sub on GCP | **Cloud Workflows** |
| Lambda-centric AWS automation | **Step Functions** |
| Heavy batch ELT | Neither alone - use Composer/MWAA |

## Related

- [Cloud Workflows Learning Guide](../02.03.02_Cloud_Services/02.03.02.02_GCP/02.03.02.02.04_Cloud_Workflows_Learning_Guide/README.md)
- [Step Functions Learning Guide](../02.03.02_Cloud_Services/02.03.02.03_AWS/02.03.02.03.05_Step_Functions_Learning_Guide/README.md)
'@

Write-Doc "02.03.06_Comparisons\02.03.06.06_Orchestrator_Selection_Framework.md" "Orchestrator Selection Framework" "02.03.06.06" "evaluation" "comparison, selection, framework" @'
# Orchestrator Selection Framework

## Purpose

Decision framework for **choosing an orchestration platform** - open source, managed cloud, or hybrid.

## Step 1: Classify workload

| Workload type | Examples | Favor |
| --- | --- | --- |
| **Batch ELT** | Nightly marts, dbt | Airflow, Dagster, Prefect |
| **Serverless glue** | 10-step Lambda chain | Step Functions, Cloud Workflows |
| **K8s containers** | Spark-on-K8s, ML | Argo, Flyte, Airflow K8s executor |
| **Durable sagas** | Payments, approvals | Temporal, Step Functions |
| **Visual ETL** | Azure copy pipelines | ADF |
| **Declarative YAML** | Platform GitOps | Kestra, Cloud Workflows |

## Step 2: Constraints

| Constraint | Weight questions |
| --- | --- |
| Cloud anchor | Locked to AWS/GCP/Azure? |
| Ops capacity | Can you run schedulers + DB? |
| Lineage | Need asset-first catalog? |
| Team skills | Python depth? YAML? |
| SLA tier | T0 financial close? |
| Portability | Multi-cloud in 3 years? |

## Step 3: Scorecard (1-5)

Rate candidates on: data engineering fit, ecosystem, self-host ops, cost at your scale, hiring, managed option quality.

## Quick picks

| Profile | Primary | Secondary |
| --- | --- | --- |
| GCP analytics | Composer | Cloud Workflows (glue) |
| AWS analytics | MWAA | Step Functions (glue) |
| Azure Microsoft stack | ADF | Self-host Airflow if needed |
| OSS-first, K8s estate | Airflow or Argo | Kestra for YAML teams |
| Asset platform | Dagster | Airflow for legacy |
| ML platform | Flyte / Metaflow | Airflow |

## Related

- [Orchestration Strategy](../02.03.01_Fundamentals/02.03.01.02_Strategy/02.03.01.02.01_Orchestration_Strategy.md)
- [Top 10 Open Source](../02.03.03_Top_10/README.md)
- [Cloud Services](../02.03.02_Cloud_Services/README.md)
- [All comparisons](README.md)
'@

Write-Doc "02.03.06_Comparisons\README.md" "Comparisons" "02.03.06" "hub" "comparison, orchestration" @'
# 02.03.06 Comparisons

Side-by-side **orchestration technology comparisons** and selection guidance.

## Start here

- [Orchestrator Selection Framework](02.03.06.06_Orchestrator_Selection_Framework.md)

## Comparisons

| Doc | Compares |
| --- | --- |
| [Airflow vs Prefect vs Dagster](02.03.06.01_Airflow_vs_Prefect_vs_Dagster.md) | Top OSS Python orchestrators |
| [Composer vs MWAA vs Self-Hosted](02.03.06.02_Composer_vs_MWAA_vs_Self_Hosted_Airflow.md) | Managed Airflow options |
| [Step Functions vs Temporal vs Airflow](02.03.06.03_Step_Functions_vs_Temporal_vs_Airflow.md) | Durable vs batch |
| [ADF vs Airflow](02.03.06.04_ADF_vs_Airflow.md) | Azure factory vs DAGs |
| [Cloud Workflows vs Step Functions](02.03.06.05_Cloud_Workflows_vs_Step_Functions.md) | Serverless YAML/ASL |
| [Selection Framework](02.03.06.06_Orchestrator_Selection_Framework.md) | Decision scorecard |

## Related

- [Benchmarks](../02.03.05_Benchmarks/README.md)
- [Cloud Services](../02.03.02_Cloud_Services/README.md)
'@

# --- 02.03.07 Interview Questions ---
Write-Doc "02.03.07_Interview_Questions\02.03.07.01_Orchestration_Fundamentals_Questions.md" "Orchestration Fundamentals Questions" "02.03.07.01" "interview" "interview, orchestration, fundamentals" @'
# Orchestration Fundamentals - Interview Questions

## Conceptual

1. **What is data orchestration?** How does it differ from data ingestion and transformation?
2. **Orchestration vs choreography** - when would you pick each for a microservices + data pipeline estate?
3. **What belongs in the orchestrator vs the warehouse?** Thin orchestrator, fat compute - explain.
4. **Define DAG.** What makes a valid dependency graph?
5. **Time-based vs data-driven scheduling** - trade-offs and hybrid patterns?
6. **What is idempotency** in batch tasks? Why do retries require it?
7. **Explain backfill.** How do you run one without breaking prod SLAs?

## Architecture

8. Draw **control plane vs execution plane** for Airflow or any orchestrator.
9. What is **active metadata** and how does it change orchestrator behavior?
10. How does **OpenLineage** integrate with orchestration?
11. **Multi-tenant orchestration** - pools, RBAC, namespaces?
12. What is a **dead letter** pattern for failed pipeline tasks?

## Model answers

See [What Is Data Orchestration](../02.03.01_Fundamentals/02.03.01.01_Overview/02.03.01.01.01_What_Is_Data_Orchestration.md), [Orchestration vs Choreography](../02.03.01_Fundamentals/02.03.01.01_Overview/02.03.01.01.02_Orchestration_vs_Choreography.md), [Active Metadata](../02.03.01_Fundamentals/02.03.01.06_Active_Metadata/02.03.01.06.01_Active_Metadata.md).

## Related

- [Airflow Deep Dive](02.03.07.02_Airflow_Deep_Dive_Questions.md)
- [System Design Cases](02.03.07.05_System_Design_Orchestration_Cases.md)
'@

Write-Doc "02.03.07_Interview_Questions\02.03.07.02_Airflow_Deep_Dive_Questions.md" "Airflow Deep Dive Questions" "02.03.07.02" "interview" "interview, airflow" @'
# Airflow Deep Dive - Interview Questions

## Airflow internals

1. **Scheduler loop** - what happens from DAG file change to task queued?
2. Compare **executors**: Local, Celery, Kubernetes.
3. **XCom** - purpose, size limits, anti-patterns?
4. **Pools, priorities, parallelism** - how do they interact?
5. **Sensors vs deferrable operators** - why deferrable matters at scale.
6. **Airflow 2.x Datasets** - how do they replace external task sensors?
7. **Dynamic task mapping** - use case and scheduler impact?

## Operations

8. How do you **debug a stuck task** in queued state?
9. **DAG versioning** and safe deploy without killing running tasks?
10. **Secrets** - Connections vs external secret backends?
11. Common causes of **metadata DB bloat** and cleanup strategy?
12. **MWAA vs self-hosted** - what does AWS manage vs you?

## Model answers

See [Airflow Architecture](../02.03.03_Top_10/02.03.03.02_Apache_Airflow_Learning_Guide/02.03.03.02.02_Architecture.md), [Retry Strategies](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.03_Retry_Strategies.md).

## Related

- [Scheduling and Dependency Questions](02.03.07.03_Scheduling_And_Dependency_Questions.md)
'@

Write-Doc "02.03.07_Interview_Questions\02.03.07.03_Scheduling_And_Dependency_Questions.md" "Scheduling and Dependency Questions" "02.03.07.03" "interview" "interview, scheduling, dependencies" @'
# Scheduling and Dependency - Interview Questions

## Scheduling

1. **Cron vs interval vs timetable** - when is cron insufficient?
2. Explain **data interval** vs **logical date** in Airflow.
3. **Catchup** - when enabled vs disabled?
4. **SLA misses** - detection and escalation design?
5. **Cross-DAG dependencies** - ExternalTaskSensor vs datasets vs triggering API?

## Dependencies

6. **Trigger rules** (`all_success`, `none_failed`, etc.) - fan-in examples?
7. How do you model **optional branches** in a DAG?
8. **Partition-aware backfill** - upstream/downstream alignment?
9. **Circular dependency** detection in CI?
10. **Event-driven trigger** from catalog freshness - design outline?

## Scenarios

11. DAG A must finish before B and C, but B and C can run in parallel - draw it.
12. Finance close: freeze deploys, guarantee 6 AM SLA - orchestration controls?

## Model answers

See [Scheduling Patterns](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.01_Scheduling_Patterns.md), [Dependency Management](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.02_Dependency_Management.md), [SLA Management](../02.03.01_Fundamentals/02.03.01.03_Core_Concepts/02.03.01.03.04_SLA_Management.md).

## Related

- [Orchestration Fundamentals](02.03.07.01_Orchestration_Fundamentals_Questions.md)
'@

Write-Doc "02.03.07_Interview_Questions\02.03.07.04_Cloud_Orchestration_Questions.md" "Cloud Orchestration Questions" "02.03.07.04" "interview" "interview, cloud, orchestration" @'
# Cloud Orchestration - Interview Questions

## Multi-cloud concepts

1. Compare **Composer, MWAA, ADF, Step Functions, Cloud Workflows** in one sentence each.
2. When is **Glue Workflows** enough vs needing MWAA?
3. **Logic Apps** vs ADF - orchestration boundaries?
4. **Hybrid orchestration** - on-prem agents calling cloud orchestrator?
5. **IAM patterns** - least privilege for orchestrator workers?

## AWS

6. Step Functions **Standard vs Express** - latency and cost?
7. MWAA **networking** - public vs private, VPC endpoints?
8. Trigger Glue job from Step Functions vs Airflow operator?

## GCP

9. **Composer 2 vs 3** - architectural differences (high level)?
10. Cloud Workflows calling Cloud Run + BigQuery - fit?

## Azure

11. **Self-hosted integration runtime** purpose in ADF?
12. ADF trigger types vs Airflow sensors?

## Model answers

See [Cloud Orchestration Reference Architecture](../02.03.02_Cloud_Services/02.03.02.01_Overview/02.03.02.01.01_Cloud_Orchestration_Reference_Architecture.md), [Managed Workflows](../02.03.02_Cloud_Services/02.03.02.01_Overview/02.03.02.01.02_Managed_Workflows.md).

## Related

- [Comparisons](../02.03.06_Comparisons/README.md)
'@

Write-Doc "02.03.07_Interview_Questions\02.03.07.05_System_Design_Orchestration_Cases.md" "System Design Orchestration Cases" "02.03.07.05" "interview" "interview, system-design, orchestration" @'
# System Design - Orchestration Cases

## Case 1: Enterprise batch platform

**Prompt:** Design orchestration for 200 teams, 2000 DAGs, T0 finance SLAs, multi-cloud warehouses.

**Evaluate:** IDP golden path, multi-tenant RBAC, pools, CI/CD, active metadata, cost allocation tags, observability.

**Reference:** [Internal Developer Platform](../02.03.04_Architecture_Patterns/02.03.04.03_Platform_Patterns/02.03.04.03.01_Internal_Developer_Platform.md), [Enterprise Batch Reference](../02.03.09_Reference_Architectures/02.03.09.02_Enterprise_Batch_Orchestration_Reference.md).

## Case 2: Real-time + batch unified

**Prompt:** Kafka streams land in lakehouse; hourly aggregates must run after stream checkpoint. Design triggers.

**Evaluate:** Dataset triggers, stream-batch alignment, idempotent writes, late data handling.

## Case 3: Multi-cloud disaster recovery

**Prompt:** Primary orchestrator in AWS MWAA; DR in GCP Composer. RPO/RTO design.

**Evaluate:** DAG Git portability, connection secrets per region, metadata not replicated, runbook for failover.

**Reference:** [Multi-Cloud Patterns](../02.03.02_Cloud_Services/02.03.02.05_Cross_Cloud/02.03.02.05.01_Multi_Cloud_Orchestration_Patterns.md).

## Case 4: Migration from cron + bash

**Prompt:** 500 cron jobs on Linux servers. Migration strategy without big bang?

**Evaluate:** Inventory, priority tiers, wrapper DAGs, parallel run period, decommission gates.

## Case 5: Cost optimization

**Prompt:** Orchestration drives 40% redundant warehouse spend from retries and overlap.

**Evaluate:** Pool tuning, dataset scheduling, FinOps tags, benchmark framework.

**Reference:** [Cost Benchmark Framework](../02.03.05_Benchmarks/02.03.05.06_Cost_And_SLA_Benchmark_Framework.md).

## Related

- [Orchestration Fundamentals Questions](02.03.07.01_Orchestration_Fundamentals_Questions.md)
- [Architecture Patterns](../02.03.04_Architecture_Patterns/README.md)
'@

Write-Doc "02.03.07_Interview_Questions\README.md" "Interview Questions" "02.03.07" "hub" "interview, orchestration" @'
# 02.03.07 Interview Questions

**Interview prep** for data orchestration roles - fundamentals through system design.

## Question sets

| Doc | Focus |
| --- | --- |
| [Orchestration Fundamentals](02.03.07.01_Orchestration_Fundamentals_Questions.md) | Concepts, active metadata |
| [Airflow Deep Dive](02.03.07.02_Airflow_Deep_Dive_Questions.md) | Executors, XCom, ops |
| [Scheduling and Dependencies](02.03.07.03_Scheduling_And_Dependency_Questions.md) | SLAs, triggers, backfill |
| [Cloud Orchestration](02.03.07.04_Cloud_Orchestration_Questions.md) | Composer, MWAA, ADF, SF |
| [System Design Cases](02.03.07.05_System_Design_Orchestration_Cases.md) | Platform, DR, migration |

## Related

- [Fundamentals](../02.03.01_Fundamentals/README.md)
- [Comparisons](../02.03.06_Comparisons/README.md)
'@

Write-Host "02.03.06-07 done"
