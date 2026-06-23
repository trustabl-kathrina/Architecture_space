---
title: Temporal How To Use
section: "02.03.03.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [temporal, durable-execution, open-source, top-10, learning-guide]
canonical: true
---

# 3. Temporal How To Use

See [official documentation](https://docs.temporal.io/) and [Top 10 hub](../README.md).

Module focus: Author, deploy, invoke, operate
## Implementation flow

1. Model business process as workflow functions (deterministic—no random/time without wrappers).
2. Implement activities for DB calls, HTTP, file IO.
3. Run workers scaled independently from frontends.
4. Start executions via client SDK or Temporal Cloud UI.

Use **continue-as-new** for unbounded streams; **signals/queries** for human-in-the-loop approvals.

## Related

- [Top 10 README](../README.md)
- [Temporal hub](../README.md)
