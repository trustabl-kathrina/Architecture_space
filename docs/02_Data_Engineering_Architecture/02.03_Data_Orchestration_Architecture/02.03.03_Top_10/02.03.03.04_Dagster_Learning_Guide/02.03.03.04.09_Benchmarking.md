---
title: Dagster Benchmarking
section: "02.03.03.04"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dagster, open-source, assets, top-10, learning-guide, open-source]
canonical: true
---

# 9. Dagster Benchmarking

See [official documentation](https://docs.dagster.io/) and [Top 10 hub](../README.md).

Module focus: Reference load and sizing profiles
## Benchmark profiles

| Profile | Setup | Measure |
| --- | --- | --- |
| D1 | 200 assets linear graph | UI load + daemon tick latency |
| D2 | Daily partition backfill 90d | Warehouse credits vs incremental |
| D3 | Sensor every 60s on S3 prefix | Sensor evaluation CPU |
| D4 | Asset check failure cascade | Time to halt downstream materializations |

Document Dagster version, deployment type (Cloud hybrid vs OSS), and launcher (K8s job vs Celery).

## Related

- [Top 10 README](../README.md)
- [Dagster hub](../README.md)
