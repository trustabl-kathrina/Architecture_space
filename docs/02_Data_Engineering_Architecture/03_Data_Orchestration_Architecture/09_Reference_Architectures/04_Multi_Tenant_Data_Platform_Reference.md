---
title: Multi-Tenant Data Platform Reference Architecture
section: "02.03.09.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [reference-architecture, multi-tenant, platform]
canonical: true
---
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

- [Self-Service Platform](../08_Integration_Patterns/01_Self_Service_Platform.md)
- [Internal Developer Platform](../04_Architecture_Patterns/03_Platform_Patterns/01_Internal_Developer_Platform.md)