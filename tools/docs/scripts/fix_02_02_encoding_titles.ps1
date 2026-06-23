# Fix encoding mojibake, malformed module titles, and remaining template stubs in 02.02
$Repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$Base = Join-Path $Repo "docs\02_Data_Engineering_Architecture\02.02_Data_Transformation_Architecture"
$utf8 = New-Object System.Text.UTF8Encoding $false
$fixed = 0

function Get-LongPath($path) {
    $full = [IO.Path]::GetFullPath($path)
    if ($full.StartsWith('\\?\')) { return $full }
    if ($full.StartsWith('\\')) { return "\\?\UNC$($full.Substring(1))" }
    return "\\?\$full"
}

$mdFiles = [System.Collections.ArrayList]@()
$stack = New-Object System.Collections.Stack
[void]$stack.Push($Base)
while ($stack.Count -gt 0) {
    $dir = [string]$stack.Pop()
    try {
        foreach ($d in [IO.Directory]::EnumerateDirectories((Get-LongPath $dir))) {
            [void]$stack.Push($d.TrimStart('\\?\'))
        }
        foreach ($f in [IO.Directory]::EnumerateFiles((Get-LongPath $dir), "*.md")) {
            [void]$mdFiles.Add($f.TrimStart('\\?\'))
        }
    } catch { }
}

foreach ($filePath in $mdFiles) {
    try { $t = [IO.File]::ReadAllText((Get-LongPath $filePath), $utf8) } catch { continue }
    $o = $t
    $t = $t.Replace([char]0x2013, '-').Replace([char]0x2014, '-').Replace([char]0x00B7, '|')
    $t = $t -replace '\xE2\x80\x93', '-' -replace '\xE2\x80\x94', '-'
    $t = $t -replace '``` bash','```bash' -replace '``` python','```python'
    $t = [regex]::Replace($t, '(?m)^# (\d+)\. 02\.02\.[\d.]+\s+(.+)$', '# $1. $2')
    $t = [regex]::Replace($t, '(?m)^title: 02\.02\.[\d.]+\s+(.+)$', 'title: $1')
    if ($t -ne $o) {
        [IO.File]::WriteAllText((Get-LongPath $filePath), $t, $utf8)
        $fixed++
    }
}

# Replace docs.example.com in Costing modules with official docs from sibling How To Use module
$pricingFixed = 0
$guideDirs = $mdFiles | ForEach-Object { Split-Path $_ -Parent } | Select-Object -Unique |
    Where-Object { $_ -match 'Learning_Guide' }
foreach ($gd in $guideDirs) {
    $howTo = [IO.Directory]::EnumerateFiles((Get-LongPath $gd), "*.03_How_To_Use.md") | Select-Object -First 1
    if (-not $howTo) { continue }
    $howPath = $howTo.TrimStart('\\?\')
    try { $htText = [IO.File]::ReadAllText((Get-LongPath $howPath), $utf8) } catch { continue }
    if ($htText -notmatch '\[Official documentation\]\(([^)]+)\)') { continue }
    $docsUrl = $Matches[1]
    $prefix = ([IO.Path]::GetFileName($howPath) -replace '\.03_How_To_Use\.md$','')
    $costing = Join-Path $gd "$prefix.06_Costing.md"
    if (-not [IO.File]::Exists((Get-LongPath $costing))) { continue }
    try { $ct = [IO.File]::ReadAllText((Get-LongPath $costing), $utf8) } catch { continue }
    if ($ct -notmatch 'docs\.example\.com') { continue }
    $nt = $ct -replace 'https://docs\.example\.com', $docsUrl
    if ($nt -ne $ct) {
        [IO.File]::WriteAllText((Get-LongPath $costing), $nt, $utf8)
        $pricingFixed++
    }
}
Write-Host "Pricing URL fixes: $pricingFixed"

Write-Host "Encoding/title fixes: $fixed"

$templates = @{
    "02.02.01_Batch_Transformation\02.02.01.08_Integration_Patterns\02.02.01.08.01_Scheduling_Framework.md" = @'
---
title: Scheduling Framework for Batch Transforms
section: "02.02.01.08"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [scheduling, orchestration, batch]
canonical: true
---
# Scheduling Framework for Batch Transforms

## Purpose

Coordinate **when** transform jobs run relative to upstream ingestion completion, downstream SLAs, and resource windows.

## Scheduling models

| Model | Use case |
| --- | --- |
| **Time-based cron** | Daily/hourly medallion layers |
| **Dependency-based** | Run silver after bronze partition lands |
| **Event-triggered** | S3/Lake Formation event starts Glue job |
| **Backfill window** | Historical reprocessing with concurrency cap |

## Integration with orchestrators

Link to [02.03 Data Orchestration](../../02.03_Data_Orchestration_Architecture/README.md): Airflow ExternalTaskSensor, Glue Workflows triggers, Step Functions EventBridge rules.

## Best practices

- Idempotent job design for safe replays
- max_active_runs=1 for merge-heavy layers
- Separate dev/staging/prod schedules with data isolation
'@
    "02.02.01_Batch_Transformation\02.02.01.08_Integration_Patterns\02.02.01.08.02_Dependency_Management.md" = @'
---
title: Dependency Management for Transforms
section: "02.02.01.08"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [dependencies, dag, batch]
canonical: true
---
# Dependency Management for Transforms

## Dependency types

| Type | Example |
| --- | --- |
| **Data** | Silver depends on bronze partition |
| **Schema** | Mart depends on dimension SCD completion |
| **Operational** | Quality gate pass before gold publish |
| **Cross-domain** | Finance mart after GL close event |

## DAG design

```mermaid
flowchart LR
  Bronze --> Silver
  Silver --> Quality[Quality_Gate]
  Quality --> Gold
  Gold --> Mart
```

## Failure handling

- Block downstream on upstream failure
- Allow partial partition success with quarantine tables
- Document explicit vs implicit dependencies in catalog
'@
    "02.02.01_Batch_Transformation\02.02.01.04_Architecture_Patterns\02.02.01.04.01_ETL_ELT\02.02.01.04.01.02_Batch_Design_Patterns.md" = @'
---
title: Batch Design Patterns
section: "02.02.01.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [batch, patterns, etl]
canonical: true
---
# Batch Design Patterns

## Core patterns

| Pattern | Description |
| --- | --- |
| **Full refresh** | Rebuild table each run; simple, costly at scale |
| **Incremental append** | New partitions only; requires late-data handling |
| **Merge/upsert** | SCD and CDC silver with business keys |
| **Snapshot** | Point-in-time copy for regulatory reporting |
| **Partition swap** | Build new partition then atomic swap |

## Medallion alignment

- **Bronze**: append-only, minimal transform
- **Silver**: dedup, conform, merge CDC
- **Gold**: aggregate, denormalize for consumption

## Related

- [Medallion Implementation](../../../02.02.04_Shared_Foundations/02.02.04.01_Fundamentals/02.02.04.01.03_Medallion_And_Zones/02.02.04.01.03.01_Medallion_Implementation.md)
'@
}

foreach ($rel in $templates.Keys) {
    $path = Join-Path $Base $rel
    [IO.File]::WriteAllText((Get-LongPath $path), $templates[$rel].TrimEnd() + "`n", $utf8)
    Write-Host "Fixed template: $rel"
}
