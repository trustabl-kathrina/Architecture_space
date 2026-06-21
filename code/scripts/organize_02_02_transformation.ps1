# Scaffold 02.02 Data Transformation Architecture — mirrors 02.01 ingestion mode structure.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TransformRoot = Join-Path $RepoRoot "docs\02_Data_Engineering_Architecture\02.02_Data_Transformation_Architecture"
$Today = "2026-06-20"

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function To-LongPath([string]$Path) {
    $p = [System.IO.Path]::GetFullPath($Path)
    if ($p.StartsWith('\\?\')) { return $p }
    if ($p.StartsWith('\\')) { return '\\?\UNC\' + $p.Substring(2) }
    return '\\?\' + $p
}

function Write-File([string]$Path, [string]$Content) {
    Ensure-Dir (Split-Path $Path -Parent)
    if ($DryRun) { Write-Host "  write: $Path"; return }
    [IO.File]::WriteAllText((To-LongPath $Path), $Content.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}

function Move-Legacy([string]$Src, [string]$Dst) {
    if (-not (Test-Path $Src)) { return }
    if (Test-Path $Dst) { return }
    Ensure-Dir (Split-Path $Dst -Parent)
    if ($DryRun) { Write-Host "  move: $(Split-Path $Src -Leaf) -> $Dst"; return }
    [System.IO.File]::Move((To-LongPath $Src), (To-LongPath $Dst))
    Write-Host "  moved: $(Split-Path $Src -Leaf)"
}

$SubSlots = @(
    "01_Fundamentals", "02_Cloud_Services", "03_Open_Source", "04_Architecture_Patterns",
    "05_Benchmarks", "06_Comparisons", "07_Interview_Questions", "08_Integration_Patterns", "09_Reference_Architectures"
)

$Modes = @(
    @{ Id = "02.02.01"; Folder = "02.02.01_Batch_Transformation"; Title = "Batch Transformation"; Tags = "batch, etl, elt, spark" }
    @{ Id = "02.02.02"; Folder = "02.02.02_Streaming_Transformation"; Title = "Streaming Transformation"; Tags = "streaming, flink, spark-streaming" }
    @{ Id = "02.02.03"; Folder = "02.02.03_Near_Real_Time_Transformation"; Title = "Near Real Time Transformation"; Tags = "micro-batch, nrt" }
    @{ Id = "02.02.04"; Folder = "02.02.04_Shared_Foundations"; Title = "Shared Foundations"; Tags = "transformation, medallion, scd" }
)

Write-Host "Phase 1: scaffold mode folders"
foreach ($mode in $Modes) {
    $modeRoot = Join-Path $TransformRoot $mode.Folder
    foreach ($slot in $SubSlots) {
        $num = $slot.Substring(0, 2)
        if ($mode.Id -eq "02.02.04" -and $num -in @("03", "05", "06", "07", "08")) {
            # Shared foundations uses custom layout — skip generic open-source/benchmark slots
            continue
        }
        if ($mode.Id -eq "02.02.03" -and $num -eq "03") { continue }
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).$num`_$slot")
    }
    # Fundamentals topic groups
    if ($mode.Id -eq "02.02.01") {
        @(
            "$($mode.Id).01.01_Overview", "$($mode.Id).01.02_Transformation_Patterns", "$($mode.Id).01.03_Processing_Engines"
        ) | ForEach-Object { Ensure-Dir (Join-Path $modeRoot "$($mode.Id).01_Fundamentals\$_") }
    }
    if ($mode.Id -eq "02.02.02") {
        @(
            "$($mode.Id).01.01_Overview", "$($mode.Id).01.02_Stream_Processing", "$($mode.Id).01.03_State_And_Windows"
        ) | ForEach-Object { Ensure-Dir (Join-Path $modeRoot "$($mode.Id).01_Fundamentals\$_") }
    }
    if ($mode.Id -eq "02.02.03") {
        @(
            "$($mode.Id).01.01_Strategy", "$($mode.Id).01.02_Micro_Batch_Patterns"
        ) | ForEach-Object { Ensure-Dir (Join-Path $modeRoot "$($mode.Id).01_Fundamentals\$_") }
    }
    if ($mode.Id -eq "02.02.04") {
        @(
            "$($mode.Id).01.01_Overview", "$($mode.Id).01.02_ETL_ELT_Strategy",
            "$($mode.Id).01.03_Medallion_And_Zones", "$($mode.Id).01.04_SCD_And_Slowly_Changing",
            "$($mode.Id).01.05_Enterprise_Frameworks", "$($mode.Id).01.06_Cross_Mode_Transformation"
        ) | ForEach-Object { Ensure-Dir (Join-Path $modeRoot "$($mode.Id).01_Fundamentals\$_") }
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).02_Cloud_Services\$($mode.Id).02.01_Overview")
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.01_Reference_Architectures")
    }
    # Cloud provider slots
    if ($mode.Id -ne "02.02.04") {
        @("01_Overview", "02_GCP", "03_AWS", "04_Azure", "05_Cross_Cloud") | ForEach-Object {
            Ensure-Dir (Join-Path $modeRoot "$($mode.Id).02_Cloud_Services\$($mode.Id).02.$_")
        }
    }
    # Architecture pattern groups
    if ($mode.Id -in @("02.02.01", "02.02.02")) {
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.01_ETL_ELT")
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.02_Medallion")
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.03_Data_Quality_In_Transform")
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.04_Reference_Architectures")
    }
    if ($mode.Id -eq "02.02.03") {
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.01_Micro_Batch")
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).04_Architecture_Patterns\$($mode.Id).04.02_Reference_Architectures")
    }
    # Open source overview slot
    if ($mode.Id -in @("02.02.01", "02.02.02")) {
        Ensure-Dir (Join-Path $modeRoot "$($mode.Id).03_Open_Source\$($mode.Id).03.01_Overview")
    }

    $readme = @"
---
title: README
section: "$($mode.Id)"
status: complete
template: overview
last_reviewed: $Today
owner: architecture-team
tags: [$($mode.Tags)]
canonical: true
---

# $($mode.Id) $($mode.Title)

## Purpose

Expert learning paths for **$($mode.Title.ToLower())** — fundamentals, cloud managed services, open-source and market-leading engines, architecture patterns, benchmarks, comparisons, and interview preparation.

## Subsections

| Slot | Subsection | Path |
| ---: | --- | --- |
| .01 | Fundamentals | ``$($mode.Id).01_Fundamentals/`` |
| .02 | Cloud Services | ``$($mode.Id).02_Cloud_Services/`` |
| .03 | Open Source / Top 10 | ``$($mode.Id).03_Open_Source/`` |
| .04 | Architecture Patterns | ``$($mode.Id).04_Architecture_Patterns/`` |
| .05 | Benchmarks | ``$($mode.Id).05_Benchmarks/`` |
| .06 | Comparisons | ``$($mode.Id).06_Comparisons/`` |
| .07 | Interview Questions | ``$($mode.Id).07_Interview_Questions/`` |
| .08 | Integration Patterns | ``$($mode.Id).08_Integration_Patterns/`` |
| .09 | Reference Architectures | ``$($mode.Id).09_Reference_Architectures/`` |

## Related

- [02.02 Transformation Architecture](../README.md)
- [02.01 Data Ingestion](../../02.01_Data_Ingestion_Architecture/README.md)
- [02.03 Data Orchestration](../../02.03_Data_Orchestration_Architecture/README.md)
"@
    Write-File (Join-Path $modeRoot "README.md") $readme
}

Write-Host "Phase 2: root README"
$rootReadme = @"
---
title: README
section: "02.02"
status: complete
template: overview
last_reviewed: $Today
owner: architecture-team
tags: [transformation, etl, elt, spark, dbt]
canonical: true
---

# 02.02 Data Transformation Architecture

> Status: expert learning guides — batch, streaming, near-real-time, and shared foundations

## Purpose

How data is **cleansed, enriched, conformed, aggregated, and modeled** across latency classes: batch, streaming, and near-real-time transformation, plus shared ETL/ELT, medallion, and SCD frameworks.

## Numbering standard

Mirrors ``02.01`` ingestion structure:

``````
02.02.MM                    Transformation mode (01 batch, 02 streaming, 03 near-RT, 04 shared)
02.02.MM.SS_Subsection/     Top subsection (.01–.09)
02.02.MM.SS.TT_TopicGroup/  Topic group or learning guide folder
02.02.MM.SS.TT.NN_Topic.md  Topic file (9-module learning guides use .01–.09)
``````

**Cloud Services provider slots** (``.02`` subsection): ``.01`` Overview · ``.02`` GCP · ``.03`` AWS · ``.04`` Azure · ``.05`` Cross-Cloud

**Learning guide module pattern** (9 modules): Overview · Architecture · How To Use · Scenarios · Limitations · Costing · Production Configuration · Evaluation Criteria · Benchmarking

**Front matter:** mode READMEs use ``section: "02.02.0N"``; nested topic files use ``section: "02.02"`` or granular guide IDs.

## Transformation modes

| # | Mode | Path | Description |
| --- | --- | --- | --- |
| 02.02.01 | [Batch Transformation](02.02.01_Batch_Transformation/README.md) | ``02.02.01_*`` | Spark batch, dbt, Glue ETL, warehouse SQL, medallion batch layers |
| 02.02.02 | [Streaming Transformation](02.02.02_Streaming_Transformation/README.md) | ``02.02.02_*`` | Flink, Spark Structured Streaming, Kafka Streams, Dataflow, stream-table duality |
| 02.02.03 | [Near-Real-Time Transformation](02.02.03_Near_Real_Time_Transformation/README.md) | ``02.02.03_*`` | Micro-batch, trigger-based transforms, latency-sensitive silver/gold |

## Shared foundations

| # | Topic | Path | Description |
| --- | --- | --- | --- |
| 02.02.04 | [Shared Foundations](02.02.04_Shared_Foundations/README.md) | ``02.02.04_*`` | ETL vs ELT strategy, medallion, SCD, enterprise standards, cross-mode patterns |

## Subsection slot map

| Slot | Batch | Streaming | Near-RT | Shared |
| --- | --- | --- | --- | --- |
| .01 | Fundamentals | Fundamentals | Fundamentals | Fundamentals |
| .02 | Cloud Services | Cloud Services | Cloud Services | Cloud overview |
| .03 | Open Source / Top 10 | Open Source / Top 10 | — | — |
| .04 | Architecture Patterns | Architecture Patterns | Architecture Patterns | Patterns |
| .05 | Benchmarks | Benchmarks | Benchmarks | — |
| .06 | Comparisons | Comparisons | Comparisons | — |
| .07 | Interview Questions | Interview Questions | Interview Questions | — |
| .08 | Integration Patterns | Integration Patterns | Integration Patterns | — |
| .09 | Reference Architectures | Reference Architectures | Reference Architectures | Reference |

## Related

- [02 Data Engineering Architecture](../README.md)
- [02.01 Data Ingestion](../02.01_Data_Ingestion_Architecture/README.md)
- [02.05 Data Storage](../02.05_Data_Storage_Architecture/README.md)
"@
Write-File (Join-Path $TransformRoot "README.md") $rootReadme

Write-Host "Phase 3: migrate legacy flat files"
$LegacyMap = @{
    "Batch_Architecture.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.01_Overview\02.02.01.01.01.01_Batch_Transformation_Overview.md"
    "Batch_Design_Patterns.md" = "02.02.01_Batch_Transformation\02.02.01.04_Architecture_Patterns\02.02.01.04.01_ETL_ELT\02.02.01.04.01.02_Batch_Design_Patterns.md"
    "ETL_Strategy.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.02_ETL_ELT_Strategy\02.02.04.01.02.01_ETL_Strategy.md"
    "ELT_Strategy.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.02_ETL_ELT_Strategy\02.02.04.01.02.02_ELT_Strategy.md"
    "Transformation_Framework.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.01_Overview\02.02.04.01.01.01_Transformation_Framework.md"
    "Transformation_Patterns.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.01_Overview\02.02.04.01.01.02_Transformation_Patterns.md"
    "Medallion_Implementation.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.01_Medallion_Implementation.md"
    "Bronze_Architecture.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.02_Bronze_Architecture.md"
    "Silver_Architecture.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.03_Silver_Architecture.md"
    "Gold_Architecture.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.04_Gold_Architecture.md"
    "Data_Enrichment.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.02_Transformation_Patterns\02.02.01.01.02.01_Data_Enrichment.md"
    "Data_Harmonization.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.02_Transformation_Patterns\02.02.01.01.02.02_Data_Harmonization.md"
    "Data_Standardization.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.02_Transformation_Patterns\02.02.01.01.02.03_Data_Standardization.md"
    "Business_Rules_Framework.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.05_Enterprise_Frameworks\02.02.04.01.05.01_Business_Rules_Framework.md"
    "Enterprise_Batch_Standards.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.05_Enterprise_Frameworks\02.02.04.01.05.02_Enterprise_Batch_Standards.md"
    "Transformation_Governance.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.05_Enterprise_Frameworks\02.02.04.01.05.03_Transformation_Governance.md"
    "Reusable_Transformation_Frameworks.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.05_Enterprise_Frameworks\02.02.04.01.05.04_Reusable_Transformation_Frameworks.md"
    "Delta_Lake_Engineering.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.03_Processing_Engines\02.02.01.01.03.01_Delta_Lake_Engineering.md"
    "Iceberg_Engineering.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.03_Processing_Engines\02.02.01.01.03.02_Iceberg_Engineering.md"
    "Hudi_Engineering.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.03_Processing_Engines\02.02.01.01.03.03_Hudi_Engineering.md"
    "Lakehouse_Best_Practices.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.05_Lakehouse_Best_Practices.md"
    "Lakehouse_Optimization.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.06_Lakehouse_Optimization.md"
    "Distributed_Processing.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.03_Processing_Engines\02.02.01.01.03.04_Distributed_Processing.md"
    "Parallel_Processing.md" = "02.02.01_Batch_Transformation\02.02.01.01_Fundamentals\02.02.01.01.03_Processing_Engines\02.02.01.01.03.05_Parallel_Processing.md"
    "Batch_Performance_Tuning.md" = "02.02.01_Batch_Transformation\02.02.01.05_Benchmarks\02.02.01.05.01_Batch_Performance_Tuning.md"
    "Batch_SLA_Framework.md" = "02.02.01_Batch_Transformation\02.02.01.05_Benchmarks\02.02.01.05.02_Batch_SLA_Framework.md"
    "Scheduling_Framework.md" = "02.02.01_Batch_Transformation\02.02.01.08_Integration_Patterns\02.02.01.08.01_Scheduling_Framework.md"
    "Dependency_Management.md" = "02.02.01_Batch_Transformation\02.02.01.08_Integration_Patterns\02.02.01.08.02_Dependency_Management.md"
    "Storage_Optimization.md" = "02.02.04_Shared_Foundations\02.02.04.01_Fundamentals\02.02.04.01.03_Medallion_And_Zones\02.02.04.01.03.07_Storage_Optimization.md"
}
foreach ($entry in $LegacyMap.GetEnumerator()) {
    Move-Legacy (Join-Path $TransformRoot $entry.Key) (Join-Path $TransformRoot $entry.Value)
}
# Performance optimization folder
$perfSrc = Join-Path $TransformRoot "Performance_Optimization"
if (Test-Path $perfSrc) {
    Get-ChildItem $perfSrc -File | ForEach-Object {
        $dst = Join-Path $TransformRoot "02.02.01_Batch_Transformation\02.02.01.05_Benchmarks\02.02.01.05.03_Performance_Optimization\$($_.Name)"
        Move-Legacy $_.FullName $dst
    }
    if (-not $DryRun -and (Test-Path $perfSrc) -and -not (Get-ChildItem $perfSrc -Recurse -ErrorAction SilentlyContinue)) {
        Remove-Item $perfSrc -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Done.$(if ($DryRun) { ' (Dry run)' })"
