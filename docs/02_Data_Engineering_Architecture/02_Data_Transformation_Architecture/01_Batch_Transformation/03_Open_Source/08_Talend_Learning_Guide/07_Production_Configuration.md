---
title: Talend Production Configuration
section: "02.02.01.03.08"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [batch transformation, learning-guide]
canonical: true
---
# 7. Talend Production Configuration

## High availability

- Multi-AZ workers and broker replication.
- Checkpoint to durable object storage with versioning.
- RTO target: < 15 min via automated redeploy.

## Security checklist

| Control | Implementation |
| --- | --- |
| Encryption at rest | KMS / CMEK on storage |
| Encryption in transit | TLS on all endpoints |
| IAM | Least privilege per job SA |
| Secrets | Vault / Secrets Manager |
| Network | Private endpoints, no public IPs |
| Audit | CloudTrail / Activity Log |

## Monitoring

| Metric | Alert threshold |
| --- | --- |
| Job failure | Any failure in prod |
| Freshness lag | > 2Ã- SLA |
| Error rate | > 0.1% records |
| Duration | > p99 baseline |

## SLA template

`
Availability: 99.9% monthly
Freshness: ___ minutes p99
Recovery: ___ minutes RTO
`

## Related

- [Learning guide README](README.md)
