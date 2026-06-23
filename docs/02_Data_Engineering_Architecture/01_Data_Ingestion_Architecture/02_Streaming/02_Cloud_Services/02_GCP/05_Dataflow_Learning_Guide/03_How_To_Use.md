---
title: How to Use Dataflow
section: "02.01"
status: complete
template: concept
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, dataflow, operations]
canonical: true
---
# 3. How to Use Dataflow

## Setup prerequisites

1. Enable `dataflow.googleapis.com`, `compute.googleapis.com`, `storage.googleapis.com`.
2. Create GCS staging/temp bucket: `gs://PROJECT-dataflow-staging`.
3. Create worker service account with least-privilege roles.
4. Install Apache Beam SDK: `pip install apache-beam[gcp]` (Python) or Maven (Java).

## Minimal streaming pipeline (Python)

```python
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

options = PipelineOptions(
    streaming=True,
    project="PROJECT_ID",
    region="us-central1",
    temp_location="gs://PROJECT-dataflow-staging/temp",
    staging_location="gs://PROJECT-dataflow-staging/staging",
    max_num_workers=10,
    enable_streaming_engine=True,
)

with beam.Pipeline(options=options) as p:
    (p
     | "ReadPubSub" >> beam.io.ReadFromPubSub(
           subscription="projects/PROJECT/subscriptions/events-processor")
     | "Parse" >> beam.Map(lambda b: b.decode("utf-8"))
     | "Window" >> beam.WindowInto(beam.window.FixedWindows(60))
     | "Count" >> beam.combiners.Count.PerKey()
     | "WriteBQ" >> beam.io.WriteToBigQuery(
           "PROJECT:dataset.table",
           write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND))
```

## Submit job

```bash
python pipeline.py \
  --runner DataflowRunner \
  --job_name events-aggregator-prod \
  --service_account_email dataflow-worker@PROJECT.iam.gserviceaccount.com
```

## Essential pipeline options

| Option | Batch | Streaming | Notes |
| --- | --- | --- | --- |
| `streaming` | `False` | `True` | Required for unbounded sources |
| `enable_streaming_engine` | — | `True` | Production default |
| `max_num_workers` | ✓ | ✓ | Cost cap |
| `autoscaling_algorithm` | `NONE` or throughput | `THROUGHPUT_BASED` | |
| `worker_machine_type` | ✓ | ✓ | Right-size for CPU vs memory |
| `experiments` | FlexRS flag for batch | resource-based billing | See costing module |
| `streaming_mode_at_least_once` | — | Optional | Cost reduction |

## Java pipeline (structure)

```java
PipelineOptions options = PipelineOptionsFactory.fromArgs(args).create();
options.as(StreamingOptions.class).setStreaming(true);
options.as(DataflowPipelineOptions.class).setEnableStreamingEngine(true);

Pipeline p = Pipeline.create(options);
p.apply("Read", PubsubIO.readStrings().fromSubscription(SUBSCRIPTION))
 .apply("Process", ParDo.of(new MyFn()))
 .apply("Write", BigQueryIO.writeTableRows().to(TABLE).withCreateDisposition(CREATE_IF_NEEDED));

p.run();
```

## Dataflow templates

| Type | Use |
| --- | --- |
| **Classic templates** | Pre-built parameterized pipelines (Pub/Sub to GCS, etc.) |
| **Flex Templates** | Containerized pipeline; `gcloud dataflow flex-template run` |

Templates enable self-service ingestion with guardrails — platform team owns container image and IAM.

## Terraform deployment

```hcl
resource "google_dataflow_flex_template_job" "pubsub_to_bq" {
  provider               = google-beta
  name                   = "pubsub-to-bq-prod"
  container_spec_gcs_path = "gs://templates/pubsub-to-bq.json"
  region                 = "us-central1"

  parameters = {
    inputSubscription = "projects/PROJECT/subscriptions/events"
    outputTable       = "PROJECT:dataset.events"
  }

  service_account_email = google_service_account.dataflow.email
}
```

## Monitoring

- **Dataflow UI** — job graph, step metrics, autoscaling timeline
- **Cloud Monitoring** — `dataflow.googleapis.com/job/system_lag`, `element_count`, `watermark_age`
- **Alerts** — system lag > SLO, error rate, worker count at max

## Update and drain streaming jobs

```bash
# Graceful update (compatible pipeline change)
gcloud dataflow jobs update JOB_ID --region=us-central1 ...

# Drain before breaking change
gcloud dataflow jobs drain JOB_ID --region=us-central1
```

## Operational checklist

- [ ] Streaming Engine enabled
- [ ] Resource-based billing evaluated
- [ ] `maxNumWorkers` set for FinOps cap
- [ ] Worker SA least privilege verified
- [ ] Staging bucket lifecycle policy configured
- [ ] Exactly-once vs at-least-once consciously chosen
- [ ] Dead-letter pattern for malformed records
- [ ] Job labels for cost allocation (`domain`, `env`, `cost-center`)

## Related

- [Architecture](02_Architecture.md)
- [Real-Time Configuration](07_Real_Time_Configuration.md)
- [Beam programming guide](https://beam.apache.org/documentation/programming-guide/)
