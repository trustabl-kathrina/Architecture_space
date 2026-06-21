# Fill missing 02.02 Data Transformation Architecture content
# Phases: structure fix, subsection READMEs, NRT/streaming/batch/shared content, learning guide enhancement
$ErrorActionPreference = "Stop"
$Repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$Base = Join-Path $Repo "docs\02_Data_Engineering_Architecture\02.02_Data_Transformation_Architecture"
$Today = "2026-06-20"
$utf8 = New-Object System.Text.UTF8Encoding $false
$Stats = @{ Created = 0; Updated = 0; Errors = [System.Collections.ArrayList]@() }

function Get-FM($title, $section, $template, $tags) {
    return @"
---
title: $title
section: "$section"
status: complete
template: $template
last_reviewed: $Today
owner: architecture-team
tags: [$tags]
canonical: true
---

"@
}

function Get-LongPath($path) {
    $full = [IO.Path]::GetFullPath($path)
    if ($full.StartsWith('\\?\')) { return $full }
    if ($full.StartsWith('\\')) { return "\\?\UNC$($full.Substring(1))" }
    return "\\?\$full"
}

function Strip-LongPath([string]$path) {
    if ($path.StartsWith('\\?\UNC')) { return '\\' + $path.Substring(8) }
    if ($path.StartsWith('\\?\')) { return $path.Substring(4) }
    return $path
}

function Ensure-Directory($path) {
    $full = [IO.Path]::GetFullPath($path)
    $long = Get-LongPath $full
    if ([IO.Directory]::Exists($long)) { return }
    $parent = Split-Path $full -Parent
    if ($parent -and $parent -ne $full) { Ensure-Directory $parent }
    [void][IO.Directory]::CreateDirectory($long)
}

function Write-Doc($fullPath, $content) {
    $fullPath = [IO.Path]::GetFullPath($fullPath)
    Ensure-Directory (Split-Path $fullPath -Parent)
    $exists = Test-Path (Get-LongPath $fullPath)
    $text = $content.TrimEnd() + "`n"
    [IO.File]::WriteAllText((Get-LongPath $fullPath), $text, $utf8)
    if ($exists) { $script:Stats.Updated++ } else { $script:Stats.Created++ }
}

function ND($relPath, $title, $section, $template, $tags, $body) {
    Write-Doc (Join-Path $Base $relPath) ((Get-FM $title $section $template $tags) + $body)
}

function Remove-EmptyDir($path) {
    if (-not (Test-Path $path)) { return }
    $items = Get-ChildItem $path -Force -ErrorAction SilentlyContinue
    if ($items.Count -eq 0) {
        Remove-Item (Get-LongPath $path) -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  removed empty: $(Split-Path $path -Leaf)"
    }
}

function Move-RenameFolder($src, $dst) {
    if (-not (Test-Path $src)) { return }
    if (Test-Path $dst) {
        Get-ChildItem $src -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $target = Join-Path $dst $_.Name
            if (-not (Test-Path $target)) {
                Move-Item (Get-LongPath $_.FullName) (Get-LongPath $target) -Force
            }
        }
        Remove-EmptyDir $src
        return
    }
    Ensure-Directory (Split-Path $dst -Parent)
    Move-Item (Get-LongPath $src) (Get-LongPath $dst) -Force
    Write-Host "  renamed: $(Split-Path $src -Leaf) -> $(Split-Path $dst -Leaf)"
}

# ========== Phase 1: Fix structure ==========
Write-Host "Phase 1: Fix structure"
$GhostFolders = @(
    "02.02.01_Batch_Transformation\02.02.01.01_01_Fundamentals"
    "02.02.01_Batch_Transformation\02.02.01.02_02_Cloud_Services"
    "02.02.04_Shared_Foundations\02.02.04.01_01_Fundamentals"
    "02.02.04_Shared_Foundations\02.02.04.02_02_Cloud_Services"
    "02.02.04_Shared_Foundations\02.02.04.04_04_Architecture_Patterns"
)
foreach ($g in $GhostFolders) { Remove-EmptyDir (Join-Path $Base $g) }

$Renames = @(
    @("02.02.01_Batch_Transformation\02.02.01.07_07_Interview_Questions", "02.02.01_Batch_Transformation\02.02.01.07_Interview_Questions")
    @("02.02.02_Streaming_Transformation\02.02.02.05_05_Benchmarks", "02.02.02_Streaming_Transformation\02.02.02.05_Benchmarks")
    @("02.02.02_Streaming_Transformation\02.02.02.06_06_Comparisons", "02.02.02_Streaming_Transformation\02.02.02.06_Comparisons")
    @("02.02.02_Streaming_Transformation\02.02.02.07_07_Interview_Questions", "02.02.02_Streaming_Transformation\02.02.02.07_Interview_Questions")
    @("02.02.02_Streaming_Transformation\02.02.02.08_08_Integration_Patterns", "02.02.02_Streaming_Transformation\02.02.02.08_Integration_Patterns")
    @("02.02.02_Streaming_Transformation\02.02.02.09_09_Reference_Architectures", "02.02.02_Streaming_Transformation\02.02.02.09_Reference_Architectures")
    @("02.02.03_Near_Real_Time_Transformation\02.02.03.05_05_Benchmarks", "02.02.03_Near_Real_Time_Transformation\02.02.03.05_Benchmarks")
    @("02.02.03_Near_Real_Time_Transformation\02.02.03.06_06_Comparisons", "02.02.03_Near_Real_Time_Transformation\02.02.03.06_Comparisons")
    @("02.02.03_Near_Real_Time_Transformation\02.02.03.07_07_Interview_Questions", "02.02.03_Near_Real_Time_Transformation\02.02.03.07_Interview_Questions")
    @("02.02.03_Near_Real_Time_Transformation\02.02.03.08_08_Integration_Patterns", "02.02.03_Near_Real_Time_Transformation\02.02.03.08_Integration_Patterns")
    @("02.02.03_Near_Real_Time_Transformation\02.02.03.09_09_Reference_Architectures", "02.02.03_Near_Real_Time_Transformation\02.02.03.09_Reference_Architectures")
    @("02.02.04_Shared_Foundations\02.02.04.09_09_Reference_Architectures", "02.02.04_Shared_Foundations\02.02.04.09_Reference_Architectures")
)
foreach ($r in $Renames) { Move-RenameFolder (Join-Path $Base $r[0]) (Join-Path $Base $r[1]) }

# Remove any remaining double-number malformed folders (e.g. 02.02.02.05_05_Benchmarks)
Get-ChildItem $Base -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '\.\d{2}_\d{2}_'
} | ForEach-Object {
    $fixedName = $_.Name -replace '\.(\d{2})_\1_', '.$1_'
    if ($fixedName -eq $_.Name) { return }
    $bad = $_.FullName
    $fixed = Join-Path (Split-Path $bad -Parent) $fixedName
    Move-RenameFolder $bad $fixed
    Remove-EmptyDir $bad
    if (Test-Path $bad) {
        Remove-Item (Get-LongPath $bad) -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  force-removed malformed: $($_.Name)"
    }
}

Ensure-Directory (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.09_Reference_Architectures")
Ensure-Directory (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.07_Interview_Questions")

# ========== Phase 2: Subsection READMEs ==========
Write-Host "Phase 2: Subsection READMEs"

$SubSlots = @(
    @{ Num = "01"; Name = "Fundamentals"; Desc = "core concepts, patterns, and processing models" }
    @{ Num = "02"; Name = "Cloud_Services"; Desc = "managed cloud transformation services and learning guides" }
    @{ Num = "03"; Name = "Open_Source"; Desc = "top 10 open-source and market-leading transformation engines" }
    @{ Num = "04"; Name = "Architecture_Patterns"; Desc = "ETL/ELT, medallion, quality, and reference patterns" }
    @{ Num = "05"; Name = "Benchmarks"; Desc = "latency, throughput, and performance tuning profiles" }
    @{ Num = "06"; Name = "Comparisons"; Desc = "technology and pattern comparison matrices" }
    @{ Num = "07"; Name = "Interview_Questions"; Desc = "fundamentals, deep dives, and system design prep" }
    @{ Num = "08"; Name = "Integration_Patterns"; Desc = "orchestration, catalog, quality gates, observability" }
    @{ Num = "09"; Name = "Reference_Architectures"; Desc = "enterprise platform and lakehouse reference designs" }
)

$ModeMeta = @(
    @{ Id = "02.02.01"; Folder = "02.02.01_Batch_Transformation"; Title = "Batch Transformation"; Tags = "batch, etl, elt" }
    @{ Id = "02.02.02"; Folder = "02.02.02_Streaming_Transformation"; Title = "Streaming Transformation"; Tags = "streaming, flink, spark-streaming" }
    @{ Id = "02.02.03"; Folder = "02.02.03_Near_Real_Time_Transformation"; Title = "Near Real Time Transformation"; Tags = "micro-batch, nrt, trigger" }
    @{ Id = "02.02.04"; Folder = "02.02.04_Shared_Foundations"; Title = "Shared Foundations"; Tags = "transformation, medallion, scd" }
)

foreach ($mode in $ModeMeta) {
    foreach ($slot in $SubSlots) {
        if ($mode.Id -eq "02.02.04" -and $slot.Num -in @("03", "05", "06", "07", "08")) { continue }
        if ($mode.Id -eq "02.02.03" -and $slot.Num -eq "03") { continue }
        $secId = "$($mode.Id).$($slot.Num)"
        $folderName = "$secId`_$($slot.Name)"
        $folderPath = Join-Path $Base "$($mode.Folder)\$folderName"
        if (-not (Test-Path $folderPath)) { Ensure-Directory $folderPath }
        $label = $slot.Name.Replace("_", " ")
        $readmeBody = @"
# $label

Subsection index for $($mode.Id) $($mode.Title) — $($slot.Desc).

## Section ID

``$secId``

## Contents

Browse topic files and learning guides under ``$folderName/``.

## Related

- [$($mode.Id) $($mode.Title)](../README.md)
- [02.02 Transformation Architecture](../../README.md)
"@
        ND "$($mode.Folder)\$folderName\README.md" "$label README" $secId "overview" "$($mode.Tags), $($slot.Name.ToLower())" $readmeBody
    }
}

Write-Host "Phase 2 complete."

# ========== Phase 3: Fill 02.02.03 Near-Real-Time ==========
Write-Host "Phase 3: Fill NRT mode (02.02.03)"
$NRT = "02.02.03_Near_Real_Time_Transformation"

Ensure-Directory (Join-Path $Base "$NRT\02.02.03.01_Fundamentals\02.02.03.01.01_Strategy")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.01_Fundamentals\02.02.03.01.02_Micro_Batch_Patterns")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.01_Overview")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.02_GCP")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.03_AWS")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.04_Azure")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.04_Architecture_Patterns\02.02.03.04.01_Micro_Batch")
Ensure-Directory (Join-Path $Base "$NRT\02.02.03.04_Architecture_Patterns\02.02.03.04.02_Reference_Architectures")

ND "$NRT\02.02.03.01_Fundamentals\02.02.03.01.01_Strategy\02.02.03.01.01.01_NRT_Transformation_Strategy.md" "NRT Transformation Strategy" "02.02.03.01.01" "concept" "nrt, strategy, micro-batch" @'
# NRT Transformation Strategy

## Definition

**Near-real-time (NRT) transformation** sits between batch (minutes–hours SLA) and streaming (sub-second). It delivers curated data within **seconds to low minutes** using **micro-batch**, **trigger-based**, or **short-interval scheduled** execution.

## When to choose NRT

| Signal | NRT fit |
| --- | --- |
| Business SLA 1–15 minutes | Strong |
| Source is CDC or incremental files | Strong |
| Need exactly-once lakehouse silver | Strong with Delta/Iceberg MERGE |
| Sub-second alerting on raw events | Use streaming instead |
| Daily/monthly reporting only | Use batch |

## Latency tiers

| Tier | Interval | Typical engines |
| --- | --- | --- |
| **T1** | 30s–2m | Spark SS trigger, Databricks trigger, Dataflow streaming |
| **T2** | 2–15m | Orchestrated micro-batch, Fabric pipelines |
| **T3** | 15–60m | Scheduled warehouse SQL, Glue Flex jobs |

## Architecture decision flow

```mermaid
flowchart TD
  Q1{SLA under 1 min?}
  Q1 -->|Yes| Stream[Streaming_transform]
  Q1 -->|No| Q2{SLA under 15 min?}
  Q2 -->|Yes| NRT[NRT_micro_batch]
  Q2 -->|No| Batch[Batch_transform]
```

## Design principles

1. **Idempotent sinks** — MERGE/upsert by business key; never blind append on updates.
2. **Watermark late data** — define max lateness for micro-batch windows.
3. **Cost vs freshness** — smaller trigger interval = higher cost; measure marginal value.
4. **Unified model** — same silver schema whether batch backfill or NRT incremental.

## Related

- [Micro-Batch Patterns](../02.02.03.01.02_Micro_Batch_Patterns/02.02.03.01.02.01_Micro_Batch_Transform_Patterns.md)
- [Batch vs Stream vs NRT](../../02.02.03.06_Comparisons/02.02.03.06.01_Batch_vs_Streaming_vs_NRT_Transform.md)
'@

ND "$NRT\02.02.03.01_Fundamentals\02.02.03.01.02_Micro_Batch_Patterns\02.02.03.01.02.01_Micro_Batch_Transform_Patterns.md" "Micro-Batch Transform Patterns" "02.02.03.01.02" "concept" "micro-batch, nrt" @'
# Micro-Batch Transform Patterns

## Core pattern

Micro-batch reads **incremental input** (Kafka offset range, file arrival, CDC batch) and writes **curated output** on a fixed trigger.

```mermaid
flowchart LR
  Src[Incremental_Source] --> Trigger[Trigger_Interval]
  Trigger --> Transform[Transform_Logic]
  Transform --> Merge[MERGE_Silver]
```

## Pattern catalog

| Pattern | Input | Output | Notes |
| --- | --- | --- | --- |
| **Append-only facts** | Event stream | Partitioned fact table | Dedup by event_id |
| **CDC upsert** | Debezium/DMS batch | SCD Type 1/2 silver | MERGE on primary key |
| **File landing** | New objects in prefix | Bronze→Silver promotion | List after orchestration sensor |
| **Warehouse incremental** | Streams + tasks | Staging views | Snowflake/BQ native |

## Spark Structured Streaming micro-batch

```python
spark.readStream.format("delta").load("/bronze/orders") \
  .withWatermark("event_time", "10 minutes") \
  .groupBy(window("event_time", "5 minutes"), "region") \
  .agg(F.sum("amount").alias("total")) \
  .writeStream.format("delta").outputMode("append") \
  .trigger(processingTime="1 minute") \
  .start("/gold/orders_5m")
```

## Anti-patterns

- Running full-table scans every trigger interval.
- No checkpoint location for streaming/micro-batch jobs.
- Mixing batch and NRT writes to same table without isolation level plan.

## Related

- [Trigger-Based Transforms](02.02.03.01.02.02_Trigger_Based_Transforms.md)
- [Latency Tiers](02.02.03.01.02.03_Latency_Tiers.md)
'@

ND "$NRT\02.02.03.01_Fundamentals\02.02.03.01.02_Micro_Batch_Patterns\02.02.03.01.02.02_Trigger_Based_Transforms.md" "Trigger-Based Transforms" "02.02.03.01.02" "concept" "trigger, nrt" @'
# Trigger-Based Transforms

## Trigger types

| Trigger | Engine examples | Use case |
| --- | --- | --- |
| **Processing time** | Spark SS, Dataflow | Regular freshness, simple ops |
| **Available-now** | Spark SS (legacy) | Process as fast as possible |
| **Once** | Spark SS, Beam | Backfill single batch |
| **Continuous** | Spark SS experimental | Low latency micro-batch |
| **Orchestrator cron** | Airflow, Dagster | Warehouse SQL every N minutes |
| **Event-driven** | Lambda, Cloud Functions | File arrival, queue message |

## Orchestration-triggered NRT

```mermaid
sequenceDiagram
  participant Orch as Orchestrator
  participant Ingest as Ingestion
  participant Transform as NRT_Job
  participant Lake as Lakehouse
  Orch->>Ingest: Sensor file count
  Ingest-->>Orch: Ready
  Orch->>Transform: Run incremental MERGE
  Transform->>Lake: Upsert silver
  Transform-->>Orch: Success metrics
```

## Databricks trigger example

```python
# Delta Live Tables / structured streaming pipeline
@dlt.table
def silver_orders():
    return spark.readStream.table("bronze.orders") \
        .withWatermark("order_ts", "15 minutes") \
        .dropDuplicates(["order_id"])
```

## Operational checklist

- [ ] Trigger interval documented in SLA matrix
- [ ] Checkpoint/watermark paths on durable storage
- [ ] Alert on processing delay > 2× trigger interval
- [ ] Backfill procedure uses same MERGE logic

## Related

- [Integration: Orchestration Triggers](../../02.02.03.08_Integration_Patterns/02.02.03.08.01_Orchestration_Triggers.md)
'@

ND "$NRT\02.02.03.01_Fundamentals\02.02.03.01.02_Micro_Batch_Patterns\02.02.03.01.02.03_Latency_Tiers.md" "NRT Latency Tiers" "02.02.03.01.02" "concept" "latency, nrt, sla" @'
# NRT Latency Tiers

## Tier definitions

| Tier | End-to-end latency | Compute model | Cost profile |
| ---: | --- | --- | --- |
| **Platinum** | 30s–2m | Always-on streaming/micro-batch | Highest |
| **Gold** | 2–5m | 1–5m trigger, autoscale | Medium-high |
| **Silver** | 5–15m | Orchestrated micro-batch | Medium |
| **Bronze** | 15–60m | Scheduled batch chunks | Lower |

## Measurement points

```mermaid
flowchart LR
  E[Event_time] --> I[Ingest_lag]
  I --> T[Transform_lag]
  T --> Q[Query_available]
```

Track: **ingest lag** (source→bronze), **processing lag** (bronze→silver), **freshness** (silver max timestamp vs now).

## SLA template

| Dataset | Tier | Max lag | Owner |
| --- | --- | --- | --- |
| orders_silver | Gold | 5 min | Data platform |
| inventory_silver | Silver | 15 min | Supply chain |
| finance_gl | Bronze | 60 min | Finance |

## Right-sizing triggers

- Start at **2× expected ingest burst duration**.
- Reduce interval only when downstream dashboards prove value.
- Use **Flex/preemptible** workers for non-platinum tiers.

## Related

- [Micro-Batch Latency Profiles](../../02.02.03.05_Benchmarks/02.02.03.05.01_Micro_Batch_Latency_Profiles.md)
'@

ND "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.01_Overview\02.02.03.02.01.01_Cloud_NRT_Transformation_Reference.md" "Cloud NRT Transformation Reference" "02.02.03.02.01" "overview" "cloud, nrt" @'
# Cloud NRT Transformation Reference Architecture

## Purpose

Hyperscaler mapping for **near-real-time transformation** — micro-batch triggers on managed compute, landing in lakehouse or warehouse silver layers.

## Hyperscaler matrix

| Capability | GCP | AWS | Azure |
| --- | --- | --- | --- |
| Micro-batch engine | Dataflow (Beam) | Glue Streaming / EMR SS | Synapse Spark / Fabric |
| Trigger model | Streaming + batch | Glue job bookmark + SS trigger | Pipeline schedule / Eventstream |
| Lakehouse sink | BigQuery + GCS Delta | S3 Iceberg/Delta + Athena | OneLake Delta |
| Orchestration | Cloud Composer | Step Functions / MWAA | ADF / Fabric pipelines |

## Reference diagram

```mermaid
flowchart TB
  subgraph ingest [Ingest_NRT]
    CDC[CDC]
    Events[Events]
  end
  subgraph broker [Buffer]
    PS[PubSub_Kinesis_EventHubs]
  end
  subgraph transform [NRT_Transform]
    DF[Dataflow_Glue_Spark]
  end
  subgraph lake [Lakehouse]
    Silver[Silver_MERGE]
  end
  CDC --> PS
  Events --> PS
  PS --> DF
  DF --> Silver
```

## Design principles

1. **MERGE idempotency** on silver tables for all NRT paths.
2. **Autoscale** micro-batch workers; avoid fixed oversized clusters.
3. **Private networking** between broker and transform compute.
4. **FinOps** — trigger interval directly drives DPU/vCore hours.

## Related

- [GCP Dataflow Micro-Batch](../02.02.03.02.02_GCP/02.02.03.02.02.01_GCP_Dataflow_Micro_Batch.md)
- [Databricks Trigger](../02.02.03.02.03_AWS/02.02.03.02.03.02_Databricks_Trigger_Transforms.md)
'@

ND "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.02_GCP\02.02.03.02.02.01_GCP_Dataflow_Micro_Batch.md" "GCP Dataflow Micro-Batch" "02.02.03.02.02" "concept" "gcp, dataflow, nrt" @'
# GCP Dataflow Micro-Batch Transformation

## Overview

**Cloud Dataflow** runs Apache Beam pipelines with autoscaling workers. For NRT, use **streaming runner** with windowing or **batch runner** on short Composer schedules for file-based NRT.

## Configuration

| Parameter | NRT recommendation |
| --- | --- |
| `streaming` | `true` for Pub/Sub sources |
| `maxNumWorkers` | Cap for cost control |
| `workerMachineType` | `n1-standard-4` baseline |
| Window | Fixed 1–5m for aggregations |

## Beam trigger example

```python
options = PipelineOptions(streaming=True, max_num_workers=20)
with beam.Pipeline(options=options) as p:
    (p | 'Read' >> beam.io.ReadFromPubSub(subscription=SUB)
       | 'Parse' >> beam.Map(parse_json)
       | 'Window' >> beam.WindowInto(beam.window.FixedWindows(60))
       | 'Write' >> beam.io.WriteToBigQuery(TABLE, method='STREAMING_INSERTS'))
```

## IAM minimum

- `roles/dataflow.worker` on worker SA
- `roles/pubsub.subscriber` on source subscription
- `roles/bigquery.dataEditor` on target dataset

## Related

- [Dataflow Learning Guide](../../../02.02.02_Streaming_Transformation/02.02.02.02_Cloud_Services/02.02.02.02.02_GCP/02.02.02.02.02.03_Dataflow_Learning_Guide/README.md)
'@

ND "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.03_AWS\02.02.03.02.03.01_Spark_Structured_Streaming_Trigger.md" "Spark Structured Streaming Trigger (AWS)" "02.02.03.02.03" "concept" "aws, spark, nrt" @'
# Spark Structured Streaming Trigger on AWS

## Deployment options

| Service | Trigger support | Best for |
| --- | --- | --- |
| **Glue Streaming** | `processingTime` trigger | Managed SS on Kinesis/Kafka |
| **EMR on EKS** | Full SS API | Custom Spark versions |
| **Databricks on AWS** | Delta Live Tables | Lakehouse MERGE silver |

## Glue Streaming trigger

```python
glueContext.forEachBatch(frame=dyf, batch_function=process_batch, options={"windowSize": "60 seconds"})
```

## Checkpointing

- Store checkpoints on **S3** with versioning enabled.
- Separate checkpoint prefix per job/environment.
- Monitor `StructuredStreamingQueryProgress` JSON logs.

## Related

- [Glue Streaming Learning Guide](../../../02.02.02_Streaming_Transformation/02.02.02.02_Cloud_Services/02.02.02.02.03_AWS/02.02.02.02.03.03_Glue_Streaming_Learning_Guide/README.md)
'@

ND "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.03_AWS\02.02.03.02.03.02_Databricks_Trigger_Transforms.md" "Databricks Trigger Transforms" "02.02.03.02.03" "concept" "databricks, trigger, nrt" @'
# Databricks Trigger-Based Transforms

## Delta Live Tables (DLT)

DLT pipelines support **triggered** or **continuous** execution for bronze→silver→gold with declarative expectations.

```python
@dlt.table(name="silver_customers")
@dlt.expect_or_drop("valid_id", "customer_id IS NOT NULL")
def silver_customers():
    return dlt.read_stream("bronze_customers").dropDuplicates(["customer_id"])
```

## Trigger modes

| Mode | Latency | Cost |
| --- | --- | --- |
| Continuous | Lowest | Highest |
| Triggered (1–30m) | NRT tiers | Predictable |
| Scheduled (batch) | Hours | Lowest |

## MERGE streaming sink

Use `foreachBatch` with Delta `merge` for CDC silver:

```python
def upsert_batch(batch_df, batch_id):
    batch_df.createOrReplaceTempView("updates")
    spark.sql("""
        MERGE INTO silver.orders t USING updates s ON t.id = s.id
        WHEN MATCHED THEN UPDATE SET *
        WHEN NOT MATCHED THEN INSERT *
    """)
```

## Related

- [CDC Silver Merge](../../02.02.03.04_Architecture_Patterns/02.02.03.04.01_Micro_Batch/02.02.03.04.01.02_CDC_Silver_Merge.md)
'@

ND "$NRT\02.02.03.02_Cloud_Services\02.02.03.02.04_Azure\02.02.03.02.04.01_Fabric_Real_Time_Transform.md" "Fabric Real-Time Transform" "02.02.03.02.04" "concept" "azure, fabric, nrt" @'
# Microsoft Fabric Real-Time Transformation

## Components

| Component | NRT role |
| --- | --- |
| **Eventstream** | Ingest events into OneLake |
| **KQL Database** | Real-time transform and query |
| **Spark notebook** | Micro-batch on OneLake Delta |
| **Data pipeline** | Schedule notebook/activity every N minutes |

## Eventstream → Lakehouse flow

```mermaid
flowchart LR
  EH[Event_Hubs] --> ES[Eventstream]
  ES --> OL[OneLake_Delta]
  OL --> NB[Spark_Notebook_MERGE]
  NB --> LH[Lakehouse_Silver]
```

## NRT pipeline pattern

1. Eventstream captures source events to **Delta bronze**.
2. Fabric pipeline triggers Spark notebook every **5 minutes**.
3. Notebook runs **MERGE** into silver lakehouse table.
4. Direct Lake mode exposes silver to Power BI with freshness SLA.

## Related

- [Fabric RTI Learning Guide](../../../02.02.02_Streaming_Transformation/02.02.02.02_Cloud_Services/02.02.02.02.04_Azure/02.02.02.02.04.04_Fabric_Real_Time_Intelligence_Learning_Guide/README.md)
'@

ND "$NRT\02.02.03.04_Architecture_Patterns\02.02.03.04.01_Micro_Batch\02.02.03.04.01.01_Micro_Batch_Medallion.md" "Micro-Batch Medallion" "02.02.03.04.01" "concept" "medallion, nrt" @'
# Micro-Batch Medallion Architecture

## Layer flow

```mermaid
flowchart TB
  B[Bronze_raw_append] --> S[Silver_dedup_MERGE]
  S --> G[Gold_aggregates]
```

| Layer | NRT behavior | Storage |
| --- | --- | --- |
| Bronze | Append-only, minimal transform | Raw Delta/Iceberg |
| Silver | MERGE, conform, DQ gates | Curated Delta |
| Gold | Windowed aggregates or batch refresh | Mart tables |

## Incremental silver rules

- **Primary key** enforced at silver MERGE.
- **Late events** handled via watermark + optional side output quarantine.
- **Schema evolution** — additive columns only without migration window.

## Related

- [Medallion Implementation](../../../02.02.04_Shared_Foundations/02.02.04.01_Fundamentals/02.02.04.01.03_Medallion_And_Zones/02.02.04.01.03.01_Medallion_Implementation.md)
'@

ND "$NRT\02.02.03.04_Architecture_Patterns\02.02.03.04.01_Micro_Batch\02.02.03.04.01.02_CDC_Silver_Merge.md" "CDC Silver Merge" "02.02.03.04.01" "concept" "cdc, merge, nrt" @'
# CDC Silver Merge Pattern

## Flow

CDC events (insert/update/delete) land in bronze; micro-batch job MERGEs into silver SCD Type 1 or Type 2.

```mermaid
flowchart LR
  DB[(Source_DB)] --> CDC[CDC_Reader]
  CDC --> Bronze[Bronze_CDC_log]
  Bronze --> Merge[MERGE_Job]
  Merge --> Silver[Silver_current]
```

## MERGE template (Type 1)

```sql
MERGE INTO silver.product AS t
USING bronze.product_cdc AS s ON t.product_id = s.product_id
WHEN MATCHED AND s.op = 'D' THEN DELETE
WHEN MATCHED THEN UPDATE SET name = s.name, price = s.price, updated_at = s.ts
WHEN NOT MATCHED AND s.op != 'D' THEN INSERT *
```

## Type 2 extension

Close prior row (`valid_to = s.ts`), insert new current row with `valid_from = s.ts`.

## Related

- [SCD Patterns](../../../02.02.04_Shared_Foundations/02.02.04.01_Fundamentals/02.02.04.01.04_SCD_And_Slowly_Changing/02.02.04.01.04.01_SCD_Type_1_Patterns.md)
'@

ND "$NRT\02.02.03.04_Architecture_Patterns\02.02.03.04.01_Micro_Batch\02.02.03.04.01.03_Trigger_Orchestration.md" "Trigger Orchestration Pattern" "02.02.03.04.01" "concept" "orchestration, nrt" @'
# Trigger Orchestration for NRT

## Pattern

Orchestrator owns **when**; engine owns **how**. Sensors gate runs until ingest completes.

| Orchestrator | Sensor type | Transform action |
| --- | --- | --- |
| Airflow | S3/GCS prefix | Trigger Glue/Spark job |
| Dagster | Asset materialization | Run op with incremental config |
| Step Functions | EventBridge rule | Lambda + EMR step |
| Fabric | Pipeline schedule | Notebook MERGE |

## Dependency graph

```mermaid
flowchart TD
  Ingest[Ingestion_DAG] --> Sensor[Dataset_Ready]
  Sensor --> NRT[NRT_Transform_DAG]
  NRT --> DQ[Quality_Gate]
  DQ --> Publish[Publish_Gold]
```

## Related

- [Orchestration Triggers](../../02.02.03.08_Integration_Patterns/02.02.03.08.01_Orchestration_Triggers.md)
'@

ND "$NRT\02.02.03.05_Benchmarks\02.02.03.05.01_Micro_Batch_Latency_Profiles.md" "Micro-Batch Latency Profiles" "02.02.03.05" "evaluation" "benchmark, nrt, latency" @'
# Micro-Batch Latency Profiles

## Reference workloads

| ID | Profile | Input rate | Trigger | Expected p99 lag |
| ---: | --- | --- | --- | --- |
| **N1** | Light CDC | 500 rows/s | 1m | < 90s |
| **N2** | Standard events | 5K events/s | 2m | < 3m |
| **N3** | Burst files | 200 files/5m | 5m | < 8m |
| **N4** | Wide MERGE | 50 cols, 10M rows/day | 5m | < 10m |
| **N5** | Multi-hop | Bronze→Silver→Gold | 1m chain | < 5m per hop |

## Measurement methodology

1. Inject timestamped test events at source.
2. Query silver `max(event_time)` vs wall clock every minute.
3. Record p50/p95/p99 **freshness lag** over 24h soak.
4. Document worker count, DPU, shuffle spill.

## Reporting template

```
Profile: N__  Engine: ________  Trigger: ____
p50 lag: __s  p99 lag: __s  Cost/hr: $____
Failures: __  Checkpoint recovery: __min
```

## Related

- [Latency Tiers](../../02.02.03.01_Fundamentals/02.02.03.01.02_Micro_Batch_Patterns/02.02.03.01.02.03_Latency_Tiers.md)
'@

ND "$NRT\02.02.03.06_Comparisons\02.02.03.06.01_Batch_vs_Streaming_vs_NRT_Transform.md" "Batch vs Streaming vs NRT Transform" "02.02.03.06" "evaluation" "comparison, nrt" @'
# Batch vs Streaming vs NRT Transformation

| Dimension | Batch | NRT (Micro-batch) | Streaming |
| --- | --- | --- | --- |
| **Latency SLA** | Minutes–hours | 1–15 minutes | Sub-second–seconds |
| **Compute model** | Scheduled job | Triggered micro-batch | Always-on |
| **State** | Minimal | Windowed/checkpoint | Full stateful |
| **Cost** | Lowest per TB | Medium | Highest |
| **Complexity** | Lowest | Medium | Highest |
| **Best examples** | Nightly ELT | Silver MERGE every 5m | Fraud scoring |
| **Engines** | Spark batch, dbt | SS trigger, DLT, Dataflow | Flink, Kafka Streams |

## Decision matrix

```mermaid
flowchart TD
  A[New transform requirement] --> B{Need sub-second?}
  B -->|Yes| S[Streaming]
  B -->|No| C{Need under 15 min?}
  C -->|Yes| N[NRT]
  C -->|No| T[Batch]
```

## Related

- [NRT Strategy](../../02.02.03.01_Fundamentals/02.02.03.01.01_Strategy/02.02.03.01.01.01_NRT_Transformation_Strategy.md)
'@

ND "$NRT\02.02.03.07_Interview_Questions\02.02.03.07.01_NRT_Transformation_Interview_Questions.md" "NRT Transformation Interview Questions" "02.02.03.07" "evaluation" "interview, nrt" @'
# NRT Transformation Interview Questions

## Fundamentals

1. **Define near-real-time transformation.** How does it differ from batch and true streaming?
2. **Explain micro-batch vs continuous processing.** Trade-offs in cost and latency?
3. **What is a watermark?** How does it affect windowed NRT aggregations?
4. **Why use MERGE instead of append** for CDC silver tables?
5. **Describe checkpointing** in Spark Structured Streaming micro-batch jobs.

## Architecture

6. **Design an NRT pipeline** from Kafka to Delta silver with 5-minute freshness SLA.
7. **How would you handle late-arriving data** beyond the watermark?
8. **Compare trigger-based orchestration vs engine-native triggers.**
9. **How do you backfill** an NRT table without duplicating rows?
10. **Explain idempotency** in foreachBatch MERGE patterns.

## Operations

11. **What metrics alert you** that NRT SLA is at risk?
12. **How do you right-size trigger interval** vs cost?
13. **Describe failure recovery** when checkpoint corruption occurs.

## Related

- [NRT Reference Architecture](../../02.02.03.09_Reference_Architectures/02.02.03.09.01_NRT_Lakehouse_Transform_Reference.md)
'@

ND "$NRT\02.02.03.08_Integration_Patterns\02.02.03.08.01_Orchestration_Triggers.md" "NRT Orchestration Triggers" "02.02.03.08" "concept" "integration, orchestration, nrt" @'
# NRT Orchestration Triggers

## Integration points

| Upstream | Trigger mechanism | Downstream transform |
| --- | --- | --- |
| Batch ingest complete | Airflow dataset | Spark MERGE job |
| File landing | S3 Event → Step Functions | Glue Flex ETL |
| CDC lag threshold | Dagster sensor | DLT pipeline run |
| Message queue depth | Cloud Monitoring alert | Scale Dataflow workers |

## Handoff contract

```yaml
dataset: silver.orders
freshness_sla_minutes: 5
upstream: ingest.orders_cdc
quality_gate: orders_silver_tests
owner: data-platform
```

## Related

- [Ingestion Handoff](02.02.03.08.02_Ingestion_Handoff.md)
- [02.03 Orchestration](../../../02.03_Data_Orchestration_Architecture/README.md)
'@

ND "$NRT\02.02.03.08_Integration_Patterns\02.02.03.08.02_Ingestion_Handoff.md" "NRT Ingestion Handoff" "02.02.03.08" "concept" "integration, ingestion, nrt" @'
# NRT Ingestion Handoff

## Contract between ingest and transform

1. **Landing zone** — bronze path, format, partition scheme documented.
2. **Completion signal** — `_SUCCESS` file, metadata table row, or orchestrator dataset.
3. **Schema version** — compatibility matrix in catalog.
4. **SLA clock starts** at completion signal, not source event time.

## Sequence

```mermaid
sequenceDiagram
  participant Ing as 02.01_Ingestion
  participant Meta as Catalog
  participant Tr as 02.02_NRT_Transform
  Ing->>Meta: Register partition + schema
  Ing->>Tr: Signal ready
  Tr->>Tr: Incremental MERGE
  Tr->>Meta: Update lineage + freshness
```

## Related

- [02.01 Ingestion Architecture](../../../02.01_Data_Ingestion_Architecture/README.md)
'@

ND "$NRT\02.02.03.09_Reference_Architectures\02.02.03.09.01_NRT_Lakehouse_Transform_Reference.md" "NRT Lakehouse Transform Reference" "02.02.03.09" "overview" "reference, nrt, lakehouse" @'
# NRT Lakehouse Transform Reference Architecture

## Enterprise reference

```mermaid
flowchart TB
  subgraph sources [Sources]
    OLTP[OLTP_CDC]
    Events[Product_Events]
  end
  subgraph ingest [02.01_Ingestion]
    Broker[Managed_Broker]
    Bronze[Bronze_Lake]
  end
  subgraph transform [02.02.03_NRT]
    Trigger[Orchestrator_Trigger]
    Engine[Spark_Dataflow_DLT]
    Silver[Silver_MERGE]
    Gold[Gold_Aggregates]
  end
  subgraph consume [Consumption]
    BI[BI_Dashboards]
    ML[Feature_Store]
  end
  OLTP --> Broker
  Events --> Broker
  Broker --> Bronze
  Bronze --> Trigger
  Trigger --> Engine
  Engine --> Silver
  Silver --> Gold
  Gold --> BI
  Gold --> ML
```

## Component responsibilities

| Layer | Technology examples | SLA |
| --- | --- | --- |
| Ingest | Pub/Sub, Kinesis, Debezium | < 1m to bronze |
| NRT transform | DLT, Glue SS, Dataflow | 2–10m to silver |
| Quality | Great Expectations, DLT expectations | Block publish on fail |
| Serve | Direct Lake, BQ, Snowflake | Query freshness tag |

## Related

- [Cloud NRT Reference](../02.02.03.02_Cloud_Services/02.02.03.02.01_Overview/02.02.03.02.01.01_Cloud_NRT_Transformation_Reference.md)
'@

Write-Host "Phase 3 complete."

# ========== Phase 4: Fill streaming gaps (02.02.02) ==========
Write-Host "Phase 4: Fill streaming gaps (02.02.02)"
$STR = "02.02.02_Streaming_Transformation"

Ensure-Directory (Join-Path $Base "$STR\02.02.02.01_Fundamentals\02.02.02.01.02_Stream_Processing")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.01_Fundamentals\02.02.02.01.03_State_And_Windows")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.02_Cloud_Services\02.02.02.02.01_Overview")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.02_Cloud_Services\02.02.02.02.05_Cross_Cloud")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.04_Architecture_Patterns\02.02.02.04.01_ETL_ELT")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.04_Architecture_Patterns\02.02.02.04.02_Medallion")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.04_Architecture_Patterns\02.02.02.04.03_Data_Quality_In_Transform")
Ensure-Directory (Join-Path $Base "$STR\02.02.02.04_Architecture_Patterns\02.02.02.04.04_Reference_Architectures")

