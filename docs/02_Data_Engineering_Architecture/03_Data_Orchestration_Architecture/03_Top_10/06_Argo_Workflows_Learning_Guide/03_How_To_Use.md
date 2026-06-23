---
title: Argo Workflows How To Use
section: "02.03.03.06"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [argo, kubernetes, cncf, open-source, top-10, learning-guide]
canonical: true
---

# 3. Argo Workflows How To Use

See [official documentation](https://argo-workflows.readthedocs.io/) and [Top 10 hub](../README.md).

Module focus: Author, deploy, invoke, operate
## Authoring

Install controller via Helm. Submit:

```bash
argo submit -n data-workflows my-pipeline.yaml
argo logs @latest
```

Use **WorkflowTaskSet** patterns, **withParam** for fan-out, and **retryStrategy** for transient node failures.

For Python teams, **Hera** generates typed workflow specs.

## Related

- [Top 10 README](../README.md)
- [Argo Workflows hub](../README.md)
