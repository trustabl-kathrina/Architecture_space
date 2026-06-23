---
title: Prefect Scenarios
section: "02.03.03.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [prefect, open-source, top-10, learning-guide]
canonical: true
---

# 4. Prefect Scenarios

See [official documentation](https://docs.prefect.io/) and [Top 10 hub](../README.md).

Module focus: Enterprise pipeline patterns
## Enterprise scenarios

| Scenario | Prefect approach |
| --- | --- |
| Parametric replays | Deployment parameters + manual custom runs |
| Per-tenant isolation | Separate work pools and IAM roles per tenant |
| Event-driven | Webhooks and automations on block events |
| dbt orchestration | `prefect-dbt` or shell tasks with artifacts |
| ML training | Map over hyperparameter grid with task runners |
| File landing | S3/GCS automation triggers deployment |

Combine with **Concurrency limits** on work pools to protect downstream warehouses.

## Related

- [Top 10 README](../README.md)
- [Prefect hub](../README.md)