$Phase4Files = @{
    "$STR\02.02.02.01_Fundamentals\02.02.02.01.02_Stream_Processing\02.02.02.01.02.01_Stream_Processing_Overview.md" = @("Stream Processing Overview", "02.02.02.01.02", "concept", "streaming, fundamentals", "# Stream Processing Overview`n`n## Definition`n`n**Stream processing** applies transformations to unbounded event sequences with low latency, maintaining state across events.`n`n## Core concepts`n`n| Concept | Description |`n| --- | --- |`n| **Event** | Immutable record with timestamp and payload |`n| **Stream** | Ordered sequence of events |`n| **Operator** | Map, filter, join, aggregate on streams |`n| **Sink** | Materialized output (lake, DB, topic) |`n`n## Processing guarantees`n`n| Guarantee | Meaning |`n| --- | --- |`n| At-most-once | May lose events |`n| At-least-once | May duplicate; idempotent sinks required |`n| Exactly-once | End-to-end once (engine + transactional sink) |`n`n## Related`n`n- [State and Windows](../02.02.02.01.03_State_And_Windows/02.02.02.01.03.01_State_And_Windows.md)")
    "$STR\02.02.02.01_Fundamentals\02.02.02.01.03_State_And_Windows\02.02.02.01.03.01_State_And_Windows.md" = @("State and Windows", "02.02.02.01.03", "concept", "streaming, state, windows", "# State and Windows`n`n## Stateful operators`n`nAggregations, joins, and sessionization require **state** stored in RocksDB (Flink) or memory+checkpoint (Spark SS).`n`n## Window types`n`n| Window | Use case |`n| --- | --- |`n| Tumbling | Fixed non-overlapping buckets |`n| Sliding | Moving averages |`n| Session | User activity gaps |`n| Global | Single window (careful with unbounded state) |`n`n## Event time vs processing time`n`n- **Event time** - when event occurred (correct for analytics).`n- **Processing time** - when processed (simple, non-deterministic under lag).`n`n## Related`n`n- [Watermarks for Transforms](02.02.02.01.03.02_Watermarks_For_Transforms.md)")
    "$STR\02.02.02.01_Fundamentals\02.02.02.01.03_State_And_Windows\02.02.02.01.03.02_Watermarks_For_Transforms.md" = @("Watermarks for Transforms", "02.02.02.01.03", "concept", "watermarks, streaming", "# Watermarks for Transforms`n`n## Purpose`n`nWatermarks declare **how late** event-time data may arrive; windows close after watermark passes end of window.`n`n## Configuration`n`n````python`n.withWatermark('event_ts', '10 minutes')`n````n`n## Late data strategies`n`n| Strategy | Behavior |`n| --- | --- |`n| Drop | Ignore late events |`n| Side output | Route to quarantine stream |`n| Allowed lateness | Update closed windows (Flink) |`n`n## Related`n`n- [Stream-Table Duality](02.02.02.01.03.03_Stream_Table_Duality.md)")
    "$STR\02.02.02.01_Fundamentals\02.02.02.01.03_State_And_Windows\02.02.02.01.03.03_Stream_Table_Duality.md" = @("Stream-Table Duality", "02.02.02.01.03", "concept", "streaming, tables", "# Stream-Table Duality`n`n## Concept`n`nA **changelog stream** can rebuild a **table**; a **table** can emit a **changelog stream** (CDC). Unified engines (Flink SQL, Materialize) exploit this duality.`n`n## Implications for transforms`n`n| Direction | Pattern |`n| --- | --- |`n| Stream to Table | Aggregating sink, MERGE into lake |`n| Table to Stream | CDC source, binlog capture |`n| Stream join Stream | Join stream with table (temporal join) |`n`n## Related`n`n- [CDC Merge Streaming](../../02.02.02.04_Architecture_Patterns/02.02.02.04.02_Medallion/02.02.02.04.02.03_CDC_Merge_Streaming.md)")
    "$STR\02.02.02.02_Cloud_Services\02.02.02.02.01_Overview\02.02.02.02.01.01_Cloud_Streaming_Transformation_Reference.md" = @("Cloud Streaming Transformation Reference Architecture", "02.02.02.02.01", "overview", "cloud, streaming", "# Cloud Streaming Transformation Reference Architecture`n`n## Purpose`n`nHyperscaler mapping for **streaming transformation** - stateful compute on managed brokers, writing to lakehouse and real-time serving.`n`n## Matrix`n`n| Capability | GCP | AWS | Azure |`n| --- | --- | --- | --- |`n| Broker | Pub/Sub | Kinesis/MSK | Event Hubs |`n| Processor | Dataflow | Managed Flink/Glue SS | Stream Analytics/Fabric |`n| State store | Managed + GCS checkpoints | S3 checkpoints | ADLS checkpoints |`n| Lake sink | BigQuery streaming | S3 Delta/Iceberg | OneLake Delta |`n`n## Diagram`n`n````mermaid`nflowchart TB`n  Broker[Broker] --> Proc[Stream_Processor]`n  Proc --> Lake[Lakehouse_Silver]`n  Proc --> RT[Real_Time_Serving]`n````n`n## Related`n`n- [Multi-Cloud Streaming Transforms](../02.02.02.02.05_Cross_Cloud/02.02.02.02.05.01_Multi_Cloud_Streaming_Transform_Patterns.md)")
    "$STR\02.02.02.02_Cloud_Services\02.02.02.02.05_Cross_Cloud\02.02.02.02.05.01_Multi_Cloud_Streaming_Transform_Patterns.md" = @("Multi-Cloud Streaming Transform Patterns", "02.02.02.02.05", "concept", "cross-cloud, streaming", "# Multi-Cloud Streaming Transform Patterns`n`n## Patterns`n`n| Pattern | Description |`n| --- | --- |`n| **Portable Beam** | Same pipeline on Dataflow, Flink, Spark runner |`n| **Kafka as bus** | MSK/Confluent Cloud neutral transport |`n| **Dual write** | Transform in primary cloud, replicate gold to DR |`n| **Federated query** | Trino over multi-cloud silver tables |`n`n## Governance`n`n- Unified schema registry (Confluent/Glue).`n- Cross-cloud IAM via workload identity federation.`n- Single observability plane (OpenTelemetry).`n`n## Related`n`n- [02.03 Cross-Cloud Orchestration](../../../02.03_Data_Orchestration_Architecture/02.03.02_Cloud_Services/02.03.02.05_Cross_Cloud/02.03.02.05.01_Multi_Cloud_Orchestration_Patterns.md)")
}
foreach ($kv in $Phase4Files.GetEnumerator()) {
    $parts = $kv.Value
    ND $kv.Key $parts[0] $parts[1] $parts[2] $parts[3] $parts[4]
}

