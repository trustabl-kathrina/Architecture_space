param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$PocSection = Join-Path $DocsRoot "18_POCs_And_Benchmarks"
$Today = Get-Date -Format "yyyy-MM-dd"
$Stats = @{ moved = 0; merged = 0; cleaned = 0; deleted = 0 }

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function Get-Body([string]$Text) {
    if ($Text -match '(?s)^---\s*\r?\n.*?\r?\n---\s*\r?\n(.*)$') { return $Matches[1].Trim() }
    return $Text.Trim()
}

function Update-FrontMatter([string]$Text, [string]$Section, [string]$Template = "") {
    if ($Text -notmatch '(?s)^(---\s*\r?\n.*?\r?\n---\s*\r?\n)') { return $Text }
    $fm = $Matches[1]
    $body = $Text.Substring($Matches[1].Length)
    $fm = $fm -replace '(?m)^section:\s*".*"', "section: `"$Section`""
    if ($Template) { $fm = $fm -replace '(?m)^template:\s*\S+', "template: $Template" }
    $fm = $fm -replace '(?m)^last_reviewed:\s*\S+', "last_reviewed: $Today"
    $body = $body -replace '(?m)^> \*\*Canonical copy\*\*.*\r?\n\r?\n', ''
    $body = $body -replace '(?m)^> \*\*Canonical version:\*\*.*\r?\n', ''
    return $fm + $body
}

function Write-Doc([string]$Dest, [string]$Content) {
    Ensure-Dir (Split-Path $Dest -Parent)
    if (-not $DryRun) {
        [IO.File]::WriteAllText($Dest, $Content.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    }
}

function Move-PocFile([string]$SourceRel, [string]$DestRel, [string]$Section, [string]$Template = "") {
    $src = Join-Path $PocSection $SourceRel
    $dest = Join-Path $DocsRoot $DestRel
    if (-not (Test-Path $src)) { return }

    $content = [IO.File]::ReadAllText($src)
    $content = Update-FrontMatter $content $Section $Template

    if (Test-Path $dest) {
        $existing = [IO.File]::ReadAllText($dest)
        $srcRank = if ($content -match '(?m)^status:\s*complete') { 3 } elseif ($content -match '(?m)^status:\s*draft') { 1 } else { 0 }
        $dstRank = if ($existing -match '(?m)^status:\s*complete') { 3 } elseif ($existing -match '(?m)^status:\s*draft') { 1 } else { 0 }
        if ($srcRank -gt $dstRank -or (Get-Body $content).Length -gt (Get-Body $existing).Length) {
            Write-Doc $dest $content
            $Stats.merged++
        }
        else {
            $Stats.merged++
        }
    }
    else {
        Write-Doc $dest $content
        $Stats.moved++
    }
}

function Relocate-IfExists([string]$SourceRel, [string]$DestRel, [string]$Section) {
    $src = Join-Path $DocsRoot $SourceRel
    $dest = Join-Path $DocsRoot $DestRel
    if (-not (Test-Path $src)) { return }
    $content = Update-FrontMatter ([IO.File]::ReadAllText($src)) $Section
    Write-Doc $dest $content
    if (-not $DryRun -and $src -ne $dest) { Remove-Item -LiteralPath $src -Force }
    $Stats.moved++
}

Write-Host "Phase 1: distribute POCs from section 18 to technology sections"

# Streaming benchmarks -> 02.01.02.05_Benchmarks
$streamingBenchmarks = @(
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/04_Watermarks/Watermarks.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Watermarks.md", "02.01.02.05", "concept"),
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/05_Windowing/Windowing.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Windowing.md", "02.01.02.05", "concept"),
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/07_Streaming_Design_Patterns/Streaming_Design_Patterns.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Streaming_Design_Patterns.md", "02.01.02.05", "concept")
)
foreach ($m in $streamingBenchmarks) { Move-PocFile $m[0] $m[1] $m[2] $m[3] }

# Relocate copies already sitting in 02.01.02.01 fundamentals into benchmarks
Relocate-IfExists "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Watermarks.md" "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Watermarks.md" "02.01.02.05"
Relocate-IfExists "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Windowing.md" "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Windowing.md" "02.01.02.05"
Relocate-IfExists "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Streaming_Design_Patterns.md" "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Streaming_Design_Patterns.md" "02.01.02.05"

# Streaming fundamentals (stubs + concepts) -> 02.01.02.01
$streamingFundamentals = @(
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/01_Event_Driven_Architecture/Event_Driven_Architecture.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Event_Driven_Architecture.md", "02.01.02.01"),
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/02_Streaming_vs_Batch/Streaming_vs_Batch.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Streaming_vs_Batch.md", "02.01.02.01"),
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/03_Event_Time_vs_Processing_Time/Event_Time_vs_Processing_Time.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Event_Time_vs_Processing_Time.md", "02.01.02.01"),
    @("18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.01_Fundamentals/06_Exactly_Once_Semantics/Exactly_Once_Semantics.md", "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/Exactly_Once_Semantics.md", "02.01.02.01")
)
foreach ($m in $streamingFundamentals) { Move-PocFile $m[0] $m[1] $m[2] }

# GCP Pub/Sub POC -> cloud streaming services
Move-PocFile "18.01_Streaming/22.04_Data_Engineering/22.04.21_Streaming_Architecture/22.04.21.02_Streaming_Platforms/01_Event_Streaming/01_Cloud_Native/01_GCP/PubSub/PubSub.md" `
    "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.02_Cloud_Services/GCP_PubSub_POC.md" "02.01.02.02" "evaluation"

# RAG / GenAI POC evaluations -> 11.03_RAG
$ragPocs = @(
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/02_Data_Ingestion_Pipeline/01_Document_Parsing.md", "11_AI_Data_Architecture/11.03_RAG/Document_Parsing.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/02_Data_Ingestion_Pipeline/02_Data_Cleaning.md", "11_AI_Data_Architecture/11.03_RAG/Data_Cleaning.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/02_Data_Ingestion_Pipeline/03_Metadata_Extraction.md", "11_AI_Data_Architecture/11.03_RAG/Metadata_Extraction.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/02_Data_Ingestion_Pipeline/04_Data_Pipelines.md", "11_AI_Data_Architecture/11.03_RAG/Data_Pipelines.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/03_Chunking_Strategies/03_Chunking_Strategies.md", "11_AI_Data_Architecture/11.03_RAG/Chunking_Strategies.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/04_Embedding_Models/04_Embedding_Models.md", "11_AI_Data_Architecture/11.03_RAG/Embedding_Models.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/05_Vector_Database_Selection/05_Vector_Database_Selection.md", "11_AI_Data_Architecture/11.03_RAG/Vector_Database_Selection.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/06_Retrieval_Mechanisms/06_Retrieval_Mechanisms.md", "11_AI_Data_Architecture/11.03_RAG/Retrieval_Mechanisms.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/01_RAG_Architecture_Overview/01_RAG_Architecture_Overview.md", "11_AI_Data_Architecture/11.03_RAG/RAG_Architecture_Overview.md", "11.03"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/03_Retrieval_Augmented_Generation_Pattern/03_Retrieval_Augmented_Generation_Pattern.md", "11_AI_Data_Architecture/11.03_RAG/Retrieval_Augmented_Generation_Pattern.md", "11.03")
)
foreach ($m in $ragPocs) { Move-PocFile $m[0] $m[1] $m[2] "evaluation" }

