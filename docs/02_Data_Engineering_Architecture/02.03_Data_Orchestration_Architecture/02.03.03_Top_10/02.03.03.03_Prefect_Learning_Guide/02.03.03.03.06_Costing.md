---
title: Prefect Costing
section: "02.03.03.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [prefect, open-source, top-10, learning-guide]
canonical: true
---

# 6. Prefect Costing

See [official documentation](https://docs.prefect.io/) and [Top 10 hub](../README.md).

Module focus: Self-host and OSS cost models
## Pricing dimensions

Prefect Cloud bills on **successful task runs** tiers (see official pricing). Self-hosted server costs are primarily Postgres, API compute, and worker fleet—similar to self-hosted Airflow minus Celery complexity.

| Scenario | Cost tip |
| --- | --- |
| High-frequency micro-tasks | Batch inside one task to reduce run metering |
| Dev/staging | Separate workspace with lower automation |
| Hybrid | Keep workers in your VPC; no data egress through control plane |

## Related

- [Top 10 README](../README.md)
- [Prefect hub](../README.md)