# Architecture patterns (8 files)
$ArchPatterns = @(
    @("02.02.02.04.01.01_Stream_Enrichment.md", "Stream Enrichment", "Join streaming events with dimension tables (broadcast or async lookup). Use Redis/BQ for low-latency dims; cache TTL aligned with freshness SLA.")
    @("02.02.02.04.01.02_Windowed_Aggregation.md", "Windowed Aggregation", "Tumbling/sliding windows for metrics. Emit to lake via foreachBatch MERGE or streaming sink.")
    @("02.02.02.04.02.01_Streaming_Medallion.md", "Streaming Medallion", "Bronze append from broker; silver streaming MERGE; gold batch or streaming aggregates.")
    @("02.02.02.04.02.02_Stream_To_Batch_Handoff.md", "Stream-to-Batch Handoff", "Archive raw to lake; batch job reconciles silver nightly; streaming handles hot path.")
    @("02.02.02.04.02.03_CDC_Merge_Streaming.md", "CDC Merge Streaming", "Debezium to Kafka to Flink MERGE into Delta silver with exactly-once semantics.")
    @("02.02.02.04.03.01_DQ_In_Stream.md", "Data Quality in Stream", "Expectations on micro-batch; quarantine side output for failed records.")
    @("02.02.02.04.04.01_Event_Time_Correction.md", "Event-Time Correction", "Reprocess with updated watermarks; versioned silver tables.")
    @("02.02.02.04.04.02_Multi_Sink_Fanout.md", "Multi-Sink Fanout", "Single transform to lake plus metrics topic plus alert sink.")
)
foreach ($ap in $ArchPatterns) {
    $subdir = if ($ap[0] -match '04.01') { "02.02.02.04.01_ETL_ELT" } elseif ($ap[0] -match '04.02') { "02.02.02.04.02_Medallion" } elseif ($ap[0] -match '04.03') { "02.02.02.04.03_Data_Quality_In_Transform" } else { "02.02.02.04.04_Reference_Architectures" }
    $body = "# $($ap[1])`n`n## Overview`n`n$($ap[2])`n`n## Architecture`n`n````mermaid`nflowchart LR`n  In[Input_Stream] --> T[Transform]`n  T --> Out[Output]`n````n`n## Implementation notes`n`n- Design for **at-least-once** with idempotent sinks.`n- Monitor **state size** and checkpoint duration.`n- Document **schema evolution** policy.`n`n## Related`n`n- [Streaming Transformation Overview](../../02.02.02.01_Fundamentals/02.02.02.01.01_Overview/02.02.02.01.01.01_Streaming_Transformation_Overview.md)"
    ND "$STR\02.02.02.04_Architecture_Patterns\$subdir\$($ap[0])" $ap[1] "02.02.02.04" "concept" "streaming, architecture" $body
}

