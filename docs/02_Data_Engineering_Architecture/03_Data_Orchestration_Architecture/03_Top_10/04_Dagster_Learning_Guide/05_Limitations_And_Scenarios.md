---
title: Dagster Limitations And Scenarios
section: "02.03.03.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dagster, open-source, assets, top-10, learning-guide, open-source]
canonical: true
---

# 5. Dagster Limitations And Scenarios

See [official documentation](https://docs.dagster.io/) and [Top 10 hub](../README.md).

Module focus: Quotas, constraints, mitigations
## Trade-offs

| Limitation | Mitigation |
| --- | --- |
| Learning curve | Training on assets vs raw tasks |
| Operational footprint | Daemon + code locations + DB |
| Real-time | Pair with streaming ingest; Dagster orchestrates batch materialization |
| Non-Python steps | Wrap via ops or external asset sensors |

Less suited to pure JSON state machines (see Step Functions) or ultra-light cron glue.

## Related

- [Top 10 README](../README.md)
- [Dagster hub](../README.md)