# GenAI architecture stubs -> relevant AI sections
$genaiDistribution = @(
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/01_Overview/01_GenAI_Architecture_Overview.md", "11_AI_Data_Architecture/11.01_AI_Ready_Data_Platform/GenAI_Architecture_Overview.md", "11.01"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/02_Foundation_Model_Strategy/02_Foundation_Model_Strategy.md", "11_AI_Data_Architecture/11.01_AI_Ready_Data_Platform/Foundation_Model_Strategy.md", "11.01"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/04_GenAI_Data_Architecture/04_GenAI_Data_Architecture.md", "11_AI_Data_Architecture/11.01_AI_Ready_Data_Platform/GenAI_Data_Architecture.md", "11.01"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/05_Orchestration_And_Application_Layer/05_Orchestration_And_Application_Layer.md", "11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.12_Agentic_AI_Architecture/11.12.06_Agent_Orchestration/GenAI_Orchestration_And_Application_Layer.md", "11.12.06"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/06_GenAI_Security_And_Guardrails/06_GenAI_Security_And_Guardrails.md", "14_Security_And_Privacy_Architecture/14.08_AI_Security/GenAI_Security_And_Guardrails.md", "14.08"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/07_GenAI_Infrastructure_And_FinOps/07_GenAI_Infrastructure_And_FinOps.md", "11_AI_Data_Architecture/11.11_AI_FinOps/GenAI_Infrastructure_And_FinOps.md", "11.11"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/08_GenAI_Evaluation_And_Observability/08_GenAI_Evaluation_And_Observability.md", "11_AI_Data_Architecture/11.10_AI_Observability/GenAI_Evaluation_And_Observability.md", "11.10"),
    @("18.01_Streaming/22.06_AI_Architecture/22.06.14_Generative_AI_Architecture/09_Reference_Architectures/09_Reference_Architectures.md", "11_AI_Data_Architecture/11.01_AI_Ready_Data_Platform/GenAI_Reference_Architectures.md", "11.01")
)
foreach ($m in $genaiDistribution) { Move-PocFile $m[0] $m[1] $m[2] }