# Benchmarks (4), Comparisons (4), Interview (3), Integration (3), Reference (2)
$StreamBench = @("Latency_Benchmarks", "Throughput_Benchmarks", "State_Size_Benchmarks", "Checkpoint_Recovery_Benchmarks")
$i = 1; foreach ($b in $StreamBench) {
    ND "$STR\02.02.02.05_Benchmarks\02.02.02.05.0$i`_$b.md" "Streaming $b" "02.02.02.05" "evaluation" "benchmark, streaming" "# Streaming $b`n`n## Methodology`n`nRun in isolated cluster with synthetic load; measure p50/p99 over 24h.`n`n## Reference profiles`n`n| ID | Load | Metric target |`n| ---: | --- | --- |`n| S1 | 1K evt/s | p99 < 5s |`n| S2 | 10K evt/s | p99 < 10s |`n| S3 | 100K evt/s | p99 < 30s |`n| S4 | Stateful join | State < 50GB |`n| S5 | Recovery | RTO < 5 min |`n`n## Related`n`n- [Flink Learning Guide](../02.02.02.03_Open_Source/02.02.02.03.02_Apache_Flink_Learning_Guide/README.md)"
    $i++
}
$StreamCmp = @(
    @("02.02.02.06.01_Flink_vs_Spark_SS_vs_Kafka_Streams.md", "Flink vs Spark SS vs Kafka Streams", "Engine comparison for stateful streaming transforms.")
    @("02.02.02.06.02_Batch_vs_Stream_Transform.md", "Batch vs Stream Transform", "When to migrate batch jobs to streaming.")
    @("02.02.02.06.03_Managed_vs_Self_Hosted_Streaming.md", "Managed vs Self-Hosted Streaming", "Ops burden vs control trade-off.")
    @("02.02.02.06.04_Event_Time_vs_Processing_Time.md", "Event Time vs Processing Time", "Correctness vs simplicity in transforms.")
)
foreach ($c in $StreamCmp) {
    ND "$STR\02.02.02.06_Comparisons\$($c[0])" $c[1] "02.02.02.06" "evaluation" "comparison, streaming" "# $($c[1])`n`n$($c[2])`n`n| Dimension | Option A | Option B |`n| --- | --- | --- |`n| Latency | | |`n| State | | |`n| Ops | | |`n| Cost | | |"
}
ND "$STR\02.02.02.07_Interview_Questions\02.02.02.07.01_Streaming_Transform_Fundamentals.md" "Streaming Transform Fundamentals Interview" "02.02.02.07" "evaluation" "interview, streaming" "# Streaming Transform Fundamentals`n`n1. Explain event-time vs processing-time.`n2. What is a watermark?`n3. At-least-once vs exactly-once.`n4. How does Kafka partition affect parallelism?`n5. Stateful vs stateless operators."
ND "$STR\02.02.02.07_Interview_Questions\02.02.02.07.02_Streaming_System_Design.md" "Streaming System Design Interview" "02.02.02.07" "evaluation" "interview, system-design" "# Streaming System Design`n`n1. Design fraud detection pipeline (1M TPS).`n2. CDC to lakehouse with 30s SLA.`n3. Handle schema breaking change in production stream."
ND "$STR\02.02.02.07_Interview_Questions\02.02.02.07.03_Flink_Spark_Deep_Dive.md" "Flink Spark Deep Dive Interview" "02.02.02.07" "evaluation" "interview, flink, spark" "# Flink / Spark Deep Dive`n`n1. Compare Flink checkpoint vs Spark SS checkpoint.`n2. Explain backpressure.`n3. RocksDB state tuning parameters."
ND "$STR\02.02.02.08_Integration_Patterns\02.02.02.08.01_Catalog_Lineage.md" "Streaming Catalog Lineage" "02.02.02.08" "concept" "integration, catalog" "# Catalog and Lineage`n`nRegister streaming sinks in Unity Catalog/Glue/Data Catalog; emit OpenLineage from job completion."
ND "$STR\02.02.02.08_Integration_Patterns\02.02.02.08.02_Orchestration_Integration.md" "Streaming Orchestration Integration" "02.02.02.08" "concept" "integration, orchestration" "# Orchestration Integration`n`nDeploy/stream jobs via CI/CD; orchestrator monitors lag sensors; coordinated backfill with batch DAGs."
ND "$STR\02.02.02.08_Integration_Patterns\02.02.02.08.03_Observability.md" "Streaming Transform Observability" "02.02.02.08" "concept" "integration, observability" "# Observability`n`nMetrics: lag, throughput, state bytes, checkpoint duration, failed records. Dashboards per job; SLO burn alerts."
ND "$STR\02.02.02.09_Reference_Architectures\02.02.02.09.01_Enterprise_Streaming_Transform_Platform.md" "Enterprise Streaming Transform Platform" "02.02.02.09" "overview" "reference, streaming" @'
# Enterprise Streaming Transform Platform

