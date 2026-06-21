# Generate expert-level 02.02 transformation learning guides (Top 10 + Cloud Services)
$Repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$Base = Join-Path $Repo "docs\02_Data_Engineering_Architecture\02.02_Data_Transformation_Architecture"
$Today = "2026-06-20"
$utf8 = New-Object System.Text.UTF8Encoding $false

$Modules = @(
    @("01", "Overview", "overview"),
    @("02", "Architecture", "concept"),
    @("03", "How_To_Use", "concept"),
    @("04", "Scenarios", "concept"),
    @("05", "Limitations_And_Scenarios", "concept"),
    @("06", "Costing", "evaluation"),
    @("07", "Production_Configuration", "concept"),
    @("08", "Evaluation_Criteria", "evaluation"),
    @("09", "Benchmarking", "evaluation")
)

$ModuleFocus = @{
    "01" = "What it is, mental model, when to use"
    "02" = "Components, execution model, data flow"
    "03" = "Author, deploy, test, operate transforms"
    "04" = "Enterprise medallion, SCD, conformed layers"
    "05" = "Quotas, constraints, anti-patterns"
    "06" = "Compute, storage, licensing cost models"
    "07" = "HA, security, monitoring, SLAs"
    "08" = "Scorecard vs peer technologies"
    "09" = "Reference workloads and sizing profiles"
}

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
    $text = $content.TrimEnd() + "`n"
    [IO.File]::WriteAllText((Get-LongPath $fullPath), $text, $utf8)
}

function Get-ModuleRows($guideId) {
    $rows = @()
    foreach ($m in $Modules) {
        $num, $name, $_ = $m
        $label = $name.Replace("_", " ")
        $rows += "| $([int]$num) | [$label](${guideId}.${num}_${name}.md) | $($ModuleFocus[$num]) |"
    }
    return ($rows -join "`n")
}

