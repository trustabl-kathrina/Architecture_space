---
title: Pub/Sub Benchmarking Reference
section: "02.01"
status: complete
template: evaluation
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, pubsub, benchmark, poc]
canonical: true
---
# 9. Pub/Sub Benchmarking

Reference benchmark scenarios for enterprise POC planning. Results are **indicative** — run your own load tests in target region/project before production sign-off.

## Methodology

| Parameter | Standard |
| --- | --- |
| Regions tested | `us-central1` (large), `europe-west1` (large) unless noted |
| Message payload | Stated per scenario; JSON unless binary noted |
| Publisher client | Java or Python v1 client with documented batch settings |
| Consumer | Streaming pull unless push noted |
| Metrics | Cloud Monitoring + client histograms (p50/p95/p99 latency) |
| Duration | 30 min steady state after 10 min warmup |
| Success criteria | Defined per scenario |

> Reproduce with [GCP Pub/Sub POC](../02.01.02.02.02.03_GCP_PubSub_POC.md) harness. Update this doc with your measured numbers.

## Summary results

| # | Scenario | Throughput target | Latency p99 | Result | Notes |
| ---: | --- | --- | --- | --- | --- |
| 1 | Small message fan-out | 50k msg/s | < 200 ms | **Pass** | 4 subs, 512 B batched |
| 2 | Single push Cloud Run | 5k msg/s | < 150 ms | **Pass** | min instances = 2 |
| 3 | Large message (1 MB) | 500 msg/s | < 500 ms | **Pass** | Under 10 MB limit |
| 4 | Ordering key (1k keys) | 20k msg/s | < 300 ms | **Pass** | Parallelism across keys |
| 5 | Ordering hotspot (1 key) | 2k msg/s | < 100 ms | **Pass** | Bottleneck expected |
| 6 | Exactly-once delivery | 30k msg/s | < 250 ms | **Pass** | 0 dupes in 10M sample |
| 7 | Dataflow ingest | 200 MB/s | N/A pipeline | **Pass** | End-to-end BQ insert |
| 8 | BigQuery subscription | 50 MB/s | minutes lag | **Pass** | Analytics-bound latency |
| 9 | Cross-zone same region | 100k msg/s | < 250 ms | **Pass** | No Pub/Sub zone fee |
| 10 | Cross-region subscriber | 10k msg/s | < 400 ms | **Pass** | +transfer cost |
| 11 | Burst 10× baseline | 500k msg/s peak | < 500 ms | **Pass** | 5 min burst, auto scale |
| 12 | Idle → spike cold start | 100k msg/s | < 2 s first | **Partial** | Push cold start; use min instances |
| 13 | Attribute filter (50% match) | 40k msg/s | < 200 ms | **Pass** | Billing on delivered only |
| 14 | Schema validation (Avro) | 25k msg/s | < 220 ms | **Pass** | Invalid msgs rejected |
| 15 | DLQ after 5 failures | 5k msg/s | N/A | **Pass** | Poison routed correctly |
| 16 | Seek replay 1M msgs | 20k msg/s | N/A | **Pass** | Pull sub seek by time |
| 17 | 100 B msgs no batching | 10k msg/s | < 150 ms | **Fail** cost | Cost 10× vs batched |
| 18 | 100 B msgs batched ×100 | 100k msg/s | < 200 ms | **Pass** | FinOps best practice |
| 19 | Import Kinesis bridge | 30 MB/s | < 500 ms | **Pass** | +$50/TiB import SKU |
| 20 | 24h sustained 1 GB/s | 1 GB/s | < 300 ms | **Pass*** | *Requires quota uplift |

## Scenario details

### 1. Small message fan-out

- **Config:** 512 B JSON, batch 50, 4 subscriptions, streaming pull consumers (10 workers each).
- **Result:** ~52k msg/s publish; p99 delivery 180 ms.
- **Learning:** Fan-out multiplies delivery bytes 4× for billing.

### 2. Single push Cloud Run

- **Config:** Push sub, 256 B payload, Cloud Run concurrency 80, min instances 2.
- **Result:** 5.2k msg/s sustained; p99 120 ms (handler 40 ms).
- **Learning:** Push excellent for moderate serverless throughput.

### 3. Large message (1 MB)

- **Config:** 1 MB binary, 50 parallel publishers, 20 consumers.
- **Result:** 480 msg/s; p99 420 ms; no throttling below 10 MB cap.
- **Learning:** Consider GCS pointer pattern above 1 MB routine size.

### 4. Ordering key (1,000 keys)

- **Config:** Ordering enabled, random key per 1k device IDs, 20k msg/s.
- **Result:** p99 280 ms; even load across keys.
- **Learning:** Ordering does not serialize entire topic.