```mermaid
flowchart TB
  Src[Sources] --> Bus[Event_Bus]
  Bus --> Proc[Stream_Processors]
  Proc --> Lake[Lakehouse]
  Proc --> Svc[Serving_Layer]
  Gov[Governance] --> Proc
```
'@
ND "$STR\02.02.02.09_Reference_Architectures\02.02.02.09.02_Streaming_To_Lakehouse.md" "Streaming to Lakehouse Reference" "02.02.02.09" "overview" "reference, lakehouse" "# Streaming to Lakehouse`n`nBroker to Flink/SS to Delta/Iceberg silver to gold batch refresh. Exactly-once via transactional sinks."

Write-Host "Phase 4 complete."

# ========== Phase 5: Fill batch gaps (02.02.01) ==========
Write-Host "Phase 5: Fill batch gaps (02.02.01)"
$BAT = "02.02.01_Batch_Transformation"

Ensure-Directory (Join-Path $Base "$BAT\02.02.01.02_Cloud_Services\02.02.01.02.05_Cross_Cloud")
Ensure-Directory (Join-Path $Base "$BAT\02.02.01.04_Architecture_Patterns\02.02.01.04.02_Medallion")
Ensure-Directory (Join-Path $Base "$BAT\02.02.01.04_Architecture_Patterns\02.02.01.04.03_Data_Quality_In_Transform")
Ensure-Directory (Join-Path $Base "$BAT\02.02.01.04_Architecture_Patterns\02.02.01.04.04_Reference_Architectures")
Ensure-Directory (Join-Path $Base "$BAT\02.02.01.07_Interview_Questions")
Ensure-Directory (Join-Path $Base "$BAT\02.02.01.08_Integration_Patterns")
Ensure-Directory (Join-Path $Base "$BAT\02.02.01.09_Reference_Architectures")