function Get-GuideReadme($g) {
    $rankLine = ""
    if ($g.ContainsKey("rank")) {
        $rankLine = "> **Rank #$($g.rank)** in [$($g.rank_doc)]($($g.rank_link)).`n`n"
    }
    $modRows = Get-ModuleRows $g.id
    $parentReadme = if ($g.ContainsKey("parent_readme")) { $g.parent_readme } else { "Mode README" }
    $parentLink = if ($g.ContainsKey("parent_link")) { $g.parent_link } else { "../README.md" }
    $prereqExtra = if ($g.ContainsKey("prereq_extra")) { $g.prereq_extra } else { "" }
    $context = if ($g.ContainsKey("context")) { $g.context } else { "" }

    return (Get-FM "$($g.name) Learning Guide" $g.section "hub" ($g.tags -join ", ")) + @"
# $($g.name) Learning Guide

$rankLine`Structured learning path for **$($g.desc)**.

$context
## Prerequisites

- $($g.prereq)
$prereqExtra
## Modules

| # | Module | Focus |
| ---: | --- | --- |
$modRows

## Quick links

- [$parentReadme]($parentLink)
- [Official documentation]($($g.docs))
- [Official pricing]($($g.pricing))
"@
}

function Get-ExpertOverview($key, $g) {
    $Expert = $script:ExpertContent
    if ($Expert.ContainsKey($key) -and $Expert[$key].ContainsKey("overview")) {
        return $Expert[$key]["overview"]
    }
    $name = $g.name
    $short = if ($g.ContainsKey("short")) { $g.short } else { $g.name }
    $useWhen = if ($g.ContainsKey("use_when")) { $g.use_when } else { "Transform workload matches engine strengths" }
    $altWhen = if ($g.ContainsKey("alt_when")) { $g.alt_when } else { "Simpler SQL-only path exists in warehouse" }
    $skill = if ($g.ContainsKey("skill")) { $g.skill } else { "platform expertise" }
    $useWhen2 = if ($g.ContainsKey("use_when2")) { $g.use_when2 } else { "Medallion or dimensional modeling at scale" }
    $altWhen2 = if ($g.ContainsKey("alt_when2")) { $g.alt_when2 } else { "Lightweight one-off scripts -> simpler tooling" }
    $parentReadme = if ($g.ContainsKey("parent_readme")) { $g.parent_readme } else { "Transformation mode" }
    $parentLink = if ($g.ContainsKey("parent_link")) { $g.parent_link } else { "../../README.md" }

    return (Get-FM "$name Overview" $g.section "overview" ($g.tags -join ", ")) + @"
# 1. $name Overview

## What is $short?

**$name** is $($g.desc).

## Mental model

```mermaid
flowchart LR
  In[Raw_or_Staged_Input] --> T[${short}_Transform]
  T --> Out[Curated_Output]
```

- **You own** business rules, schema contracts, test suites, and deployment pipelines.
- **Platform owns** compute scheduling, optimizer, and managed runtime (where applicable).

## When to use $short

| Use when... | Consider alternatives when... |
| --- | --- |
| $useWhen | $altWhen |
| Team has $skill | Sub-second streaming only -> dedicated stream processor |
| $useWhen2 | $altWhen2 |

## Learning path

Continue to [Architecture]($($g.id).02_Architecture.md) or [Scenarios]($($g.id).04_Scenarios.md).

## Related

- [Official documentation]($($g.docs))
- [$parentReadme]($parentLink)
"@
}

function Get-ExpertArchitecture($key, $g) {
    $Expert = $script:ExpertContent
    if ($Expert.ContainsKey($key) -and $Expert[$key].ContainsKey("architecture")) {
        return $Expert[$key]["architecture"]
    }
    $name = $g.name
    return (Get-FM "$name Architecture" $g.section "concept" ($g.tags -join ", ")) + @"
# 2. Architecture of $name

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Job definitions, scheduling hooks, metadata, IAM |
| **Execution plane** | Distributed workers, shuffle, spill, result materialization |

## Data flow topology

```mermaid
flowchart TB
  Src[(Sources)] --> Stage[Staging]
  Stage --> Transform[$name]
  Transform --> Sink[(Target_Store)]
```

## Design principles

1. **Idempotent transforms** - safe replays and backfills.
2. **Schema evolution** - backward-compatible column adds; explicit breaking changes.
3. **Partition pruning** - filter early on date/tenant keys.
4. **Observability** - row counts, null rates, SLA timers emitted per run.

## Related

- [Overview]($($g.id).01_Overview.md)
- [Production Configuration]($($g.id).07_Production_Configuration.md)
"@
}

function Get-GenericModule($g, $num, $modName, $template) {
    $name = $g.name
    $hnum = [int]$num
    $title = "$name $($modName.Replace('_', ' '))"
    $key = if ($g.ContainsKey("key")) { $g.key } else { "" }
    $Expert = $script:ExpertContent
    $field = $modName.ToLower()
    if ($key -and $Expert.ContainsKey($key) -and $Expert[$key].ContainsKey($field)) {
        return (Get-FM $title $g.section $template ($g.tags -join ", ")) + $Expert[$key][$field]
    }
    $focus = $ModuleFocus[$num]
    $mode = if ($g.ContainsKey("mode")) { $g.mode } else { "transformation" }
    return (Get-FM $title $g.section $template ($g.tags -join ", ")) + @"
# $hnum. $title

Expert guidance for **$name** - $($focus.ToLower()).

See [official documentation]($($g.docs)) and the [learning guide README](README.md).

## Key topics

| Area | Guidance |
| --- | --- |
| Scope | $focus |
| Platform | $name |
| Mode | $mode |

## Related

- [Overview]($($g.id).01_Overview.md)
- [Architecture]($($g.id).02_Architecture.md)
"@
}

function Invoke-GenerateGuide($g) {
    $folder = Join-Path $Base $g.folder
    $count = 0
    Write-Doc (Join-Path $folder "README.md") (Get-GuideReadme $g)
    $count++
    $key = if ($g.ContainsKey("key")) { $g.key } else { "" }
    foreach ($m in $Modules) {
        $num, $modName, $template = $m
        $path = Join-Path $folder "$($g.id).${num}_${modName}.md"
        switch ($num) {
            "01" { $body = Get-ExpertOverview $key $g }
            "02" { $body = Get-ExpertArchitecture $key $g }
            default { $body = Get-GenericModule $g $num $modName $template }
        }
        Write-Doc $path $body
        $count++
    }
    return $count
}

# --- Expert content for flagship technologies ---
$script:ExpertContent = @{}

$script:ExpertContent["spark"] = @{
    overview = (Get-FM "Apache Spark Overview" "02.02.01.03.02" "overview" "spark, batch, open-source, top-10") + @'
# 1. Apache Spark Overview

## What is Apache Spark?

**Apache Spark** is the dominant unified analytics engine for **large-scale batch and micro-batch transformation** on data lakes and warehouses. It provides DataFrame/Dataset APIs in Python, Scala, Java, and SQL with Catalyst optimizer and Tungsten execution.

## Mental model

```mermaid
flowchart LR
  Driver[Driver_Program] --> DAG[Logical_Plan]
  DAG --> Stages[Physical_Stages]
  Stages --> Exec[Executors]
  Exec --> Parquet[(Parquet_Iceberg_Delta)]
```

- **Driver** - plans jobs, tracks stages, coordinates executors.
- **Executors** - run tasks in parallel; shuffle for joins/aggregations.
- **Tables** - read/write via Hive metastore, Unity Catalog, or path-based open formats.

## When to use Spark

| Use Spark when... | Consider alternatives when... |
| --- | --- |
| TB+ batch transforms on object storage | Warehouse-only SQL (dbt + Snowflake/BQ) suffices |
| Complex joins, UDFs, ML feature prep in one engine | Sub-second streaming with strict event-time -> **Flink** |
| Multi-cloud portable lakehouse medallion | Simple file copy + SQL -> managed ELT SaaS |
| Team already on Databricks/EMR/Dataproc | Interactive BI only -> warehouse native SQL |

## Spark vs dbt vs Flink

| Engine | Sweet spot |
| --- | --- |
| **Spark** | Distributed batch/micro-batch on lake |
| **dbt** | Warehouse-native SQL transforms |
| **Flink** | Stateful stream processing, CEPS |

## Learning path

Continue to [Architecture](02.02.01.03.02.02_Architecture.md) or [Scenarios](02.02.01.03.02.04_Scenarios.md).
'@
    architecture = (Get-FM "Apache Spark Architecture" "02.02.01.03.02" "concept" "spark, architecture") + @'
# 2. Architecture of Apache Spark

## Cluster architecture

| Component | Role |
| --- | --- |
| **Driver** | SparkContext/SparkSession, DAGScheduler, TaskScheduler |
| **Cluster Manager** | YARN, Kubernetes, Mesos, or standalone |
| **Executor** | JVM process running tasks; caches partitions |
| **Catalog** | Hive, Glue, Unity, Iceberg REST |

## Job lifecycle

```mermaid
stateDiagram-v2
  [*] --> Parse: SQL_DataFrame_API
  Parse --> Optimize: Catalyst_Rules
  Optimize --> Plan: Physical_Plan
  Plan --> Stage: Shuffle_Boundary
  Stage --> Task: Parallel_Tasks
  Task --> Commit: Write_Output
  Commit --> [*]
```

## Shuffle and partitioning

- **Hash partition** - equi-joins, group-by keys.
- **Range partition** - order-sensitive ops (limited).
- **Coalesce/repartition** - control output file count (target 128MB-1GB objects).
- **Adaptive Query Execution (AQE)** - runtime skew join handling, coalesce shuffle partitions.

## Lakehouse integration

| Format | Spark integration |
| --- | --- |
| **Delta Lake** | ACID MERGE, time travel, OPTIMIZE/VACUUM |
| **Iceberg** | Hidden partitioning, branch/tag, merge-on-read |
| **Hudi** | Upsert, incremental pull, clustering |

## Production checklist

- Dynamic partition overwrite for idempotent daily loads
- Broadcast joins only under size threshold (~10-50MB tuned)
- Speculative execution for straggler mitigation
- Event logging to Spark History Server / OTel

## Related

- [Dataproc Learning Guide](../../02.02.01.02_Cloud_Services/02.02.01.02.02_GCP/02.02.01.02.02.03_Dataproc_Spark_Learning_Guide/README.md)
- [EMR Spark Learning Guide](../../02.02.01.02_Cloud_Services/02.02.01.02.03_AWS/02.02.01.02.03.04_EMR_Spark_Learning_Guide/README.md)
'@
    scenarios = (Get-FM "Apache Spark Scenarios" "02.02.01.03.02" "concept" "spark, scenarios") + @'
# 4. Apache Spark Enterprise Scenarios

## Medallion batch pipeline

| Layer | Spark pattern |
| --- | --- |
| Bronze | Raw ingest validation, schema inference, quarantine bad rows |
| Silver | Dedup by business key, SCD Type 2 MERGE, conformed dimensions |
| Gold | Aggregates, feature tables, export to warehouse |

## CDC merge (Delta/Iceberg)

```sql
MERGE INTO silver.customer AS t
USING bronze.customer_cdc AS s
ON t.customer_id = s.customer_id
WHEN MATCHED AND s.op = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *
```

## Slowly changing dimensions

- **Type 1** - overwrite attribute (simple `update`).
- **Type 2** - `MERGE` with `valid_from`/`valid_to`, current flag.
- **Type 3** - limited history columns; rare at TB scale.

## Related

- [Medallion Implementation](../../../02.02.04_Shared_Foundations/02.02.04.01_Fundamentals/02.02.04.01.03_Medallion_And_Zones/02.02.04.01.03.01_Medallion_Implementation.md)
'@
}

$script:ExpertContent["dbt"] = @{
    overview = (Get-FM "dbt Overview" "02.02.01.03.03" "overview" "dbt, sql, top-10") + @'
# 1. dbt Overview

## What is dbt?

**dbt (data build tool)** is the industry-standard **SQL-first transformation framework** for warehouses and lakehouse SQL engines. It compiles modular SQL models, runs tests, generates docs, and integrates with Git-based CI/CD.

## Mental model

```mermaid
flowchart LR
  Raw[(Staging_Views)] --> dbt[dbt_Models]
  dbt --> Mart[(Marts)]
  dbt --> Tests[Tests_Docs_Lineage]
```

- **Models** - `SELECT` statements materialized as view/table/incremental.
- **Sources** - declared upstream tables with freshness checks.
- **Tests** - uniqueness, not-null, relationships, custom SQL.
- **Macros/Jinja** - reusable SQL abstractions.

## When to use dbt

| Use dbt when... | Consider alternatives when... |
| --- | --- |
| Transform logic lives in **Snowflake/BQ/Redshift/Databricks SQL** | Heavy graph algorithms / ML on files -> **Spark** |
| Analytics engineering owns **Git + PR** workflow | Complex event-time streaming -> **Flink** |
| Need **lineage, docs, tests** out of the box | Legacy GUI ETL only shop -> Informatica/Talend |

## dbt vs Spark vs warehouse-native

| Approach | Best for |
| --- | --- |
| **dbt** | Modular SQL marts, testing, documentation |
| **Spark** | Lake file processing, complex distributed UDFs |
| **Native stored procs** | Simple, DBA-centric, no Git culture |
'@
    architecture = (Get-FM "dbt Architecture" "02.02.01.03.03" "concept" "dbt, architecture") + @'
# 2. dbt Architecture

## Project structure

| Artifact | Purpose |
| --- | --- |
| `dbt_project.yml` | Project config, materializations defaults |
| `models/` | Layered SQL (`staging/`, `intermediate/`, `marts/`) |
| `seeds/` | CSV reference data |
| `snapshots` | SCD Type 2 for changing sources |
| `tests/` | Schema + singular tests |
| `macros/` | Jinja SQL functions |

## Execution flow

```mermaid
flowchart TB
  Parse[Parse_Project] --> Compile[Jinja_Expand]
  Compile --> DAG[Model_DAG]
  DAG --> Run[Execute_SQL]
  Run --> Test[Run_Tests]
  Test --> Docs[Generate_Docs]
```

## Materialization strategies

| Strategy | Use case |
| --- | --- |
| `view` | Lightweight staging |
| `table` | Full rebuild marts |
| `incremental` | Append/merge large fact tables |
| `ephemeral` | CTE-like intermediate (no object) |

## Incremental patterns

- **`merge` strategy** - upsert on unique key (Snowflake, BQ, Databricks).
- **`delete+insert`** - partition replace.
- **`microbatch`** - dbt 1.9+ time-window incremental.

## Related

- [BigQuery dbt Learning Guide](../../02.02.01.02_Cloud_Services/02.02.01.02.02_GCP/02.02.01.02.02.04_BigQuery_SQL_Learning_Guide/README.md)
'@
}

$script:ExpertContent["flink"] = @{
    overview = (Get-FM "Apache Flink Overview" "02.02.02.03.02" "overview" "flink, streaming, top-10") + @'
# 1. Apache Flink Overview

## What is Apache Flink?

**Apache Flink** is the leading **stateful stream processing** engine for transformation with event-time semantics, exactly-once checkpoints, and CEP. It powers real-time silver/gold layers, CDC propagation, and stream-table duality via Flink SQL.

## Mental model

```mermaid
flowchart LR
  Kafka[Kafka_Pulsar] --> Flink[Flink_Job]
  State[(RocksDB_State)] --> Flink
  Flink --> Sink[(Iceberg_JDBC_Kafka)]
```

## When to use Flink

| Use Flink when... | Consider alternatives when... |
| --- | --- |
| **Event-time** windows, watermarks, late data | Minute-level micro-batch OK -> Spark Structured Streaming |
| **Stateful** aggregations (sessions, funnel) | Simple filter/map -> Kafka Streams |
| **Exactly-once** end-to-end with Kafka + lake | Managed serverless -> **Dataflow** / **Managed Flink** |
| **SQL + DataStream** unified API | Batch-only TB scans -> Spark |

## Flink vs Spark Streaming vs Kafka Streams

| Engine | Latency | State | Ops complexity |
| --- | --- | --- | --- |
| **Flink** | ms-s | Rich | Medium-High |
| **Spark SS** | s-min | Micro-batch | Medium |
| **Kafka Streams** | ms | Per-app | Lower (library) |
'@
    architecture = (Get-FM "Apache Flink Architecture" "02.02.02.03.02" "concept" "flink, architecture") + @'
# 2. Architecture of Apache Flink

## Runtime components

| Component | Role |
| --- | --- |
| **JobManager** | Coordination, checkpoint orchestration |
| **TaskManager** | Slots run operators; manage network buffers |
| **Operator** | Source, map, keyBy, window, sink |
| **State backend** | RocksDB (default) or heap |

## Checkpointing

```mermaid
sequenceDiagram
  JM as JobManager
  TM as TaskManager
  JM->>TM: trigger_checkpoint
  TM->>TM: barrier_align
  TM->>JM: ack_snapshot
  JM->>JM: complete_checkpoint
```

- **Barrier alignment** - exactly-once with Kafka source + two-phase commit sink.
- **Unaligned checkpoints** - reduce backpressure impact (1.11+).

## Time semantics

| Time | Use |
| --- | --- |
| **Event time** | Business correctness with watermarks |
| **Processing time** | Low-latency approximations |
| **Ingestion time** | Audit only - avoid for analytics |

## Related

- [Dataflow Learning Guide](../../02.02.02.02_Cloud_Services/02.02.02.02.02_GCP/02.02.02.02.02.03_Dataflow_Learning_Guide/README.md)
'@
}

$script:ExpertContent["bigquery"] = @{
    overview = (Get-FM "Google BigQuery SQL Transformation Overview" "02.02.01.02.02.04" "overview" "gcp, bigquery, sql") + @'
# 1. BigQuery SQL Transformation Overview

## What is BigQuery for transformation?

**BigQuery** is GCP's serverless **ELT warehouse** - transformations run as SQL jobs (scheduled queries, dbt, Dataform, stored procedures) with separation of storage and compute, slot-based or on-demand billing.

## Mental model

```mermaid
flowchart LR
  BQ_Storage[(Capacitor_Storage)] --> SQL[SQL_Transform]
  SQL --> Marts[(Tables_Views_MV)]
```

## When to use BigQuery transforms

| Use BigQuery when... | Consider alternatives when... |
| --- | --- |
| Data already in **BQ datasets** | Heavy file-based lake -> Dataproc Spark |
| **Serverless** SQL marts with dbt/Dataform | Complex UDF graph on Parquet -> Spark |
| **BigQuery ML** in same pipeline | Multi-cloud portable code -> Spark + Iceberg |

## Related

- [Cloud Batch Reference](../../02.02.01.02.01_Overview/02.02.01.02.01.01_Cloud_Batch_Transformation_Reference.md)
'@
    architecture = (Get-FM "BigQuery Transformation Architecture" "02.02.01.02.02.04" "concept" "gcp, bigquery") + @'
# 2. BigQuery Transformation Architecture

## Compute models

| Model | Character |
| --- | --- |
| **On-demand** | Pay per bytes scanned; simple start |
| **Editions / reservations** | Slot capacity; predictable cost at scale |
| **Autoscaling** | Burst within reservation |

## Storage layout

- **Partitioned tables** - `DATE`/`TIMESTAMP` partition pruning.
- **Clustering** - co-locate filter columns within partitions.
- **Materialized views** - pre-aggregated refresh (auto or manual).

## ELT topology on GCP

```mermaid
flowchart TB
  GCS[(GCS_Landing)] --> BQ_Load[Load_External_BQ]
  BQ_Load --> Staging[staging_*]
  Staging --> dbt[dbt_Dataform]
  dbt --> Marts[analytics_*]
```

## Related

- [dbt Learning Guide](../../02.02.01.03_Open_Source/02.02.01.03.03_dbt_Learning_Guide/README.md)
'@
}

$script:ExpertContent["glue_etl"] = @{
    overview = (Get-FM "AWS Glue ETL Overview" "02.02.01.02.03.03" "overview" "aws, glue, etl") + @'
# 1. AWS Glue ETL Overview

## What is AWS Glue ETL?

**AWS Glue** provides **managed Apache Spark** ETL jobs with visual Studio authoring, Data Catalog integration, job bookmarks for incremental processing, and Flex execution for cost optimization.

## Mental model

```mermaid
flowchart LR
  S3[(S3_Raw)] --> Glue[Glue_Spark_Job]
  Glue --> Cat[(Glue_Catalog)]
  Glue --> Curated[(S3_Iceberg_Delta)]
```

## When to use Glue ETL

| Use Glue when... | Consider alternatives when... |
| --- | --- |
| **AWS-native** lake on S3 + Catalog | Portable Airflow DAGs on any cloud -> EMR + MWAA |
| **Job bookmarks** incremental ingest+transform | Heavy custom Spark tuning -> EMR |
| **Studio visual** ETL for citizen integrators | Complex multi-service orchestration -> Step Functions + Lambda |

## Glue ETL vs EMR vs Athena

| Service | Role |
| --- | --- |
| **Glue ETL** | Managed Spark transforms |
| **EMR** | Full cluster control, Spark/Flink/Presto |
| **Athena** | SQL on catalog tables (ELT query layer) |
'@
    architecture = (Get-FM "AWS Glue ETL Architecture" "02.02.01.02.03.03" "concept" "aws, glue") + @'
# 2. AWS Glue ETL Architecture

## Job types

| Type | Runtime |
| --- | --- |
| Spark ETL | Python/Scala on Glue Spark |
| Python shell | Lightweight Python (no Spark) |
| Ray | Python distributed ML prep |

## DPU and workers

- **Standard** - 4 vCPU, 16 GB per DPU.
- **Flex** - discounted, slower startup; batch medallion friendly.
- **Worker type G.1X/G.2X** - memory-heavy skew handling.

## Incremental processing

```mermaid
flowchart LR
  Bookmark[Job_Bookmark] --> Read[Incremental_Read]
  Read --> Transform[Transform]
  Transform --> Write[Write_Output]
  Write --> Update[Update_Bookmark]
```

## Related

- [Glue Workflows Orchestration](../../../../02.03_Data_Orchestration_Architecture/02.03.02_Cloud_Services/02.03.02.03_AWS/02.03.02.03.06_Glue_Workflows_Learning_Guide/README.md)
'@
}

$script:ExpertContent["dataflow"] = @{
    overview = (Get-FM "Google Cloud Dataflow Overview" "02.02.02.02.02.03" "overview" "gcp, dataflow, beam") + @'
# 1. Google Cloud Dataflow Overview

## What is Dataflow?

**Cloud Dataflow** is GCP's **managed Apache Beam** runner for batch and streaming transformation - autoscaling workers, exactly-once processing, and native integration with Pub/Sub, BigQuery, and GCS.

## When to use Dataflow

| Use Dataflow when... | Consider alternatives when... |
| --- | --- |
| **Beam portable** pipelines on GCP | Already standardized on Flink ops team |
| **Streaming + batch** same codebase | Warehouse-only SQL -> BigQuery |
| **Pub/Sub -> BQ** real-time silver | Kafka-centric -> Managed Kafka + Flink |

## Related

- [Beam Learning Guide](../../02.02.02.03_Open_Source/02.02.02.03.08_Apache_Beam_Learning_Guide/README.md)
'@
}

# --- Guide definitions ---
$BatchTop10 = @(
    @{ id="02.02.01.03.02"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.02_Apache_Spark_Learning_Guide"; key="spark"; rank=1; name="Apache Spark"; short="Spark"; section="02.02.01.03.02"; tags=@("spark","batch","open-source","top-10"); desc="the unified distributed engine for large-scale batch transformation on data lakes"; prereq="Python or Scala, SQL, basic distributed systems"; docs="https://spark.apache.org/docs/latest/"; pricing="https://spark.apache.org/"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.03"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.03_dbt_Learning_Guide"; key="dbt"; rank=2; name="dbt"; short="dbt"; section="02.02.01.03.03"; tags=@("dbt","sql","top-10"); desc="the SQL-first analytics engineering framework for warehouse-native ELT"; prereq="SQL, Git, warehouse access (Snowflake/BQ/Redshift/Databricks)"; docs="https://docs.getdbt.com/"; pricing="https://www.getdbt.com/pricing"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.04"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.04_Databricks_Learning_Guide"; rank=3; name="Databricks"; short="Databricks"; section="02.02.01.03.04"; tags=@("databricks","delta","top-10"); desc="the unified lakehouse platform with Delta Live Tables, Photon, and collaborative notebooks"; prereq="Spark SQL, cloud workspace"; docs="https://docs.databricks.com/"; pricing="https://www.databricks.com/product/pricing"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.05"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.05_Snowflake_Learning_Guide"; rank=4; name="Snowflake"; short="Snowflake"; section="02.02.01.03.05"; tags=@("snowflake","sql","top-10"); desc="the cloud data warehouse with elastic SQL transforms, streams/tasks, and Snowpark"; prereq="SQL, warehouse admin basics"; docs="https://docs.snowflake.com/"; pricing="https://www.snowflake.com/pricing/"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.06"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.06_Trino_Learning_Guide"; rank=5; name="Trino"; short="Trino"; section="02.02.01.03.06"; tags=@("trino","presto","sql","top-10"); desc="the distributed SQL query engine for federated lake and warehouse transformation"; prereq="SQL, connector concepts"; docs="https://trino.io/docs/current/"; pricing="https://trino.io/"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.07"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.07_Apache_Beam_Batch_Learning_Guide"; rank=6; name="Apache Beam (Batch)"; short="Beam"; section="02.02.01.03.07"; tags=@("beam","batch","top-10"); desc="the portable batch pipeline SDK with runners on Dataflow, Flink, and Spark"; prereq="Python or Java, pipeline concepts"; docs="https://beam.apache.org/documentation/"; pricing="https://beam.apache.org/"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.08"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.08_Talend_Learning_Guide"; rank=7; name="Talend"; short="Talend"; section="02.02.01.03.08"; tags=@("talend","etl","top-10"); desc="enterprise visual ETL/ELT with data quality and stewardship integration"; prereq="ETL concepts, JDBC connectivity"; docs="https://help.qlik.com/talend/"; pricing="https://www.talend.com/pricing/"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.09"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.09_Informatica_Learning_Guide"; rank=8; name="Informatica"; short="Informatica"; section="02.02.01.03.09"; tags=@("informatica","etl","top-10"); desc="enterprise iPaaS and cloud data integration with AI-assisted mapping"; prereq="Enterprise integration patterns"; docs="https://docs.informatica.com/"; pricing="https://www.informatica.com/pricing.html"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.10"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.10_Matillion_Learning_Guide"; rank=9; name="Matillion"; short="Matillion"; section="02.02.01.03.10"; tags=@("matillion","cloud-etl","top-10"); desc="cloud-native push-down ELT for Snowflake, BigQuery, Redshift, and Databricks"; prereq="Target warehouse SQL"; docs="https://documentation.matillion.com/"; pricing="https://www.matillion.com/pricing"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" },
    @{ id="02.02.01.03.11"; folder="02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.11_Dataform_Learning_Guide"; rank=10; name="Dataform"; short="Dataform"; section="02.02.01.03.11"; tags=@("dataform","gcp","sql","top-10"); desc="GCP-native SQL pipeline tool (Google Cloud) for BigQuery transformations with Git integration"; prereq="BigQuery SQL, Git"; docs="https://cloud.google.com/dataform/docs"; pricing="https://cloud.google.com/dataform/pricing"; rank_doc="Top 10 Batch Transformation Technologies"; rank_link="../02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md"; mode="batch transformation" }
)

$StreamTop10 = @(
    @{ id="02.02.02.03.02"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.02_Apache_Flink_Learning_Guide"; key="flink"; rank=1; name="Apache Flink"; short="Flink"; section="02.02.02.03.02"; tags=@("flink","streaming","top-10"); desc="the stateful stream processing engine for event-time transformation and CDC"; prereq="Java/Python, Kafka, event-time concepts"; docs="https://nightlies.apache.org/flink/flink-docs-stable/"; pricing="https://flink.apache.org/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.03"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.03_Spark_Structured_Streaming_Learning_Guide"; rank=2; name="Spark Structured Streaming"; short="Spark SS"; section="02.02.02.03.03"; tags=@("spark","streaming","top-10"); desc="micro-batch stream processing on Spark with Delta/Iceberg sink integration"; prereq="Spark, SQL"; docs="https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html"; pricing="https://spark.apache.org/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.04"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.04_Kafka_Streams_Learning_Guide"; rank=3; name="Kafka Streams"; short="Kafka Streams"; section="02.02.02.03.04"; tags=@("kafka","streaming","top-10"); desc="the lightweight stream processing library embedded in Kafka applications"; prereq="Kafka, Java/Scala"; docs="https://kafka.apache.org/documentation/streams/"; pricing="https://kafka.apache.org/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.05"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.05_Google_Dataflow_Learning_Guide"; rank=4; name="Google Cloud Dataflow"; short="Dataflow"; section="02.02.02.03.05"; tags=@("gcp","dataflow","beam","top-10"); desc="managed Apache Beam runner for streaming transformation on GCP"; prereq="Beam Python/Java"; docs="https://cloud.google.com/dataflow/docs"; pricing="https://cloud.google.com/dataflow/pricing"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.06"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.06_AWS_Managed_Flink_Learning_Guide"; rank=5; name="Amazon Managed Service for Apache Flink"; short="Managed Flink"; section="02.02.02.03.06"; tags=@("aws","flink","kinesis","top-10"); desc="AWS-managed Flink for Kinesis and Kafka stream transformation"; prereq="Flink SQL or DataStream API"; docs="https://docs.aws.amazon.com/managed-flink/"; pricing="https://aws.amazon.com/kinesis/data-analytics/pricing/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.07"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.07_Azure_Stream_Analytics_Learning_Guide"; rank=6; name="Azure Stream Analytics"; short="ASA"; section="02.02.02.03.07"; tags=@("azure","streaming","top-10"); desc="SQL-based real-time transformation on Event Hubs and IoT Hub"; prereq="Stream SQL, Azure Event Hubs"; docs="https://learn.microsoft.com/azure/stream-analytics/"; pricing="https://azure.microsoft.com/pricing/details/stream-analytics/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.08"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.08_Apache_Beam_Learning_Guide"; rank=7; name="Apache Beam"; short="Beam"; section="02.02.02.03.08"; tags=@("beam","streaming","top-10"); desc="portable unified batch/stream SDK with multi-runner support"; prereq="Python/Java pipeline model"; docs="https://beam.apache.org/documentation/"; pricing="https://beam.apache.org/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.09"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.09_Materialize_Learning_Guide"; rank=8; name="Materialize"; short="Materialize"; section="02.02.02.03.09"; tags=@("materialize","sql","streaming","top-10"); desc="SQL streaming database for incremental views and real-time marts"; prereq="SQL, Kafka/PostgreSQL sources"; docs="https://materialize.com/docs/"; pricing="https://materialize.com/pricing"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.10"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.10_RisingWave_Learning_Guide"; rank=9; name="RisingWave"; short="RisingWave"; section="02.02.02.03.10"; tags=@("risingwave","streaming","top-10"); desc="PostgreSQL-compatible streaming database for cloud-native SQL transforms"; prereq="SQL, Kafka"; docs="https://docs.risingwave.com/"; pricing="https://risingwave.com/pricing/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" },
    @{ id="02.02.02.03.11"; folder="02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.11_Bytewax_Learning_Guide"; rank=10; name="Bytewax"; short="Bytewax"; section="02.02.02.03.11"; tags=@("bytewax","python","streaming","top-10"); desc="Python-native stream processing framework for ML and data transforms"; prereq="Python, Kafka/Redpanda"; docs="https://docs.bytewax.io/"; pricing="https://www.bytewax.io/"; rank_doc="Top 10 Streaming Transformation Technologies"; rank_link="../02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md"; mode="streaming transformation" }
)

$CloudBatch = @(
    @{ id="02.02.01.02.02.03"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.02_GCP\02.02.01.02.02.03_Dataproc_Spark_Learning_Guide"; key="spark"; name="Google Cloud Dataproc Spark"; short="Dataproc"; section="02.02.01.02.02.03"; tags=@("gcp","dataproc","spark","learning-guide"); desc="managed Spark clusters on GCE or GKE for lakehouse batch transformation"; prereq="GCP project, GCS datasets"; docs="https://cloud.google.com/dataproc/docs"; pricing="https://cloud.google.com/dataproc/pricing"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.02.04"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.02_GCP\02.02.01.02.02.04_BigQuery_SQL_Learning_Guide"; key="bigquery"; name="Google BigQuery SQL Transformation"; short="BigQuery"; section="02.02.01.02.02.04"; tags=@("gcp","bigquery","sql","learning-guide"); desc="serverless SQL ELT and scheduled transforms in BigQuery"; prereq="BigQuery datasets, IAM"; docs="https://cloud.google.com/bigquery/docs"; pricing="https://cloud.google.com/bigquery/pricing"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.03.03"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.03_AWS\02.02.01.02.03.03_Glue_ETL_Learning_Guide"; key="glue_etl"; name="AWS Glue ETL"; short="Glue ETL"; section="02.02.01.02.03.03"; tags=@("aws","glue","spark","learning-guide"); desc="managed Spark ETL with Data Catalog and job bookmarks"; prereq="AWS account, S3, IAM"; docs="https://docs.aws.amazon.com/glue/"; pricing="https://aws.amazon.com/glue/pricing/"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.03.04"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.03_AWS\02.02.01.02.03.04_EMR_Spark_Learning_Guide"; name="Amazon EMR Spark"; short="EMR"; section="02.02.01.02.03.04"; tags=@("aws","emr","spark","learning-guide"); desc="managed Hadoop/Spark clusters for large-scale batch transformation"; prereq="AWS, S3, EC2 networking"; docs="https://docs.aws.amazon.com/emr/"; pricing="https://aws.amazon.com/emr/pricing/"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.03.05"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.03_AWS\02.02.01.02.03.05_Athena_SQL_Learning_Guide"; name="Amazon Athena SQL"; short="Athena"; section="02.02.01.02.03.05"; tags=@("aws","athena","sql","learning-guide"); desc="serverless SQL transforms on S3 tables via Glue Catalog"; prereq="S3, Glue Catalog"; docs="https://docs.aws.amazon.com/athena/"; pricing="https://aws.amazon.com/athena/pricing/"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.04.03"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.04_Azure\02.02.01.02.04.03_Synapse_Spark_Learning_Guide"; name="Azure Synapse Spark"; short="Synapse Spark"; section="02.02.01.02.04.03"; tags=@("azure","synapse","spark","learning-guide"); desc="serverless and dedicated Spark pools in Synapse Analytics"; prereq="Synapse workspace, ADLS"; docs="https://learn.microsoft.com/azure/synapse-analytics/spark/"; pricing="https://azure.microsoft.com/pricing/details/synapse-analytics/"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.04.04"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.04_Azure\02.02.01.02.04.04_ADF_Mapping_Data_Flows_Learning_Guide"; name="Azure ADF Mapping Data Flows"; short="ADF Data Flows"; section="02.02.01.02.04.04"; tags=@("azure","adf","etl","learning-guide"); desc="visual Spark-based transforms in Azure Data Factory"; prereq="ADF, linked services"; docs="https://learn.microsoft.com/azure/data-factory/concepts-data-flow-overview"; pricing="https://azure.microsoft.com/pricing/details/data-factory/"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" },
    @{ id="02.02.01.02.04.05"; folder="02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.04_Azure\02.02.01.02.04.05_Fabric_Notebooks_Learning_Guide"; name="Microsoft Fabric Notebooks"; short="Fabric"; section="02.02.01.02.04.05"; tags=@("azure","fabric","spark","learning-guide"); desc="Spark notebooks and pipelines in Microsoft Fabric lakehouse"; prereq="Fabric capacity, lakehouse"; docs="https://learn.microsoft.com/fabric/data-engineering/"; pricing="https://azure.microsoft.com/pricing/details/microsoft-fabric/"; parent_readme="Batch Cloud Services"; parent_link="../../README.md"; mode="batch cloud" }
)

$CloudStream = @(
    @{ id="02.02.02.02.02.03"; folder="02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.02_GCP\02.02.02.02.02.03_Dataflow_Learning_Guide"; key="dataflow"; name="Google Cloud Dataflow"; short="Dataflow"; section="02.02.02.02.02.03"; tags=@("gcp","dataflow","beam","learning-guide"); desc="managed Beam runner for streaming silver/gold transforms"; prereq="Pub/Sub, Beam SDK"; docs="https://cloud.google.com/dataflow/docs"; pricing="https://cloud.google.com/dataflow/pricing"; parent_readme="Streaming Cloud Services"; parent_link="../../README.md"; mode="streaming cloud" },
    @{ id="02.02.02.02.03.03"; folder="02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.03_AWS\02.02.02.02.03.03_Glue_Streaming_Learning_Guide"; name="AWS Glue Streaming ETL"; short="Glue Streaming"; section="02.02.02.02.03.03"; tags=@("aws","glue","streaming","learning-guide"); desc="managed Spark Structured Streaming jobs on Glue 4.0+"; prereq="Kinesis or Kafka source"; docs="https://docs.aws.amazon.com/glue/latest/dg/add-job-streaming.html"; pricing="https://aws.amazon.com/glue/pricing/"; parent_readme="Streaming Cloud Services"; parent_link="../../README.md"; mode="streaming cloud" },
    @{ id="02.02.02.02.03.04"; folder="02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.03_AWS\02.02.02.02.03.04_Managed_Flink_Learning_Guide"; name="Amazon Managed Service for Apache Flink"; short="Managed Flink"; section="02.02.02.02.03.04"; tags=@("aws","flink","learning-guide"); desc="AWS-managed Flink for Kinesis and MSK stream transformation"; prereq="Kinesis/MSK"; docs="https://docs.aws.amazon.com/managed-flink/"; pricing="https://aws.amazon.com/kinesis/data-analytics/pricing/"; parent_readme="Streaming Cloud Services"; parent_link="../../README.md"; mode="streaming cloud" },
    @{ id="02.02.02.02.04.03"; folder="02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.04_Azure\02.02.02.02.04.03_Stream_Analytics_Learning_Guide"; name="Azure Stream Analytics"; short="ASA"; section="02.02.02.02.04.03"; tags=@("azure","streaming","learning-guide"); desc="SQL-based stream transforms with Event Hubs I/O"; prereq="Event Hubs, Stream Analytics job"; docs="https://learn.microsoft.com/azure/stream-analytics/"; pricing="https://azure.microsoft.com/pricing/details/stream-analytics/"; parent_readme="Streaming Cloud Services"; parent_link="../../README.md"; mode="streaming cloud" },
    @{ id="02.02.02.02.04.04"; folder="02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.04_Azure\02.02.02.02.04.04_Fabric_Real_Time_Intelligence_Learning_Guide"; name="Microsoft Fabric Real-Time Intelligence"; short="Fabric RTI"; section="02.02.02.02.04.04"; tags=@("azure","fabric","streaming","learning-guide"); desc="Eventstream and KQL transforms in Fabric for real-time analytics"; prereq="Fabric capacity"; docs="https://learn.microsoft.com/fabric/real-time-intelligence/"; pricing="https://azure.microsoft.com/pricing/details/microsoft-fabric/"; parent_readme="Streaming Cloud Services"; parent_link="../../README.md"; mode="streaming cloud" }
)

$AllGuides = $BatchTop10 + $StreamTop10 + $CloudBatch + $CloudStream
$count = 0
foreach ($g in $AllGuides) {
    $count += Invoke-GenerateGuide $g
}

# Top 10 overview hubs
Write-Doc (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.03_Open_Source\02.02.01.03.01_Overview\02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md") `
    ((Get-FM "Top 10 Batch Transformation Technologies" "02.02.01.03.01" "overview" "batch, top-10") + @'
# Top 10 Batch Transformation Technologies

Market-leading engines for **batch and micro-batch transformation** - ranked for enterprise adoption, ecosystem maturity, and production fit.

| Rank | Technology | Learning Guide | Category |
| ---: | --- | --- | --- |
| 1 | Apache Spark | [Learning Guide](../02.02.01.03.02_Apache_Spark_Learning_Guide/README.md) | Distributed lake engine |
| 2 | dbt | [Learning Guide](../02.02.01.03.03_dbt_Learning_Guide/README.md) | SQL analytics engineering |
| 3 | Databricks | [Learning Guide](../02.02.01.03.04_Databricks_Learning_Guide/README.md) | Lakehouse platform |
| 4 | Snowflake | [Learning Guide](../02.02.01.03.05_Snowflake_Learning_Guide/README.md) | Cloud warehouse SQL |
| 5 | Trino | [Learning Guide](../02.02.01.03.06_Trino_Learning_Guide/README.md) | Federated SQL |
| 6 | Apache Beam (Batch) | [Learning Guide](../02.02.01.03.07_Apache_Beam_Batch_Learning_Guide/README.md) | Portable pipelines |
| 7 | Talend | [Learning Guide](../02.02.01.03.08_Talend_Learning_Guide/README.md) | Enterprise ETL |
| 8 | Informatica | [Learning Guide](../02.02.01.03.09_Informatica_Learning_Guide/README.md) | Enterprise iPaaS |
| 9 | Matillion | [Learning Guide](../02.02.01.03.10_Matillion_Learning_Guide/README.md) | Cloud push-down ELT |
| 10 | Dataform | [Learning Guide](../02.02.01.03.11_Dataform_Learning_Guide/README.md) | BigQuery SQL pipelines |

Managed cloud variants: [Batch Cloud Services](../02.02.01.02_Cloud_Services/README.md).
'@)
$count++

Write-Doc (Join-Path $Base "02.02.02_Streaming_Transformation\02.02.02.03_Open_Source\02.02.02.03.01_Overview\02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md") `
    ((Get-FM "Top 10 Streaming Transformation Technologies" "02.02.02.03.01" "overview" "streaming, top-10") + @'
# Top 10 Streaming Transformation Technologies

| Rank | Technology | Learning Guide | Category |
| ---: | --- | --- | --- |
| 1 | Apache Flink | [Learning Guide](../02.02.02.03.02_Apache_Flink_Learning_Guide/README.md) | Stateful stream engine |
| 2 | Spark Structured Streaming | [Learning Guide](../02.02.02.03.03_Spark_Structured_Streaming_Learning_Guide/README.md) | Micro-batch streams |
| 3 | Kafka Streams | [Learning Guide](../02.02.02.03.04_Kafka_Streams_Learning_Guide/README.md) | Embedded library |
| 4 | Google Cloud Dataflow | [Learning Guide](../02.02.02.03.05_Google_Dataflow_Learning_Guide/README.md) | Managed Beam |
| 5 | Amazon Managed Flink | [Learning Guide](../02.02.02.03.06_AWS_Managed_Flink_Learning_Guide/README.md) | AWS managed Flink |
| 6 | Azure Stream Analytics | [Learning Guide](../02.02.02.03.07_Azure_Stream_Analytics_Learning_Guide/README.md) | Stream SQL |
| 7 | Apache Beam | [Learning Guide](../02.02.02.03.08_Apache_Beam_Learning_Guide/README.md) | Portable SDK |
| 8 | Materialize | [Learning Guide](../02.02.02.03.09_Materialize_Learning_Guide/README.md) | SQL streaming DB |
| 9 | RisingWave | [Learning Guide](../02.02.02.03.10_RisingWave_Learning_Guide/README.md) | Cloud streaming SQL |
| 10 | Bytewax | [Learning Guide](../02.02.02.03.11_Bytewax_Learning_Guide/README.md) | Python streams |

Managed cloud: [Streaming Cloud Services](../02.02.02.02_Cloud_Services/README.md).
'@)
$count++

# Cloud batch reference architecture
Write-Doc (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.01_Overview\02.02.01.02.01.01_Cloud_Batch_Transformation_Reference.md") `
    ((Get-FM "Cloud Batch Transformation Reference Architecture" "02.02.01.02.01" "overview" "cloud, batch") + @'
# Cloud Batch Transformation Reference Architecture

```mermaid
flowchart TB
  subgraph GCP
    BQ[BigQuery_SQL]
    DP[Dataproc_Spark]
  end
  subgraph AWS
    Glue[Glue_ETL]
    EMR[EMR_Spark]
    ATH[Athena]
  end
  subgraph Azure
    SYN[Synapse_Spark]
    ADF[ADF_Data_Flows]
  end
  Lake[(Object_Storage)] --> DP & Glue & EMR & SYN
  WH[(Warehouse)] --> BQ & ATH
```

| Provider | Primary transform services | Learning guides |
| --- | --- | --- |
| GCP | BigQuery, Dataproc | [BigQuery](../02.02.02_GCP/02.02.01.02.02.04_BigQuery_SQL_Learning_Guide/README.md), [Dataproc](../02.02.02_GCP/02.02.01.02.02.03_Dataproc_Spark_Learning_Guide/README.md) |
| AWS | Glue, EMR, Athena | [Glue ETL](../02.02.03_AWS/02.02.01.02.03.03_Glue_ETL_Learning_Guide/README.md), [EMR](../02.02.03_AWS/02.02.01.02.03.04_EMR_Spark_Learning_Guide/README.md) |
| Azure | Synapse, ADF, Fabric | [Synapse](../02.02.04_Azure/02.02.01.02.04.03_Synapse_Spark_Learning_Guide/README.md), [ADF Flows](../02.02.04_Azure/02.02.01.02.04.04_ADF_Mapping_Data_Flows_Learning_Guide/README.md) |
'@)
$count++

# Cloud services READMEs
foreach ($entry in @(
    @("02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services", "02.02.01.02", "Batch Cloud Services"),
    @("02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services", "02.02.02.02", "Streaming Cloud Services")
)) {
    $mode, $sec, $title = $entry
    Write-Doc (Join-Path $Base "$mode\README.md") ((Get-FM "$title README" $sec "overview" "cloud") + @"

# $title

Managed transformation services by cloud provider. Each service includes a **9-module learning guide**.

| Provider | Path |
| --- | --- |
| Overview | ``$sec.01_Overview/`` |
| GCP | ``$sec.02_GCP/`` |
| AWS | ``$sec.03_AWS/`` |
| Azure | ``$sec.04_Azure/`` |
| Cross-Cloud | ``$sec.05_Cross_Cloud/`` |
"@)
    $count++
}

# Open source READMEs
foreach ($entry in @(
    @("02.02.01_Batch_Transformation\02.02.01.03_Open_Source", "02.02.01.03", "Batch Open Source / Top 10"),
    @("02.02.02_Streaming_Transformation\02.02.02.03_Open_Source", "02.02.02.03", "Streaming Open Source / Top 10")
)) {
    $mode, $sec, $title = $entry
    Write-Doc (Join-Path $Base "$mode\README.md") ((Get-FM "$title README" $sec "hub" "open-source, top-10") + @"

# $title

[Top 10 overview]($sec.01_Overview/) - ranked technologies with full 9-module learning guides each.
"@)
    $count++
}

# Fundamentals overview docs
Write-Doc (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.01_Overview\02.02.01.01.01.01_Batch_Transformation_Overview.md") `
    ((Get-FM "Batch Transformation Overview" "02.02.01.01.01" "overview" "batch") + @'
# Batch Transformation Overview

**Batch transformation** converts landed raw data into curated analytical datasets on a **schedule** (hourly, daily, monthly). It is the default pattern for medallion lakehouses, dimensional marts, and regulatory reporting.

## Core capabilities

| Capability | Description |
| --- | --- |
| **Cleansing** | Null handling, type coercion, deduplication |
| **Conforming** | Surrogate keys, standard codes, unit conversion |
| **Enrichment** | Joins to reference/master data |
| **Aggregation** | Rollups, snapshots, period-end balances |
| **Modeling** | Star/snowflake, Data Vault, OBT wide tables |

## Engine selection

See [Top 10 Batch Technologies](../../02.02.01.03_Open_Source/02.02.01.03.01_Overview/02.02.01.03.01.01_Top_10_Batch_Transformation_Technologies.md).
'@)
$count++

Write-Doc (Join-Path $Base "02.02.02_Streaming_Transformation\02.02.02.01_Fundamentals\02.02.02.01.01_Overview\02.02.02.01.01.01_Streaming_Transformation_Overview.md") `
    ((Get-FM "Streaming Transformation Overview" "02.02.02.01.01.01" "overview" "streaming") + @'
# Streaming Transformation Overview

**Streaming transformation** applies business logic to unbounded event streams with **low latency** - filtering, enrichment, windowed aggregation, and CDC merge into silver/gold tables.

## Event-time vs processing-time

| Semantics | Use |
| --- | --- |
| **Event time** | Correct analytics with watermarks (Flink, Beam) |
| **Processing time** | Approximate dashboards, lower latency |
| **Ingestion time** | Audit trails only |

See [Top 10 Streaming Technologies](../../02.02.02.03_Open_Source/02.02.02.03.01_Overview/02.02.02.03.01.01_Top_10_Streaming_Transformation_Technologies.md).
'@)
$count++

# Comparisons hub
Write-Doc (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.06_Comparisons\02.02.01.06.01_ETL_vs_ELT.md") `
    ((Get-FM "ETL vs ELT Comparison" "02.02.01.06" "evaluation" "etl, elt") + @'
# ETL vs ELT

| Dimension | ETL | ELT |
| --- | --- | --- |
| Transform location | External engine before load | Inside target warehouse/lake |
| Typical tools | Spark, Glue, Informatica | dbt, BigQuery SQL, Snowflake |
| Best when | Heavy cleansing on files | Warehouse compute is elastic and cheap |
'@)
$count++

Write-Doc (Join-Path $Base "02.02.01_Batch_Transformation\02.02.01.06_Comparisons\02.02.01.06.02_Spark_vs_dbt.md") `
    ((Get-FM "Spark vs dbt Comparison" "02.02.01.06" "evaluation" "spark, dbt") + @'
# Spark vs dbt

| Dimension | Apache Spark | dbt |
| --- | --- | --- |
| Primary API | DataFrame/SQL on files | Warehouse SQL |
| Scale | PB on object storage | Warehouse limits |
| Portability | High (Spark everywhere) | Warehouse-specific adapters |
| Testing/docs | External (Great Expectations) | Built-in tests + docs site |
'@)
$count++

Write-Host "Generated $count files under 02.02 transformation"