Write-Host "  Moved: $($Stats.moved) Merged: $($Stats.merged)"

Write-Host "Phase 2: clean stale POC migration notes across docs/"
$notePatterns = @(
    '(?m)^> \*\*Canonical copy\*\* migrated from \[POC source\]\([^)]+\)\. See also section 22 for POC benchmark details\.\r?\n\r?\n',
    '(?m)^> \*\*Canonical copy\*\* migrated from \[POC source\]\([^)]+\)\.[^\r\n]*\r?\n\r?\n',
    '(?m)^> \*\*Canonical version:\*\* See migrated copy in the canonical architecture section\.\r?\n'
)
Get-ChildItem $DocsRoot -Recurse -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.FullName -match '\\18_POCs_And_Benchmarks\\') { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    $original = $text
    foreach ($p in $notePatterns) { $text = $text -replace $p, '' }
    $text = $text -replace '\[22 POCs\]\([^)]*22_POCs[^)]*\)', '[technology section POCs](../_meta/poc_index.md)'
    $text = $text -replace '\[22 POCs_And_Benchmarking\]\([^)]+\)', '[POC index](../_meta/poc_index.md)'
    $text = $text -replace 'Internal POC benchmarks should be recorded in \[22 POCs\]\([^)]+\) and linked here\.', 'Internal POC benchmarks are recorded in the relevant technology section under POCs and Benchmarks.'
    if ($text -ne $original) {
        if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) }
        $Stats.cleaned++
    }
}

Write-Host "  Cleaned: $($Stats.cleaned) files"

Write-Host "Phase 3: write distributed POC index"
$pocIndex = @"
# POC and Benchmark Index

Generated on $Today.

POCs and benchmarks are distributed by technology domain — not centralized in a single section.

## Streaming and event processing

- [09 Event and Streaming Architecture](../02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming/README.md)
  - [Benchmarks](../02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/Watermarks.md) — Watermarks, Windowing, design patterns
  - [Cloud services](../02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.02_Cloud_Services/GCP_PubSub_POC.md) — GCP Pub/Sub POC

## AI, RAG, and GenAI

- [11 AI Data Architecture](../11_AI_Data_Architecture/README.md)
  - [RAG evaluations](../11_AI_Data_Architecture/11.03_RAG/Document_Parsing.md) — document parsing, embeddings, vector DB, retrieval
  - [AI FinOps](../11_AI_Data_Architecture/11.11_AI_FinOps/GenAI_Infrastructure_And_FinOps.md)
  - [AI observability](../11_AI_Data_Architecture/11.10_AI_Observability/GenAI_Evaluation_And_Observability.md)

## Agentic AI and security

- [12 Agentic AI Architecture](../11_AI_Data_Architecture/11.12_Agentic_AI_Architecture/11.12.06_Agent_Orchestration/GenAI_Orchestration_And_Application_Layer.md)
- [14 Security and Privacy](../14_Security_And_Privacy_Architecture/14.08_AI_Security/GenAI_Security_And_Guardrails.md)

## Technology comparisons

Vendor evaluations in [17 Technology Comparisons](../17_Technology_Comparisons/README.md) link to domain POCs above.
"@
Write-Doc (Join-Path $DocsRoot "_meta/poc_index.md") $pocIndex

$benchReadme = @"
---
title: Streaming Benchmarks
section: "02.01.02.05"
status: complete
template: overview
last_reviewed: $Today
owner: architecture-team
tags: [streaming, benchmarks, poc]
canonical: true
---

# Streaming Benchmarks and POCs

Hands-on streaming architecture evaluations and benchmark notes for event-driven platforms.

## Documents

- [Watermarks](Watermarks.md)
- [Windowing](Windowing.md)
- [Streaming Design Patterns](Streaming_Design_Patterns.md)

## Related

- [Event and Streaming Architecture](../README.md)
- [POC Index](../../_meta/poc_index.md)
"@
Write-Doc (Join-Path $DocsRoot "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/README.md") $benchReadme

Write-Host "Phase 4: remove central POC section"
if (Test-Path $PocSection) {
    if (-not $DryRun) { Remove-Item -LiteralPath $PocSection -Recurse -Force }
    $Stats.deleted++
}

Write-Host "Done. Moved=$($Stats.moved) Merged=$($Stats.merged) Cleaned=$($Stats.cleaned) Section18Removed=$($Stats.deleted)"
