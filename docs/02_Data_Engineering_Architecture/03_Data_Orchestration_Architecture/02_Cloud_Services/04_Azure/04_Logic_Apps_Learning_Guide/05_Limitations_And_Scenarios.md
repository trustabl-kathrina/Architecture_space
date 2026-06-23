---
title: Azure Logic Apps Limitations and Mitigations
section: "02.03.02.04.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [azure, logic-apps, limitations]
canonical: true
---
# 5. Limitations and Mitigation Scenarios

## Platform limits (summary)

Source: [Logic Apps limits](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-limits-and-config).

| Limit | Typical impact | Mitigation |
| --- | --- | --- |
| **Run duration (Consumption)** | Long workflows timeout | Standard plan or Durable Functions |
| **Action payload size** | Large files fail | ADF copy; Blob reference URL |
| **Connector throttling** | 429 errors | Exponential retry; Service Bus buffer |
| **Consumption cold start** | Latency spikes | Standard dedicated plan |
| **Loop iteration limits** | Large foreach capped | ADF ForEach for bulk |
| **Enterprise connector cost** | Budget overrun | Built-in HTTP + managed identity |
| **Run history storage** | Compliance / cost | Configure retention account |

## Limitation → mitigation

| Limitation | Scenario | Mitigation |
| --- | --- | --- |
| Not for bulk ETL | 1 TB daily copy | **ADF** copy activity |
| Limited data lineage | Regulatory audit | **Purview** on ADF outputs |
| Designer merge pain | Large teams | JSON in Git; VS Code extension |
| VNet on Consumption | Private API | **Standard** plan in VNet |

## When not to use Logic Apps

| Situation | Better fit |
| --- | --- |
| Nightly medallion ELT | **ADF / Fabric** |
| Complex DAG backfill | **ADF** tumbling window or Airflow |
| AWS estate | **Step Functions** |
| Code-first portable YAML | **Cloud Workflows** (GCP) |

## Risk scenarios

### Connector auth expiry

**Symptom:** Silent failures after 90 days.  
**Mitigation:** Managed identity; Key Vault rotation alerts.

### Runaway Consumption billing

**Symptom:** Recurrence too frequent.  
**Mitigation:** Budget alerts; review action count per run.

### PII in run history

**Symptom:** Compliance violation.  
**Mitigation:** Redact outputs; restrict Log Analytics access.

## Related

- [Evaluation Criteria](08_Evaluation_Criteria.md)
- [Costing](06_Costing.md)
