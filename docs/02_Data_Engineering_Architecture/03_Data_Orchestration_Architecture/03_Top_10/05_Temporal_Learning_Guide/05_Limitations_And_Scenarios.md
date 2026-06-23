---
title: Temporal Limitations And Scenarios
section: "02.03.03.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [temporal, durable-execution, open-source, top-10, learning-guide]
canonical: true
---

# 5. Temporal Limitations And Scenarios

See [official documentation](https://docs.temporal.io/) and [Top 10 hub](../README.md).

Module focus: Quotas, constraints, mitigations
## Constraints

Workflow code must be **deterministic** (restricted APIs). High fan-out history grows event store—use child workflows judiciously. Operational expertise for self-hosted clusters is non-trivial; Cloud reduces burden.

## Related

- [Top 10 README](../README.md)
- [Temporal hub](../README.md)
