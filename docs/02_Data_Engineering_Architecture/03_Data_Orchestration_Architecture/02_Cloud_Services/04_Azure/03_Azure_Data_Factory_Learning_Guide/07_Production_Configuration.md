---
title: Azure Data Factory Production Configuration
section: "02.03.02.04.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [azure, adf, configuration, production]
canonical: true
---
# 7. How to Configure ADF for Production

## Configuration matrix

| Goal | Factory settings | Pipeline settings | Monitoring |
| --- | --- | --- | --- |
| **T0 SLA** | Azure IR in same region as data | Timeout + retry on copy | Metric alert FailedRuns |
| **Hybrid HA** | SHIR 2+ nodes | DIU tuned for SLA | SHIR CPU alert |
| **Regulated** | Private Link + MI | Key Vault linked services | Purview + audit logs |
| **Cost control** | Per-pipeline billing enabled | Flex/data flow off-peak | Budget on resource group |
| **CI/CD** | Git integration required | ARM/Bicep parameters | Deployment gates |

## Recipe 1 — T0 nightly ingest

```yaml
pipeline:
  timeout: 02:00:00
  retry: 2
  copy:
    parallelCopies: 4
    diu: 8
trigger:
  type: ScheduleTrigger
  schedule: "0 2 * * *"
  maxConcurrency: 1
```

Set **alert** on pipeline run failure → Action Group → Logic App or email.

## Recipe 2 — SHIR high availability

- Minimum **2 VMs** registered to same SHIR.
- Auto-update window on staggered nodes.
- Monitor **ConcurrentJobs** and CPU &gt; 75%.
- ExpressRoute/VPN stable path to Azure.

## Recipe 3 — Private Link factory

- Enable **Managed Virtual Network** + **Private Endpoints** for ADLS/Synapse.
- Use **Managed VNet IR** for isolated copy (higher pipeline activity rate applies).

## Recipe 4 — Git-based CI/CD

```
feature branch → PR → validate ARM → merge → Azure DevOps release → prod factory
```

Parameter files: `parameters.prod.json` for linked service endpoints.

## Recipe 5 — Hybrid with Logic Apps

| Layer | Tool |
| --- | --- |
| Blob event / alert | Logic Apps |
| Batch ELT | ADF pipelines |
| Approval for deploy | Logic Apps → ARM template |

## Monitoring thresholds

| Metric | Warning | Critical |
| --- | --- | --- |
| Pipeline failed runs | &gt; 0 on T0 | 2 consecutive nights |
| Copy duration p99 | &gt; 2× baseline | SLA window breach |
| SHIR CPU | &gt; 80% sustained | Job queue &gt; 30 min |
| Data flow vCore hours daily | &gt; 120% avg | Budget threshold |

## Related

- [How to Use](03_How_To_Use.md)
- [Limitations](05_Limitations_And_Scenarios.md)
