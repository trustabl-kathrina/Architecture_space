---
title: Prefect Limitations And Scenarios
section: "02.03.03.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [prefect, open-source, top-10, learning-guide]
canonical: true
---

# 5. Prefect Limitations And Scenarios

See [official documentation](https://docs.prefect.io/) and [Top 10 hub](../README.md).

Module focus: Quotas, constraints, mitigations
## Limitations

| Topic | Impact |
| --- | --- |
| Batch-first | Not a replacement for Kafka/Flink stream processing |
| Cloud dependency | Full UI/automation easiest with Prefect Cloud |
| Worker packaging | Same dependency sync problem as Airflow on static workers |
| Long-running human tasks | Use pause/resume patterns; compare with Temporal for saga length |

Document **vendor exit**: flows remain plain Python; migrate server to self-hosted Postgres if leaving Cloud.

## Related

- [Top 10 README](../README.md)
- [Prefect hub](../README.md)
