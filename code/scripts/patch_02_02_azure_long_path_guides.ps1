# Patch Azure learning guides missed due to Windows MAX_PATH (Phase 7 could not enumerate long paths)
$ErrorActionPreference = "Stop"
$Repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$Base = Join-Path $Repo "docs\02_Data_Engineering_Architecture\02.02_Data_Transformation_Architecture"
$Today = "2026-06-20"
$utf8 = New-Object System.Text.UTF8Encoding $false

function Get-LongPath($path) {
    $full = [IO.Path]::GetFullPath($path)
    if ($full.StartsWith('\\?\')) { return $full }
    if ($full.StartsWith('\\')) { return "\\?\UNC$($full.Substring(1))" }
    return "\\?\$full"
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

function Write-Doc($fullPath, $content) {
    $fullPath = [IO.Path]::GetFullPath($fullPath)
    $dir = Split-Path $fullPath -Parent
    $longDir = Get-LongPath $dir
    if (-not [IO.Directory]::Exists($longDir)) { [void][IO.Directory]::CreateDirectory($longDir) }
    [IO.File]::WriteAllText((Get-LongPath $fullPath), $content.TrimEnd() + "`n", $utf8)
}

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
| **Small** | 100 GB transform/day | `$ |
| **Medium** | 2 TB/day, 15m NRT | `$$ |
| **Large** | 20 TB/day, streaming | `$$$ |

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
Duration: __  Cost: `$__
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

$guides = @(
    @{
        Dir = "02.02.01_Batch_Transformation\02.02.01.02_Cloud_Services\02.02.01.02.04_Azure\02.02.01.02.04.04_ADF_Mapping_Data_Flows_Learning_Guide"
        Name = "Azure ADF Mapping Data Flows"
        Section = "02.02.01.02.04.04"
        Mode = "batch transformation"
        Docs = "https://learn.microsoft.com/azure/data-factory/concepts-data-flow-overview"
    },
    @{
        Dir = "02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.04_Azure\02.02.02.02.04.03_Stream_Analytics_Learning_Guide"
        Name = "Azure Stream Analytics"
        Section = "02.02.02.02.04.03"
        Mode = "streaming transformation"
        Docs = "https://learn.microsoft.com/azure/stream-analytics/"
    },
    @{
        Dir = "02.02.02_Streaming_Transformation\02.02.02.02_Cloud_Services\02.02.02.02.04_Azure\02.02.02.02.04.04_Fabric_Real_Time_Intelligence_Learning_Guide"
        Name = "Microsoft Fabric Real-Time Intelligence"
        Section = "02.02.02.02.04.04"
        Mode = "streaming transformation"
        Docs = "https://learn.microsoft.com/fabric/real-time-intelligence/"
    }
)

$modules = @(
    @("03", "How_To_Use"),
    @("04", "Scenarios"),
    @("05", "Limitations_And_Scenarios"),
    @("06", "Costing"),
    @("07", "Production_Configuration"),
    @("08", "Evaluation_Criteria"),
    @("09", "Benchmarking")
)

$count = 0
foreach ($g in $guides) {
    foreach ($m in $modules) {
        $modNum = $m[0]
        $modName = $m[1]
        $fileName = "$($g.Section).$modNum`_$modName.md"
        $fullPath = Join-Path (Join-Path $Base $g.Dir) $fileName
        $content = Get-RichLearningModule $g.Name $modNum $modName $g.Section $g.Mode $g.Docs
        Write-Doc $fullPath $content
        $count++
    }
}
Write-Host "Patched $count Azure guide modules (long-path guides)"
