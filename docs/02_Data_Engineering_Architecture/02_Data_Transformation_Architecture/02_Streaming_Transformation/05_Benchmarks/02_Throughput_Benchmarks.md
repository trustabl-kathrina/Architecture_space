---
title: Streaming Throughput_Benchmarks
section: "02.02.02.05"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [benchmark, streaming]
canonical: true
---
# Streaming Throughput_Benchmarks

## Methodology

Run in isolated cluster with synthetic load; measure p50/p99 over 24h.

## Reference profiles

| ID | Load | Metric target |
| ---: | --- | --- |
| S1 | 1K evt/s | p99 < 5s |
| S2 | 10K evt/s | p99 < 10s |
| S3 | 100K evt/s | p99 < 30s |
| S4 | Stateful join | State < 50GB |
| S5 | Recovery | RTO < 5 min |

## Related

- [Flink Learning Guide](../03_Open_Source/02_Apache_Flink_Learning_Guide/README.md)