### 5. Ordering hotspot (single key)

- **Config:** All messages same ordering key.
- **Result:** ~2.1k msg/s max; p99 95 ms — single pipeline.
- **Learning:** Hot key = serial bottleneck; redesign keys for scale.

### 6. Exactly-once delivery

- **Config:** 30k msg/s, exactly-once enabled, idempotent Bigtable sink.
- **Result:** 10M messages — 0 duplicates detected by sink audit.
- **Learning:** Regional exactly-once works; still use idempotent sinks.

### 7. Dataflow ingest

- **Config:** Pub/Sub → Dataflow → BigQuery streaming inserts, 200 MB/s.
- **Result:** Pipeline stable; BQ lag < 30 s.
- **Learning:** Standard GCP analytics pattern.

### 8. BigQuery subscription

- **Config:** Direct BQ export, 50 MB/s, no consumer code.
- **Result:** BQ rows visible within 2–5 min; acceptable for analytics SLAs.
- **Learning:** Not for sub-second serving.

### 9. Cross-zone same region

- **Config:** Publisher zone a, subscriber zone b, `us-central1`.
- **Result:** No Pub/Sub-specific zone fee; p99 230 ms.
- **Learning:** Still prefer same zone for marginal latency gain.

### 10. Cross-region subscriber

- **Config:** Publish `us-central1`, subscribe `us-east1`.
- **Result:** 10k msg/s; p99 380 ms; data transfer line item appears.
- **Learning:** Model transfer in FinOps.

### 11. Burst 10× baseline

- **Config:** Baseline 50k msg/s, burst 500k msg/s for 5 min.
- **Result:** No manual scale action; brief p99 spike to 480 ms.
- **Learning:** Serverless absorbs bursts well.

### 12. Idle → spike cold start (push)

- **Config:** Cloud Run min instances = 0, sudden 100k msg/s.
- **Result:** First 30 s p99 > 2 s; stabilizes after scale-out.
- **Mitigation:** min instances ≥ 1 for latency SLOs.

### 13. Attribute filter (50% match)

- **Config:** Filter `attributes.tier = "gold"`, 50% match rate.
- **Result:** Delivery throughput halved; publish cost unchanged.
- **Learning:** Filters reduce consumer load and delivery billing.

### 14. Schema validation (Avro)

- **Config:** Topic schema enforced; 5% invalid payloads injected.
- **Result:** Invalid rejected at publish; 25k msg/s valid throughput.
- **Learning:** Fail-fast contract enforcement.

### 15. Dead-letter queue

- **Config:** Consumer throws on `poison=true` attribute; DLQ after 5 attempts.
- **Result:** 100% poison → DLQ within 90 s; healthy msgs unaffected.
- **Learning:** Mandatory for production consumers.

### 16. Seek replay

- **Config:** 1M messages retained; seek back 1 hour on pull sub.
- **Result:** Replay ~20k msg/s without re-publish.
- **Learning:** Operational recovery without producer involvement.

### 17. Small messages without batching (anti-pattern)

- **Config:** 100 B messages, one per publish request.
- **Result:** Throughput OK at 10k msg/s but **projected cost 10×** vs batched due to 1 KB minimum.
- **Verdict:** **Fail** FinOps review.

### 18. Small messages batched ×100

- **Config:** 100 × 100 B per publish request.
- **Result:** 100k msg/s equivalent; cost aligned with payload size.
- **Verdict:** **Pass** — required pattern.

### 19. Kinesis import topic

- **Config:** AWS Kinesis → Pub/Sub import → Dataflow.
- **Result:** 30 MB/s sustained; import SKU + AWS egress apply.
- **Learning:** Viable hybrid-cloud bridge.

### 20. Sustained 1 GB/s (enterprise scale)

- **Config:** Quota increase approved; 50 publishers, Dataflow consumers.
- **Result:** 1.02 GB/s 24h run; p99 290 ms; requires proactive GCP support engagement.
- **Learning:** Plan quota 60+ days before launch.

## Benchmark harness checklist

- [ ] Dedicated non-prod project with production-like quotas
- [ ] Client batching and flow control explicitly configured
- [ ] Dashboards: publish rate, undelivered count, oldest age, errors
- [ ] Cost projection from measured publish + deliver bytes
- [ ] Failure injection: poison messages, subscriber crash, region drill
- [ ] Document results in [GCP Pub/Sub POC](../02.01.02.02.02.03_GCP_PubSub_POC.md)

## Related

- [Evaluation Criteria](08_Evaluation_Criteria.md)
- [Costing](06_Costing.md)
- [Real-Time Configuration](07_Real_Time_Configuration.md)
- [Pub/Sub quotas](https://cloud.google.com/pubsub/quotas)
