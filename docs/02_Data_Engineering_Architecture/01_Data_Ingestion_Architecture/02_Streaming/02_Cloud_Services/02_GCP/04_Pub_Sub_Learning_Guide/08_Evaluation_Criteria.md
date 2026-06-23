---
title: Pub/Sub Evaluation Criteria
section: "02.01"
status: complete
template: evaluation
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, pubsub, evaluation]
canonical: true
---
# 8. Pub/Sub Evaluation Criteria

Architect scorecard for comparing Google Cloud Pub/Sub against Apache Kafka, Amazon Kinesis, and Azure Event Hubs in enterprise selection.

**Rating scale:** 1 (weak) — 5 (excellent) | **Weight:** architect-adjusted per program

## Scorecard

| Criterion | Weight | Pub/Sub | Kafka (MSK) | Notes |
| --- | ---: | ---: | ---: | --- |
| **Latency** | High | 4 | 4 | Pub/Sub push/pull typically tens–hundreds of ms; Kafka comparable with tuned consumers. Sub-ms not a goal for either. |
| **Throughput** | High | 5 | 5 | Both scale to very high throughput; Kafka via partitions, Pub/Sub via managed scale + quota increases. |
| **Scalability** | High | 5 | 4 | Pub/Sub serverless elasticity; Kafka requires partition/broker planning. |
| **Fault tolerance** | High | 5 | 5 | Both multi-AZ; Google manages Pub/Sub infra; Kafka relies on replication config. |
| **Exactly-once support** | High | 4 | 3 | Pub/Sub subscription-level regional exactly-once; Kafka needs idempotent producer + transactions or app dedup. |
| **Replay capability** | Medium | 3 | 5 | Kafka offset replay is mature; Pub/Sub uses retention, seek, snapshots (31d topic max). |
| **Event-time processing** | Medium | 3 | 4 | Neither is a processor — pair with Dataflow/Flink. Kafka + Flink slightly more common in OSS patterns. |
| **Stateful processing** | Medium | 2 | 4 | Stateful work in Dataflow/Flink/Kafka Streams, not in broker. Kafka Streams colocated model scores higher. |
| **Operational complexity** | High | 5 | 2 | Pub/Sub near-zero ops; Kafka needs cluster expertise even when managed. |
| **Cloud portability** | Medium | 1 | 4 | Pub/Sub GCP-only; Kafka protocol portable across clouds. |
| **Cost** | High | 4 | 3 | Pub/Sub predictable serverless pricing; Kafka MSK has cluster hours + storage; varies by pattern. |
| **Ecosystem integration** | High | 5* | 4 | *5 on GCP (Dataflow, BQ, Run, Eventarc); Kafka wins multi-cloud OSS breadth. |

## Weighted interpretation by profile

| Enterprise profile | Lean Pub/Sub | Lean Kafka |
| --- | --- | --- |
| GCP-standard, serverless-first | **Strong fit** | Use for Kafka API needs only |
| Multi-cloud identical stack | Weak fit | **Strong fit** |
| Heavy replay / log-centric analytics | Moderate | **Strong fit** |
| Regulated GCP workload (CMEK, VPC-SC) | **Strong fit** | Good with MSK + config |
| Existing Flink on Kafka | Moderate | **Strong fit** |
| Event-driven microservices on Cloud Run | **Strong fit** | Operational overhead |

## Deep-dive per criterion

### Latency

- **Pub/Sub:** Push path optimized for serverless; measure end-to-end including handler. Batching increases publish latency trade-off.
- **Mitigation:** Low-latency batch settings; same-region deployment; min instances on Cloud Run.

### Throughput

- Pub/Sub quotas tiered by region size (up to ~4 GB/min publish in large regions default).
- Request quota uplift early for launch plans > 1 GB/s sustained.

### Exactly-once

- Enable on subscription; pair with BigQuery dedup or idempotent merge for sinks.
- Cross-region: treat as at-least-once at boundary.

### Replay

- Kafka: consumer group offsets, unlimited retention options.
- Pub/Sub: topic retention (31d), snapshots, seek — plan lake export for long history.

### Operational complexity

Pub/Sub eliminates broker patching, partition rebalancing, and ZooKeeper/KRaft operations — major TCO advantage for platform teams.

### Cost

Model fan-out explicitly. Kafka MSK charges for broker hours even at low traffic; Pub/Sub scales to zero activity cost but per-byte delivery can grow with subscribers.

## Recommendation framework

```
IF primary_cloud == GCP
   AND ops_headcount_limited
   AND replay_horizon <= 31d (or lake export OK)
   AND not kafka_protocol_mandatory
THEN Pub/Sub = default
ELSE evaluate MSK / Confluent / Event Hubs
```

## Related

- [Pub/Sub vs Kafka](../../../06_Comparisons/04_Pub_Sub_vs_Kafka.md)
- [Broker Selection Framework](../../../06_Comparisons/06_Broker_Selection_Framework.md)
- [Benchmarking](09_Benchmarking.md)
