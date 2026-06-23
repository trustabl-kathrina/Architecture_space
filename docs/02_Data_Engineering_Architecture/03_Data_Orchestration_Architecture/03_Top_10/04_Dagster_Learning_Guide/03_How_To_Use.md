---
title: Dagster How To Use
section: "02.03.03.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dagster, open-source, assets, top-10, learning-guide, open-source]
canonical: true
---

# 3. Dagster How To Use

See [official documentation](https://docs.dagster.io/) and [Top 10 hub](../README.md).

Module focus: Author, deploy, invoke, operate
## Project layout

Use `dagster project scaffold` (or uv/poetry). Definitions live in Python modules loaded by `Definitions` object merging assets, jobs, schedules, sensors, resources.

Local dev:

```bash
dagster dev
```

Deploy code locations via Helm, Docker, or Dagster Cloud **branch deployments** for PR previews.

## Testing

`materialize` assets in pytest with mock resources; validate **asset checks** for data quality gates before promoting jobs.

## Related

- [Top 10 README](../README.md)
- [Dagster hub](../README.md)
