---
title: Argo Workflows Production Configuration
section: "02.03.03.06"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [argo, kubernetes, cncf, open-source, top-10, learning-guide]
canonical: true
---

# 7. Argo Workflows Production Configuration

See [official documentation](https://argo-workflows.readthedocs.io/) and [Top 10 hub](../README.md).

Module focus: HA, security, monitoring recipes
## Production

RBAC for workflow SA; artifact repository credentials via K8s secrets; archive logs to S3; set **podGC** strategy; monitor controller metrics and workflow failure rates per namespace.

## Related

- [Top 10 README](../README.md)
- [Argo Workflows hub](../README.md)
