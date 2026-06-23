---
title: Platform Governance
section: "02.03.01.04"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [orchestration, platform, governance, idp]
canonical: true
---
# Platform Governance (Orchestration Context)

**Platform governance** extends orchestration governance to the **shared data platform**: standards for how domains use the orchestrator, internal developer platform (IDP) guardrails, cost accountability, and cross-domain interoperability. It answers: *how do hundreds of teams use one orchestration plane without chaos?*

## Platform vs domain responsibilities

| Layer | Platform owns | Domain owns |
| --- | --- | --- |
| **Runtime** | Orchestrator HA, upgrades, executors, pools | — |
| **Standards** | DAG templates, CI policies, operator allowlist | Business logic in tasks |
| **Self-service** | Golden paths, cookiecutter, docs | DAG repos within guardrails |
| **Cost** | Chargeback model, quotas, FinOps dashboards | Right-sizing task resources |
| **Incidents** | Platform P1 (scheduler down) | Domain P1 (DAG logic failure) |

## Golden paths

Pre-approved patterns reduce variance and review burden:

| Golden path | Includes |
| --- | --- |
| **Daily warehouse load** | Extract operator → quality check → dbt trigger template |
| **S3 landing → Spark** | Partition sensor → EMR/Dataproc submit → catalog register |
| **Cross-domain consumer** | Dataset-triggered DAG stub with SLA tags |
| **ML batch scoring** | Feature check → batch predict → monitor drift hook |

Domains fork templates; platform reviews only deviations (custom operators, new connections).

## Policy enforcement

| Policy | Enforcement point |
| --- | --- |
| Required metadata tags | CI linter |
| Approved operator list | Import guard in CI |
| Max task runtime | Platform default + override approval |
| Prod connection allowlist | Orchestrator RBAC |
| Schedule window (no peak hours) | CI or policy engine |
| OpenLineage emission | Required plugin on prod deploy |

## Multi-tenant isolation

| Model | Isolation | Governance note |
| --- | --- | --- |
| **Single cluster, RBAC** | DAG + connection permissions | Simplest; blast radius shared |
| **Namespace per domain** | K8s namespace + Airflow RBAC | Common enterprise pattern |
| **Federated orchestrators** | Separate instances | Central standards via shared CI library |

Define **noisy neighbor** limits: pools per domain, max concurrent DAG runs, warehouse slot caps.

## Cost governance

- **Tag runs** with `domain`, `cost_center`, `dag_id`.
- **Report** compute + orchestrator worker cost per domain monthly.
- **Quota** expensive backfills (e.g., > 30 days requires platform approval).
- **Optimize** schedules off-peak; use deferrable sensors to reduce worker hours.

Link to platform FinOps practices in cloud billing exports.

## IDP integration

Internal developer portal surfaces:

- Request new DAG repo from template
- View domain SLA scorecard
- Lookup dataset freshness and upstream DAG
- Request prod connection (workflow approval)

Orchestration metadata feeds the catalog; governance ensures **portal data matches prod truth**.

## Compliance and data residency

- **Data residency** — Tasks run in approved regions; connections geo-tagged.
- **PII pipelines** — Mandatory masking tasks; restricted log access.
- **SOX / SOC** — Segregation of duties: author ≠ sole prod deployer for T0 DAGs.

## Maturity indicators

| Level | Platform governance behavior |
| --- | --- |
| **1 — Ad hoc** | Verbal standards; UI edits in prod |
| **2 — Defined** | Written standards; Git for prod DAGs |
| **3 — Enforced** | CI policy; RBAC; chargeback |
| **4 — Optimized** | Self-service golden paths; automated SLA and cost optimization |

## Related

- [Orchestration Governance](01_Orchestration_Governance.md)
- [Internal Developer Platform](../../04_Architecture_Patterns/03_Platform_Patterns/01_Internal_Developer_Platform.md)
- [Self Service Platform](../../08_Integration_Patterns/01_Self_Service_Platform.md)
- [Enterprise DataOps Playbook](../05_DataOps/03_Enterprise_DataOps_Playbook.md)
