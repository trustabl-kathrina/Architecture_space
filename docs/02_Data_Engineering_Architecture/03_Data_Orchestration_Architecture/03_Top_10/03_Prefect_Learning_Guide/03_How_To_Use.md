---
title: Prefect How To Use
section: "02.03.03.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [prefect, open-source, top-10, learning-guide]
canonical: true
---

# 3. Prefect How To Use

See [official documentation](https://docs.prefect.io/) and [Top 10 hub](../README.md).

Module focus: Author, deploy, invoke, operate
## Quick start

```bash
pip install -U prefect
prefect cloud login   # or prefect server start
```

Define:

```python
from prefect import flow, task

@task(retries=3, retry_delay_seconds=30)
def extract(): ...

@flow(log_prints=True)
def elt_pipeline():
    extract()
```

Deploy with `prefect deploy` (YAML) or `flow.deploy()` specifying work pool and schedule.

## Best practices

- Use **Secret blocks** instead of env files in repo
- Tag runs (`environment=prod`, `domain=finance`) for cost allocation
- Enable **automation** rules for SLA failures → Slack/PagerDuty

## Related

- [Top 10 README](../README.md)
- [Prefect hub](../README.md)
