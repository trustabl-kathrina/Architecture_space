---
title: Argo Workflows Architecture
section: "02.03.03.06"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [argo, kubernetes, cncf, open-source, top-10, learning-guide]
canonical: true
---
# 2. Architecture of Argo Workflows

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Workflow controller, CRD reconciliation, artifact GC |
| **Execution plane** | Kubernetes pods (steps) and init/wait sidecars |

## Core components

| Component | Function |
| --- | --- |
| **Workflow CRD** | Declarative DAG of templates and steps |
| **Workflow controller** | Schedules pods, tracks phase, handles retries |
| **Artifact repository** | S3, GCS, MinIO, or Artifactory for step I/O |
| **Executor** | Runs main container; supports emissary/docker patterns |

Workflows compose **templates** (container, script, resource, suspend) into DAGs or steps. Each task is a pod — ideal when compute already lives on Kubernetes (Spark operator, Kubeflow, custom ETL images).

## Design principle

**Kubernetes-native** — no separate worker fleet; scale via cluster autoscaling and pod parallelism limits.

## Control plane

| Object | Purpose |
| --- | --- |
| **Workflow** | Template + entrypoint |
| **WorkflowTemplate** | Reusable definition |
| **CronWorkflow** | Scheduled runs |
| **Controller** | Reconciles workflow CRDs |
| **Executor** | Docker/container runtime in pod |

Integrates with **Argo Events** for event triggers and **Argo CD** for GitOps delivery of templates.

## Related

- [Orchestration Reference Model](../../01_Fundamentals/01_Overview/03_Orchestration_Reference_Model.md)
- [Top 10 README](../README.md)