$BatchArch = @(
    @("02.02.01.04.01.01_ETL_Batch_Architecture.md", "ETL Batch Architecture", "02.02.01.04.01_ETL_ELT", "Extract on schedule, transform in Spark/Glue, load to warehouse/lake.")
    @("02.02.01.04.01.03_ELT_Batch_Architecture.md", "ELT Batch Architecture", "02.02.01.04.01_ETL_ELT", "Load raw to lake/warehouse; transform with dbt/SQL on schedule.")
    @("02.02.01.04.02.01_Medallion_Batch_Pipeline.md", "Medallion Batch Pipeline", "02.02.01.04.02_Medallion", "Bronze ingest, silver conform MERGE, gold marts - all batch scheduled.")
    @("02.02.01.04.02.02_Batch_SCD_Processing.md", "Batch SCD Processing", "02.02.01.04.02_Medallion", "Type 2 MERGE in nightly batch; snapshot tables for audit.")
    @("02.02.01.04.03.01_Data_Quality_In_Batch_Transform.md", "Data Quality in Batch Transform", "02.02.01.04.03_Data_Quality_In_Transform", "Great Expectations/dbt tests gate gold publish.")
    @("02.02.01.04.03.02_Quarantine_Pattern.md", "Batch Quarantine Pattern", "02.02.01.04.03_Data_Quality_In_Transform", "Invalid rows to quarantine table; SLA alert on quarantine rate.")
    @("02.02.01.04.04.01_Batch_Reference_Architecture_A.md", "Batch Reference Architecture - Lakehouse", "02.02.01.04.04_Reference_Architectures", "S3/ADLS bronze to Spark silver to dbt gold.")
    @("02.02.01.04.04.02_Batch_Reference_Architecture_B.md", "Batch Reference Architecture - Warehouse-Centric", "02.02.01.04.04_Reference_Architectures", "ELT: load staging, dbt marts in Snowflake/BQ.")
)
foreach ($ba in $BatchArch) {
    $body = "# $($ba[1])`n`n## Overview`n`n$($ba[3])`n`n## Diagram`n`n````mermaid`nflowchart LR`n  Src[Sources] --> Ext[Extract]`n  Ext --> Tr[Transform]`n  Tr --> Load[Load]`n````n`n## Best practices`n`n- Idempotent partition overwrites.`n- Schema contracts in catalog.`n- Backfill runbook documented."
    ND "$BAT\02.02.01.04_Architecture_Patterns\$($ba[2])\$($ba[0])" $ba[1] "02.02.01.04" "concept" "batch, architecture" $body
}

ND "$BAT\02.02.01.02_Cloud_Services\02.02.01.02.05_Cross_Cloud\02.02.01.02.05.01_Multi_Cloud_Batch_Transform_Patterns.md" "Multi-Cloud Batch Transform Patterns" "02.02.01.02.05" "concept" "cross-cloud, batch" @'
# Multi-Cloud Batch Transform Patterns

| Pattern | Description |
| --- | --- |
| **Portable Spark** | Same JAR/wheel on EMR, Dataproc, Synapse |
| **dbt multi-target** | One project, profiles per warehouse |
| **Object storage neutral** | Delta on S3 + GCS via replication |
| **Orchestration hub** | Airflow on K8s triggering cloud jobs |

## IAM federation

Use workload identity: GCP SA, AWS IAM role, Azure managed identity federation for cross-cloud pipeline steps.
'@

ND "$BAT\02.02.01.02_Cloud_Services\02.02.01.02.05_Cross_Cloud\02.02.01.02.05.02_Informatica_Matillion_Cross_Cloud.md" "Informatica Matillion Cross-Cloud" "02.02.01.02.05" "concept" "informatica, matillion, cross-cloud" @'
# Informatica / Matillion Cross-Cloud

Enterprise iPaaS and cloud ELT tools support **multi-cloud targets** with push-down SQL.

| Tool | Strength | Cross-cloud pattern |
| --- | --- | --- |
| **Informatica IDMC** | Governance, lineage | Hybrid: on-prem extract → cloud transform |
| **Matillion** | Warehouse push-down | Same design, deploy to BQ/Snowflake/Databricks |

## Selection criteria

- Existing Informatica skill base → IDMC.
- Cloud-native ELT → Matillion or dbt.
'@

# Enhance comparisons + add Glue vs EMR, BQ vs Snowflake
ND "$BAT\02.02.01.06_Comparisons\02.02.01.06.01_ETL_vs_ELT.md" "ETL vs ELT Comparison" "02.02.01.06" "evaluation" "etl, elt" @'
# ETL vs ELT

| Dimension | ETL | ELT |
| --- | --- | --- |
| Transform location | External engine before load | Inside target warehouse/lake |
| Typical tools | Spark, Glue, Informatica | dbt, BigQuery SQL, Snowflake |
| Best when | Heavy cleansing on files, PII masking pre-load | Warehouse compute elastic and cheap |
| Data residency | Transform in controlled VPC | Raw lands first; policy in warehouse |
| Testing | Engine-specific + integration tests | dbt tests + warehouse CI |
| Cost driver | Cluster DPUs / EMR hours | Warehouse credits / slot hours |
| Latency | Extra hop before query | Faster time-to-query on raw |
| Skill set | Spark/Python + SQL | SQL-first analytics engineering |

## Decision guide

Use **ETL** when compliance requires transform before persistence. Use **ELT** when warehouse is the system of record and SQL suffices.
'@

ND "$BAT\02.02.01.06_Comparisons\02.02.01.06.02_Spark_vs_dbt.md" "Spark vs dbt Comparison" "02.02.01.06" "evaluation" "spark, dbt" @'
# Spark vs dbt

| Dimension | Apache Spark | dbt |
| --- | --- | --- |
| Primary API | Python/Scala/SQL DataFrames | SQL + Jinja |
| Data location | Lake files (Parquet/Delta) | Warehouse tables |
| Best scale | TB+ distributed file processing | Warehouse-native TB via push-down |
| Lineage/tests | External (OpenLineage, custom) | Built-in |
| Streaming | Structured Streaming | Streams/tasks (warehouse-specific) |
| Portability | High across clouds | Tied to warehouse dialect |
| Team profile | Data engineering / ML | Analytics engineering |

## Hybrid pattern

Spark builds silver lake tables; dbt builds gold marts in warehouse over external/silver tables.
'@

ND "$BAT\02.02.01.06_Comparisons\02.02.01.06.03_Glue_vs_EMR.md" "Glue vs EMR Comparison" "02.02.01.06" "evaluation" "glue, emr, aws" @'
# AWS Glue vs EMR

| Dimension | AWS Glue | Amazon EMR |
| --- | --- | --- |
| Ops model | Fully managed serverless Spark | Managed clusters (EC2/EKS) |
| Startup | Faster for small jobs | Cluster warmup overhead |
| Control | Limited Spark tuning | Full Spark/Hadoop ecosystem |
| Cost | DPU-hour + Flex discount | EC2 + EMR premium |
| Bookmarks | Native incremental | Custom |
| Best for | Standard ETL, catalog integration | Heavy tuning, Flink, Presto co-locate |
'@

ND "$BAT\02.02.01.06_Comparisons\02.02.01.06.04_BigQuery_vs_Snowflake_Transform.md" "BigQuery vs Snowflake Transform" "02.02.01.06" "evaluation" "bigquery, snowflake" @'
# BigQuery vs Snowflake Transformation

| Dimension | BigQuery | Snowflake |
| --- | --- | --- |
| SQL transforms | Native scheduled queries, Dataform | Tasks, streams, dbt |
| Semi-structured | JSON functions, nested fields | VARIANT + flatten |
| Incremental | Partition decorators, MERGE | Streams + tasks MERGE |
| Cost model | On-demand vs slots | Credits warehouses |
| Lake integration | External tables, BigLake | Iceberg external volumes |
| ML transforms | BQML in SQL | Snowpark Python/Scala |
'@

ND "$BAT\02.02.01.07_Interview_Questions\02.02.01.07.01_Batch_Transform_Fundamentals.md" "Batch Transform Fundamentals Interview" "02.02.01.07" "evaluation" "interview, batch" "# Batch Transform Fundamentals`n`n1. ETL vs ELT - when each?`n2. Idempotent batch design.`n3. Partition strategy for backfill.`n4. SCD Type 2 in batch.`n5. Handling schema evolution."
ND "$BAT\02.02.01.07_Interview_Questions\02.02.01.07.02_Spark_Batch_Deep_Dive.md" "Spark Batch Deep Dive Interview" "02.02.01.07" "evaluation" "interview, spark" "# Spark Batch Deep Dive`n`n1. Catalyst optimizer stages.`n2. Shuffle and skew mitigation.`n3. Delta MERGE performance.`n4. Adaptive Query Execution."
ND "$BAT\02.02.01.07_Interview_Questions\02.02.01.07.03_Batch_System_Design.md" "Batch System Design Interview" "02.02.01.07" "evaluation" "interview, system-design" "# Batch System Design`n`n1. Design nightly medallion for 500 sources.`n2. SLAs with cross-region DR.`n3. Cost optimization for 10PB lake."

ND "$BAT\02.02.01.08_Integration_Patterns\02.02.01.08.03_Orchestration_Integration.md" "Batch Orchestration Integration" "02.02.01.08" "concept" "integration, orchestration" "# Batch Orchestration Integration`n`nAirflow/Dagster/Prefect trigger Spark/dbt; sensors on upstream datasets; retry and SLA callbacks."
ND "$BAT\02.02.01.08_Integration_Patterns\02.02.01.08.04_Catalog_Integration.md" "Batch Catalog Integration" "02.02.01.08" "concept" "integration, catalog" "# Catalog Integration`n`nRegister tables in Glue/Unity/Hive; column lineage from dbt/Spark; tag PII columns."
ND "$BAT\02.02.01.08_Integration_Patterns\02.02.01.08.05_Quality_Gates.md" "Batch Quality Gates" "02.02.01.08" "concept" "integration, quality" "# Quality Gates`n`nBlock downstream DAG on test failure; quarantine bad partitions; notify owners via Slack/PagerDuty."
ND "$BAT\02.02.01.08_Integration_Patterns\02.02.01.08.06_Lineage_Observability.md" "Batch Lineage Observability" "02.02.01.08" "concept" "integration, lineage" "# Lineage and Observability`n`nOpenLineage emitters; row count metrics; runtime vs historical baseline alerts."

ND "$BAT\02.02.01.09_Reference_Architectures\02.02.01.09.01_Enterprise_Batch_Transform_Platform.md" "Enterprise Batch Transform Platform" "02.02.01.09" "overview" "reference, batch" "# Enterprise Batch Transform Platform`n`nOrchestrator to Spark/dbt/Glue to medallion lakehouse to warehouse marts to BI. CI/CD for transforms; Unity Catalog governance."
ND "$BAT\02.02.01.09_Reference_Architectures\02.02.01.09.02_Lakehouse_Batch_Medallion.md" "Lakehouse Batch Medallion Reference" "02.02.01.09" "overview" "reference, medallion" "# Lakehouse Batch Medallion`n`nBronze (raw Delta) to Silver (conformed MERGE) to Gold (dbt/Spark aggregates). Partition by date; OPTIMIZE/VACUUM schedule."

