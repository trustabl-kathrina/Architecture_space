---
title: Orchestration Fundamentals Questions
section: "02.03.07.01"
status: complete
template: interview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [interview, orchestration, fundamentals]
canonical: true
---
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

See [What Is Data Orchestration](../01_Fundamentals/01_Overview/01_What_Is_Data_Orchestration.md), [Orchestration vs Choreography](../01_Fundamentals/01_Overview/02_Orchestration_vs_Choreography.md), [Active Metadata](../01_Fundamentals/06_Active_Metadata/01_Active_Metadata.md).

## Related

- [Airflow Deep Dive](02_Airflow_Deep_Dive_Questions.md)
- [System Design Cases](05_System_Design_Orchestration_Cases.md)