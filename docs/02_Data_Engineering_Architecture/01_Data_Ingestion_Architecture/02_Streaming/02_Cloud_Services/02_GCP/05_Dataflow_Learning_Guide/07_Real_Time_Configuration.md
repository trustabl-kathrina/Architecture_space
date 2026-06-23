---
title: Dataflow Real-Time Configuration
section: "02.01"
status: complete
template: concept
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, dataflow, configuration, real-time]
canonical: true
---
# 7. How to Configure Dataflow for Real-Time Scenarios

## Configuration matrix

| Goal | Pipeline options | Beam patterns |
| --- | --- | --- |
| Low latency (< 30 s E2E) | Small windows, low `maxNumWorkers` floor ≥ 2 | Fixed 10–30 s windows |
| High throughput | `THROUGHPUT_BASED` autoscale, high `maxNumWorkers` | Fusion-friendly maps |
| Exactly-once | Default streaming mode | Idempotent BQ keys |
| Cost control | At-least-once, CUD, `maxNumWorkers` | Combine before shuffle |
| Late data | `allowedLateness` + triggers | Event-time timestamps |
| Resilience | DLQ Pub/Sub topic | `Try`/`Except` pattern |

## Recipe 1 — Low-latency Pub/Sub → BigQuery

**Target:** p99 end-to-end < 60 s (ingest to queryable row).

```python
PipelineOptions(
    streaming=True,
    enable_streaming_engine=True,
    max_num_workers=20,
    num_workers=2,
    worker_machine_type="n4-standard-2",
    experiments=["enable_streaming_engine_resource_based_billing"],
)
# Beam: FixedWindows(30), AfterWatermark trigger, WRITE_APPEND to partitioned BQ
```

- Co-locate Dataflow, Pub/Sub, BigQuery in **same region**.
- Pre-create BQ table with **partitioning** on `event_timestamp`.
- Monitor `dataflow.googleapis.com/job/system_lag`.

## Recipe 2 — High-throughput telemetry (100k+ msg/s)

```python
PipelineOptions(
    streaming=True,
    enable_streaming_engine=True,
    autoscaling_algorithm="THROUGHPUT_BASED",
    max_num_workers=100,
    num_workers=10,
    worker_machine_type="n4-highmem-4",
)
```

- Increase Pub/Sub subscription throughput (batch publish upstream).
- Use **Java** pipeline for parsing hot path if Python bottlenecks.
- Salt hot keys before `GroupByKey`.

## Recipe 3 — Stateful sessionization

```python
beam.WindowInto(
    beam.window.Sessions(gap_size=30 * 60),  # 30-min gap
    trigger=AfterWatermark(),
    accumulation_mode=ACCUMULATING,
    allowed_lateness=Duration(minutes=5),
)
```

- Assign **event-time** timestamps from payload, not processing time.
- Enable Streaming Engine for state backend.
- See [Event Time vs Processing Time](../../../01_Fundamentals/03_Core_Concepts/02_Event_Time_vs_Processing_Time.md).

## Recipe 4 — Side-input dimension join

```python
main | beam.Map(enrich_with_dim)  # async lookup to Spanner/BQ
# OR periodic side input refresh every 15 min for small dims
```

- Avoid broadcast of tables > 100 MB.
- Use **AsSingleton** side input refresh for reference data.

## Recipe 5 — Exactly-once billing pipeline

```python
# Do NOT set streaming_mode_at_least_once
beam.io.WriteToBigQuery(
    table, method=FILE_LOADS,  # or STREAMING_INSERTS with dedup keys
    insert_retry_strategy=RETRY_ON_TRANSIENT_ERROR,
)
```

- Use deterministic `insertId` or merge on primary key in downstream BQ scheduled merge.
- Pair with [Exactly Once Semantics](../../../01_Fundamentals/03_Core_Concepts/03_Exactly_Once_Semantics.md).

## Recipe 6 — Cost-optimized metrics (at-least-once)

```python
PipelineOptions(
    experiments=[
        "enable_streaming_engine_resource_based_billing",
        "enable_streaming_at_least_once",
    ],
)
```

- Accept duplicate counters in downstream; use approximate aggregates where OK.

## Recipe 7 — Batch backfill after schema change

```bash
python backfill_pipeline.py \
  --runner DataflowRunner \
  --experiments=enable_flexrs \
  --max_num_workers=50 \
  --region=us-central1
```

- Read historical GCS Avro; write to new BQ table version.
- Run parallel to streaming job during cutover.

## Recipe 8 — Private VPC data plane

```python
PipelineOptions(
    use_public_ips=False,
    subnetwork="regions/us-central1/subnetworks/dataflow-private",
)
```

- Enable Private Google Access on subnet.
- Configure firewall for worker ↔ Google APIs.

## Monitoring thresholds

| Metric | Warning | Critical |
| --- | --- | --- |
| `System lag` | > 60 s | > 300 s |
| `Watermark age` | > window size + lateness | 2× threshold |
| `Elapsed time at max workers` | > 30 min sustained | > 2 hr |
| Error elements rate | > 0.01% | > 0.1% |

## Related

- [How to Use](03_How_To_Use.md)
- [Costing](06_Costing.md)
- [Pub/Sub Real-Time Configuration](../04_Pub_Sub_Learning_Guide/07_Real_Time_Configuration.md)