# Replace Problem Statement templates in batch fundamentals/benchmarks
function Replace-ProblemStatementFiles($searchPath, $topicHint) {
    Get-ChildItem $searchPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $longPath = Get-LongPath $_.FullName
            if (-not [IO.File]::Exists($longPath)) { return }
            $raw = [IO.File]::ReadAllText($longPath, $utf8)
            if ($raw -notmatch '## Problem Statement') { return }
            $title = if ($raw -match 'title:\s*(.+)') { $Matches[1].Trim() } else { $_.BaseName.Replace('_', ' ') }
            $sec = if ($raw -match 'section:\s*"([^"]+)"') { $Matches[1] } else { "02.02.01" }
            $tpl = if ($raw -match 'template:\s*(\S+)') { $Matches[1] } else { "concept" }
            $tagHint = if ($searchPath -match '02.02.04') { "shared, transformation" } else { "batch, transformation" }
            $newBody = @"
# $title

## Executive summary

Expert guidance on **$title** for batch transformation - patterns, technology options, and production considerations for enterprise data platforms.

## Business drivers

- Reduce time-to-insight for curated datasets.
- Enforce data quality before consumption.
- Optimize compute cost for recurring batch workloads.

## Architecture pattern

````mermaid
flowchart LR
  Raw[Raw_Data] --> Transform[Batch_Transform]
  Transform --> Curated[Curated_Output]
````

## Technology landscape

| Category | Options |
| --- | --- |
| Distributed | Spark, Beam, Flink batch |
| Warehouse SQL | dbt, BigQuery, Snowflake |
| Cloud managed | Glue, Dataproc, Synapse |
| Enterprise ETL | Informatica, Talend |

## Cloud native matrix

| Capability | AWS | Azure | GCP |
| --- | --- | --- | --- |
| Managed Spark | Glue, EMR | Synapse, Fabric | Dataproc |
| SQL ELT | Athena + dbt | Fabric warehouse | BigQuery + Dataform |
| Orchestration | MWAA, Step Functions | ADF, Fabric | Composer |

## Production checklist

- [ ] Idempotent writes and partition strategy documented
- [ ] Backfill procedure tested
- [ ] Row-count and null-rate monitors
- [ ] Cost caps and autoscaling policy
- [ ] Schema evolution runbook

## Related

- [Batch Transformation Overview](../02.02.01.01_Fundamentals/02.02.01.01.01_Overview/02.02.01.01.01.01_Batch_Transformation_Overview.md)
- [Shared Foundations ETL Strategy](../../02.02.04_Shared_Foundations/02.02.04.01_Fundamentals/02.02.04.01.02_ETL_ELT_Strategy/02.02.04.01.02.01_ETL_Strategy.md)
"@
            Write-Doc $_.FullName ((Get-FM $title $sec $tpl $tagHint) + $newBody)
        } catch {
            [void]$Stats.Errors.Add("Replace-ProblemStatement $($_.FullName): $_")
        }
    }
}
Replace-ProblemStatementFiles (Join-Path $Base "$BAT\02.02.01.01_Fundamentals") "batch fundamentals"
Replace-ProblemStatementFiles (Join-Path $Base "$BAT\02.02.01.05_Benchmarks") "batch benchmarks"

Write-Host "Phase 5 complete."

# ========== Phase 6: Fill shared foundations (02.02.04) ==========
Write-Host "Phase 6: Fill shared foundations (02.02.04)"
$SHR = "02.02.04_Shared_Foundations"

Ensure-Directory (Join-Path $Base "$SHR\02.02.04.01_Fundamentals\02.02.04.01.04_SCD_And_Slowly_Changing")
Ensure-Directory (Join-Path $Base "$SHR\02.02.04.01_Fundamentals\02.02.04.01.06_Cross_Mode_Transformation")
Ensure-Directory (Join-Path $Base "$SHR\02.02.04.04_Architecture_Patterns\02.02.04.04.01_Reference_Architectures")
Ensure-Directory (Join-Path $Base "$SHR\02.02.04.09_Reference_Architectures")

ND "$SHR\02.02.04.01_Fundamentals\02.02.04.01.04_SCD_And_Slowly_Changing\02.02.04.01.04.01_SCD_Type_1_Patterns.md" "SCD Type 1 Implementation Patterns" "02.02.04.01.04" "concept" "scd, type-1" @'
# SCD Type 1 Implementation Patterns

**Type 1** overwrites attribute values — no history preserved.

## SQL pattern

```sql
MERGE INTO dim.customer t
USING staging.customer s ON t.customer_id = s.customer_id
WHEN MATCHED THEN UPDATE SET name = s.name, email = s.email, updated_at = CURRENT_TIMESTAMP();
```

## When to use

- Correcting errors, not tracking history.
- Attributes where history has no analytic value (e.g., current phone number display).

## Batch vs NRT

| Mode | Approach |
| --- | --- |
| Batch | Nightly MERGE from staging |
| NRT | Micro-batch MERGE on CDC stream |
| Streaming | Flink temporal table join + upsert sink |
'@

ND "$SHR\02.02.04.01_Fundamentals\02.02.04.01.04_SCD_And_Slowly_Changing\02.02.04.01.04.02_SCD_Type_2_Patterns.md" "SCD Type 2 Implementation Patterns" "02.02.04.01.04" "concept" "scd, type-2" @'
# SCD Type 2 Implementation Patterns

Track full history with **valid_from**, **valid_to**, **is_current**.

## MERGE logic

```sql
MERGE INTO dim.product t
USING changes s ON t.product_id = s.product_id AND t.is_current = TRUE
WHEN MATCHED AND t.price <> s.price THEN UPDATE SET valid_to = s.change_ts, is_current = FALSE;
-- Follow with INSERT for new current row
```

## dbt snapshots

```yaml
snapshots:
  - name: product_snapshot
    strategy: timestamp
    updated_at: updated_at
    unique_key: product_id
```

## Storage considerations

- Index on `(business_key, is_current)`.
- Periodic archive of expired rows to cold storage.
'@

ND "$SHR\02.02.04.01_Fundamentals\02.02.04.01.04_SCD_And_Slowly_Changing\02.02.04.01.04.03_SCD_Type_3_Patterns.md" "SCD Type 3 Implementation Patterns" "02.02.04.01.04" "concept" "scd, type-3" @'
# SCD Type 3 Implementation Patterns

Store **limited prior value** in additional columns (e.g., `previous_price`, `price_change_date`).

## Use cases

- Regulatory need for one prior state only.
- Small dimension where Type 2 row explosion is unacceptable.

## Limitation

Not a substitute for full audit trail — combine with immutable bronze CDC log.
'@

ND "$SHR\02.02.04.01_Fundamentals\02.02.04.01.06_Cross_Mode_Transformation\02.02.04.01.06.01_Cross_Mode_Unified_Models.md" "Cross-Mode Unified Models" "02.02.04.01.06" "concept" "batch, streaming, unified" @'
# Cross-Mode Transformation (Batch + Stream Unified Models)

## Lambda vs Kappa vs unified

| Architecture | Description |
| --- | --- |
| **Lambda** | Batch + speed layer merge |
| **Kappa** | Single stream reprocess for history |
| **Unified (lakehouse)** | Same Delta/Iceberg tables; batch backfill + stream incremental |

## Unified silver table

```mermaid
flowchart TB
  Batch[Batch_MERGE] --> Silver[(Silver_Delta)]
  Stream[Stream_MERGE] --> Silver
  Silver --> Gold[Gold_Marts]
```

## Rules

1. Same MERGE keys and column contracts for batch and stream writers.
2. Batch reconciles stream gaps nightly.
3. Single catalog registration for both paths.
'@

ND "$SHR\02.02.04.04_Architecture_Patterns\02.02.04.04.01_Reference_Architectures\02.02.04.04.01.01_Transformation_Pipeline_Architecture.md" "Transformation Pipeline Architecture" "02.02.04.04.01" "concept" "pipeline, architecture" @'
# Transformation Pipeline Architecture

## Layers

| Stage | Responsibility |
| --- | --- |
| **Ingest handoff** | Bronze landing complete signal |
| **Transform** | Business rules, conform, SCD |
| **Quality** | Tests, quarantine |
| **Publish** | Gold marts, API export |
| **Observe** | Metrics, lineage, cost |

## CI/CD

Git → PR → unit tests → deploy to dev → integration → prod promotion with schema compatibility check.
'@

ND "$SHR\02.02.04.09_Reference_Architectures\02.02.04.09.01_Metadata_Driven_Transform_Platform.md" "Metadata-Driven Transform Platform" "02.02.04.09" "overview" "reference, metadata" @'
# Metadata-Driven Transform Platform Reference

## Concept

Transform definitions stored as **metadata** (YAML/JSON in Git); engine compiles to Spark SQL/dbt at runtime.

```mermaid
flowchart LR
  Meta[Transform_Metadata] --> Compiler[Pipeline_Compiler]
  Compiler --> Spark[Spark_Job]
  Compiler --> dbt[dbt_Models]
  Spark --> Lake[(Lakehouse)]
  dbt --> Lake
```

## Components

- **Registry** — entity/attribute business glossary.
- **Rules engine** — mapping source → target columns.
- **Lineage** — automatic from metadata graph.
- **Orchestrator** — executes compiled artifacts.

## Benefits

- Reduce copy-paste across domains.
- Enforce naming and DQ standards centrally.
'@

Replace-ProblemStatementFiles (Join-Path $Base "$SHR\02.02.04.01_Fundamentals") "shared foundations"

Write-Host "Phase 6 complete."

# ========== Phase 7: Enhance learning guide stubs (.03-.09) ==========
Write-Host "Phase 7: Enhance learning guide modules"

function Get-RichLearningModule($guideName, $modNum, $modName, $section, $mode, $docsUrl) {
    $hnum = [int]$modNum
    $label = $modName.Replace('_', ' ')
    $title = "$guideName $label"
    $F = '```'
    $jobSlug = ($guideName -replace '\s+', '_')
    $body = switch ($modNum) {
        "03" { @"
# $hnum. $title

## Prerequisites

- Cloud/project access with transform admin role
- Source and sink endpoints provisioned
- Git repo or artifact store for pipeline code

## Setup workflow

| Step | Action |
| ---: | --- |
| 1 | Create service account / IAM role with least privilege |
| 2 | Configure network (VPC peering / private endpoints) |
| 3 | Author transform in dev environment |
| 4 | Unit test on sample partition |
| 5 | Deploy via CI/CD to staging |
| 6 | Soak test with production-like volume |
| 7 | Promote to prod with rollback tag |

## IAM checklist ($guideName)

| Permission | Purpose |
| --- | --- |
| Read source | Input datasets/topics |
| Write sink | Curated output tables/files |
| Secrets | API keys, JDBC passwords |
| Logging | Metrics and audit trail |

## CLI / code example

${F}bash
# Deploy transform job (adapt per platform)
export TRANSFORM_ENV=prod
./deploy.sh --job ${jobSlug}_silver_merge
$F

${F}python
# Incremental transform skeleton
def transform_batch(df):
    return df.filter("status IS NOT NULL").dropDuplicates(["id"])
$F

## Deployment pipeline

${F}mermaid
flowchart LR
  Dev[Dev] --> CI[CI_Tests]
  CI --> Stg[Staging]
  Stg --> Prod[Production]
$F

## Testing

- **Unit** - pure functions on fixture DataFrames.
- **Integration** - write to temp schema, assert row counts.
- **Regression** - compare checksum vs golden partition.

## Operate

- Monitor runtime, shuffle spill, failed records.
- Alert when duration > 2x baseline.
- Document backfill: same MERGE logic, wider partition filter.
- Run weekly cost review against budget tags.
- Rotate credentials via secrets manager every 90 days.
- Keep runbook for rollback to prior artifact version in Git tag.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Job timeout | Skew / too much shuffle | Repartition, salting |
| Auth failure | Expired SA key | Rotate secret |
| Empty output | Wrong filter predicate | Validate staging row counts |
| Duplicate rows | Missing dedup key | Add MERGE on business key |

## Related

- [Overview](README.md)
- [Official documentation]($docsUrl)
"@
        }
        "04" { @"
# $hnum. $title

## Enterprise medallion scenario

${F}mermaid
flowchart TB
  Bronze[Bronze_Raw] --> Silver[Silver_Conformed]
  Silver --> Gold[Gold_Marts]
$F

| Layer | $guideName role |
| --- | --- |
| Bronze | Land raw with minimal validation |
| Silver | Dedup, conform types, apply business keys |
| Gold | Aggregates and KPI tables for BI |

## SCD scenario

- **Type 1** — overwrite attributes on match.
- **Type 2** — close current row, insert new version.
- Use CDC stream or nightly staging diff.

## CDC scenario

${F}mermaid
sequenceDiagram
  participant DB as Source_DB
  participant CDC as CDC_Reader
  participant T as $guideName
  participant Lake as Silver_Table
  DB->>CDC: Change events
  CDC->>T: Stream/batch
  T->>Lake: MERGE
$F

## Conformed dimensions

Shared `dim_date`, `dim_customer` built once; fact tables reference surrogate keys.

## Enterprise pattern checklist

- [ ] Business keys documented
- [ ] Quarantine path for bad records
- [ ] Lineage registered in catalog
- [ ] Cost tag per domain

## Related

- [Medallion Implementation](../../../02.02.04_Shared_Foundations/02.02.04.01_Fundamentals/02.02.04.01.03_Medallion_And_Zones/02.02.04.01.03.01_Medallion_Implementation.md)
"@
        }
        "05" { @"
# $hnum. $title - Limitations and Anti-Patterns

## Platform quotas (verify current docs)

| Limit | Typical impact |
| --- | --- |
| Max workers / DPUs | Caps throughput |
| API rate limits | Throttles deploy frequency |
| State / shuffle size | OOM or spill |
| Concurrent jobs | Queue latency |

## When **not** to use $guideName

- Sub-second complex event processing → dedicated Flink cluster.
- Simple one-table SQL in warehouse → native dbt/SQL only.
- Tiny datasets (< 1 GB) → over-engineering cost.

## Anti-patterns

| Anti-pattern | Why it fails |
| --- | --- |
| Full scan every micro-batch | Cost explosion |
| No checkpoint on stream job | Unrecoverable duplicates |
| Shared prod/dev credentials | Security audit failure |
| Schema drift without contract | Silent data corruption |

## Mitigations

- Partition pruning and incremental reads.
- Right-size trigger interval vs SLA.
- Schema registry + compatibility checks.

## Related

- [Production Configuration](README.md)
"@
        }
        "06" { @"
# $hnum. $title

## Pricing model

| Component | Billing unit |
| --- | --- |
| Compute | vCPU-hour / DPU / slot-second |
| Storage | GB-month for checkpoints and temp |
| Network | Egress cross-AZ/region |
| Licensing | Enterprise support (if applicable) |

## TCO scenarios (indicative)

| Scenario | Monthly volume | Est. relative cost |
| --- | --- | --- |
| **Small** | 100 GB transform/day | \$ |
| **Medium** | 2 TB/day, 15m NRT | \$\$ |
| **Large** | 20 TB/day, streaming | \$\$\$ |

## Cost optimization

1. Use preemptible/Flex workers for batch tiers.
2. Compress shuffle and enable predicate pushdown.
3. Schedule heavy jobs off-peak.
4. Archive cold checkpoints and logs.

## FinOps checklist

- [ ] Tag jobs by cost center
- [ ] Budget alerts at 80/100%
- [ ] Monthly review of top 10 expensive jobs

## Related

- [Official pricing]($docsUrl)
"@
        }
        "07" { @"
# $hnum. $title

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
| Freshness lag | > 2× SLA |
| Error rate | > 0.1% records |
| Duration | > p99 baseline |

## SLA template

```
Availability: 99.9% monthly
Freshness: ___ minutes p99
Recovery: ___ minutes RTO
```

## Related

- [Learning guide README](README.md)
"@
        }
        "08" { @"
# $hnum. $title

## Scorecard vs peers

| Criterion | Weight | $guideName | Peer A | Peer B |
| --- | ---: | --- | --- | --- |
| Ease of ops | 20% | | | |
| Streaming fit | 20% | | | |
| Batch fit | 15% | | | |
| Ecosystem | 15% | | | |
| Cost efficiency | 15% | | | |
| Portability | 15% | | | |

## Scoring guide

- **5** — Best in class for enterprise $mode
- **3** — Viable with trade-offs
- **1** — Poor fit; consider alternative

## Decision workflow

1. Weight criteria for your workload profile.
2. Score top 3 candidates with PoC metrics.
3. Document ADR with 12-month TCO estimate.

## Related

- [Overview](README.md)
"@
        }
        "09" { @"
# $hnum. $title

## Reference workloads

| ID | Profile | Input | Expected metrics |
| ---: | --- | --- | --- |
| W1 | Smoke | 1 GB parquet | < 5 min, 0 failures |
| W2 | Standard batch | 100 GB, 50 cols | < 45 min on baseline cluster |
| W3 | Wide join | 2 TB fact + dim | Shuffle < 500 GB |
| W4 | Streaming | 5K evt/s | p99 lag < 30s |
| W5 | CDC MERGE | 1M rows/day delta | < 10 min micro-batch |
| W6 | Backfill | 90-day partition | Completes < 4 hr |
| W7 | Skewed key | 80/20 key distribution | No single task > 2× median |
| W8 | Schema evolve | Add 5 columns | No full rewrite |
| W9 | Failure recovery | Kill worker mid-job | Checkpoint recovery < 5 min |
| W10 | Cost soak | 24h continuous | Cost within budget ±10% |

## Benchmark environment

- Document engine version, worker type, count, region.
- Run 3 iterations; report median and p99.
- Store results in benchmark registry Git repo.

## Reporting template

```
Guide: $guideName
Date: $Today
Workload: W__
Duration: __  Cost: $__
Throughput: __ GB/hr  Lag p99: __s
Notes: __
```

## Related

- [Benchmarks section](../../02.02.01.05_Benchmarks/README.md)
"@
        }
        default { "# $title`n`nExpert content for $guideName." }
    }
    return (Get-FM $title $section $(if ($modNum -in @("06","08","09")) { "evaluation" } else { "concept" }) "$mode, learning-guide") + $body
}

$guideDirs = [System.Collections.ArrayList]@()
$stack = New-Object System.Collections.Stack
[void]$stack.Push($Base)
while ($stack.Count -gt 0) {
    $dir = [string]$stack.Pop()
    try {
        foreach ($d in [IO.Directory]::EnumerateDirectories((Get-LongPath $dir))) {
            $name = Split-Path (Strip-LongPath $d) -Leaf
            if ($name -like '*Learning_Guide*') {
                [void]$guideDirs.Add((Strip-LongPath $d))
            } else {
                [void]$stack.Push((Strip-LongPath $d))
            }
        }
    } catch { }
}
$enhanced = 0
foreach ($gdPath in $guideDirs) {
    $gdName = Split-Path $gdPath -Leaf
    $guideName = ($gdName -replace '_Learning_Guide','') -replace '_',' '
    $files = @()
    try {
        $files = [IO.Directory]::EnumerateFiles((Get-LongPath $gdPath), "*.md") |
            Where-Object { $_ -match '\.(03|04|05|06|07|08|09)_' -and $_ -notmatch 'README\.md$' }
    } catch { continue }
    foreach ($f in $files) {
        try {
            $longPath = Get-LongPath (Strip-LongPath $f)
            if (-not [IO.File]::Exists($longPath)) { continue }
            $raw = [IO.File]::ReadAllText($longPath, $utf8)
            $lines = ($raw -split "`n").Count
            $isStub = $raw -match 'Expert guidance for \*\*'
            $needsFenceFix = $raw -match '``bash'
            if (-not $isStub -and -not $needsFenceFix -and $lines -ge 80) { continue }
            $modMatch = [regex]::Match([IO.Path]::GetFileName((Strip-LongPath $f)), '\.(\d{2})_(How_To_Use|Scenarios|Limitations_And_Scenarios|Costing|Production_Configuration|Evaluation_Criteria|Benchmarking)')
            if (-not $modMatch.Success) { continue }
            $modNum = $modMatch.Groups[1].Value
            $modName = $modMatch.Groups[2].Value
            $secMatch = [regex]::Match($raw, 'section:\s*"([^"]+)"')
            $section = if ($secMatch.Success) { $secMatch.Groups[1].Value } else { "02.02" }
            $mode = if ($gdPath -match 'Streaming') { "streaming transformation" } elseif ($gdPath -match 'Batch') { "batch transformation" } else { "transformation" }
            $docsUrl = "https://docs.example.com"
            if ($raw -match 'official documentation\]?\(([^)]+)\)') { $docsUrl = $Matches[1] }
            $content = Get-RichLearningModule $guideName $modNum $modName $section $mode $docsUrl
            Write-Doc (Strip-LongPath $f) $content
            $enhanced++
        } catch {
            [void]$Stats.Errors.Add("Phase7 $(Strip-LongPath $f): $_")
        }
    }
}
Write-Host "  Enhanced $enhanced learning guide modules"

# ========== Summary ==========
Write-Host ""
Write-Host "========== FILL 02.02 COMPLETE =========="
Write-Host "Files created: $($Stats.Created)"
Write-Host "Files updated: $($Stats.Updated)"
Write-Host "Total written: $($Stats.Created + $Stats.Updated)"
if ($Stats.Errors.Count -gt 0) {
    Write-Host "Errors ($($Stats.Errors.Count)):"
    $Stats.Errors | ForEach-Object { Write-Host "  $_" }
}

# Sample verification
$nrtSample = Join-Path $Base "$NRT\02.02.03.01_Fundamentals\02.02.03.01.01_Strategy\02.02.03.01.01.01_NRT_Transformation_Strategy.md"
$lgSample = Get-ChildItem $Base -Recurse -Filter "*Learning_Guide*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 |
    ForEach-Object { Get-ChildItem $_.FullName -Filter "*.03_How_To_Use.md" -ErrorAction SilentlyContinue | Select-Object -First 1 }
if (Test-Path $nrtSample) {
    $nrtLines = (Get-Content $nrtSample).Count
    Write-Host "NRT sample ($nrtLines lines): $nrtSample"
}
if ($lgSample) {
    $lgLines = (Get-Content $lgSample.FullName).Count
    Write-Host "Learning guide sample ($lgLines lines): $($lgSample.FullName)"
}
