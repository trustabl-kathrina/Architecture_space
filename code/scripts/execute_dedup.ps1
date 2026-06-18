param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$MetaDir = Join-Path $DocsRoot "_meta"
$Today = Get-Date -Format "yyyy-MM-dd"

$Stats = @{
    purge_00 = 0
    purge_04 = 0
    purge_case_studies = 0
    purge_redundant_subsections = 0
    canonical_kept = 0
    canonical_redirects = 0
    section02_moves = 0
    reliability_moves = 0
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function Is-Redirect([string]$Text) {
    return ($Text -match '(?m)^status:\s*redirect\s*$')
}

function Get-RelativeLink([string]$FromFile, [string]$ToFile) {
    $fromDir = [IO.Path]::GetDirectoryName((Resolve-Path $FromFile).Path)
    $toPath = (Resolve-Path $ToFile).Path
    $fromUri = New-Object System.Uri(($fromDir.TrimEnd('\') + '\'))
    $toUri = New-Object System.Uri($toPath)
    return [Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString()).Replace('\', '/')
}

function Write-RedirectStub([string]$TargetPath, [string]$CanonicalFullPath, [string]$Title, [string]$Section) {
    if (-not (Test-Path $CanonicalFullPath)) { return $false }
    $rel = Get-RelativeLink $TargetPath $CanonicalFullPath
    $canonicalRel = $CanonicalFullPath.Substring($DocsRoot.Length + 1).Replace('\', '/')
    $content = @"
---
title: $Title
section: "$Section"
status: redirect
template: redirect
last_reviewed: $Today
owner: architecture-team
canonical_path: "$canonicalRel"
---

# $Title

> **Canonical:** [$Title]($rel)

This path is preserved for backward compatibility.
"@
    if (-not $DryRun) {
        Ensure-Dir (Split-Path $TargetPath -Parent)
        [IO.File]::WriteAllText($TargetPath, $content.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    }
    return $true
}

function Parse-FmTitle([string]$Text) {
    if ($Text -match '(?m)^title:\s*(.+)$') { return $Matches[1].Trim().Trim('"') }
    return "Document"
}

function Parse-FmSection([string]$Text) {
    if ($Text -match '(?m)^section:\s*"?([^"`n]+)"?') { return $Matches[1].Trim() }
    return "00"
}

function Remove-FileSafe([string]$Path) {
    if (Test-Path $Path) {
        if (-not $DryRun) { Remove-Item -LiteralPath $Path -Force }
        return $true
    }
    return $false
}

function Has-LegacySegment([string]$RelPath) {
    return ($RelPath -match '(\\|/)(0[1-9]|1[0-9]|2[0-5])\.\d{2}_')
}

function Has-LegacySegmentNot04([string]$RelPath) {
    return ($RelPath -match '(\\|/)(0[1-9]|1[0-9]|2[0-5])\.\d{2}_' -and $RelPath -notmatch '(\\|/)04\.\d{2}_')
}

# Canonical paths (docs-relative, forward slashes)
$CanonicalTopics = @{
    "Governance_Maturity.md"           = "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.10_Governance_Operating_Model/Governance_Maturity.md"
    "Governance_Operating_Model.md"  = "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.10_Governance_Operating_Model/Governance_Operating_Model.md"
    "Compliance_Framework.md"          = "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.09_Data_Compliance/Compliance_Framework.md"
    "Showback_Model.md"                = "04_Cloud_Data_Platforms/04.06_FinOps/Showback_Model.md"
    "Chargeback_Model.md"              = "04_Cloud_Data_Platforms/04.06_FinOps/Chargeback_Model.md"
}

# High-duplication topics: keep best complete doc in owning section, redirect/delete others
$HighDupTopics = @(
    "Governance_Maturity.md"
    "Compliance_Framework.md"
    "Showback_Model.md"
    "Chargeback_Model.md"
    "Governance_Automation.md"
    "Change_Management.md"
    "Governance_Dashboards.md"
    "Governance_Metrics.md"
    "Governance_Operating_Model.md"
    "Platform_Maturity.md"
    "Vendor_Scorecards.md"
    "Platform_Scorecards.md"
    "SLA_Management.md"
    "Incident_Management.md"
    "Active_Metadata.md"
)

Write-Host "Phase 0: establish canonical documents"
$govSource = Join-Path $DocsRoot "00_Architecture_Governance\00.10_Data_Governance_And_Metadata\00.10.01_Metadata_Management\08.02_Governance_Strategy\Governance_Maturity.md"
$govDest = Join-Path $DocsRoot "00_Architecture_Governance\00.10_Data_Governance_And_Metadata\00.10.10_Governance_Operating_Model\Governance_Maturity.md"
if (Test-Path $govSource) {
    Ensure-Dir (Split-Path $govDest -Parent)
    if (-not $DryRun) { Copy-Item -LiteralPath $govSource -Destination $govDest -Force }
    $CanonicalTopics["Governance_Maturity.md"] = "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.10_Governance_Operating_Model/Governance_Maturity.md"
}

$showbackSource = Join-Path $DocsRoot "04_Cloud_Data_Platforms\04.06_FinOps\18.12_Cost_Allocation_And_Chargeback\Showback_Model.md"
$showbackDest = Join-Path $DocsRoot "04_Cloud_Data_Platforms\04.06_FinOps\Showback_Model.md"
if (Test-Path $showbackSource) {
    Ensure-Dir (Split-Path $showbackDest -Parent)
    if (-not $DryRun) { Copy-Item -LiteralPath $showbackSource -Destination $showbackDest -Force }
}

Write-Host "Phase 1: purge nested legacy in section 00"
Get-ChildItem (Join-Path $DocsRoot "00_Architecture_Governance") -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    if ($rel -match '(\\|/)(0[1-9]|1[0-9]|2[0-5])\.\d{2}_') {
        if (Remove-FileSafe $_.FullName) { $Stats.purge_00++ }
    }
}

Write-Host "  Removed: $($Stats.purge_00)"

Write-Host "Phase 2: purge nested legacy inside section 04 (non-04.xx trees)"
Get-ChildItem (Join-Path $DocsRoot "04_Cloud_Data_Platforms") -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    if ($rel -match '04_Cloud_Data_Platforms\\04\.0[1-6]\\' -and $rel -match '(\\|/)(0[1-9]|1[0-9]|2[0-5])\.\d{2}_' -and $rel -notmatch '(\\|/)04\.\d{2}_') {
        if (Remove-FileSafe $_.FullName) { $Stats.purge_04++ }
    }
}

Write-Host "  Removed: $($Stats.purge_04)"

Write-Host "Phase 3: remove redundant subsections (08.03, 11.05, 11.06)"
$redundantDirs = @(
    "08_Analytics_Architecture\08.03_Real_Time_Analytics"
    "11_AI_Data_Architecture\11.05_MCP"
    "11_AI_Data_Architecture\11.06_A2A"
)
foreach ($d in $redundantDirs) {
    $full = Join-Path $DocsRoot $d
    if (Test-Path $full) {
        $count = (Get-ChildItem $full -Recurse -File -ErrorAction SilentlyContinue).Count
        if (-not $DryRun) { Remove-Item -LiteralPath $full -Recurse -Force }
        $Stats.purge_redundant_subsections += $count
    }
}

Write-Host "  Removed files in redundant subsections: $($Stats.purge_redundant_subsections)"

Write-Host "Phase 4: purge duplicate case study folders outside section 15"
Get-ChildItem $DocsRoot -Recurse -Directory | Where-Object {
    $_.Name -match 'Case_Studies$' -and $_.FullName -notmatch '15_Industry_Reference_Architectures'
} | ForEach-Object {
    Get-ChildItem $_.FullName -Recurse -File -Filter *.md | ForEach-Object {
        if (Remove-FileSafe $_.FullName) { $Stats.purge_case_studies++ }
    }
    if (-not $DryRun -and (Test-Path $_.FullName)) {
        $remaining = Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue
        if (-not $remaining) { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "  Removed case study files: $($Stats.purge_case_studies)"

Write-Host "Phase 5: resolve duplicate filenames (canonical ownership)"
foreach ($topic in $HighDupTopics) {
    if (-not $CanonicalTopics.ContainsKey($topic)) { continue }
    $canonicalRel = $CanonicalTopics[$topic]
    $canonicalPath = Join-Path $DocsRoot ($canonicalRel -replace '/', '\')
    if (-not (Test-Path $canonicalPath)) { continue }

    Get-ChildItem $DocsRoot -Recurse -Filter $topic -File | Where-Object {
        $_.FullName -notmatch '\\_meta\\|\\_hubs\\'
    } | ForEach-Object {
        if ($_.FullName -eq $canonicalPath) {
            $Stats.canonical_kept++
            return
        }
        $text = if (Test-Path $_.FullName) { [IO.File]::ReadAllText($_.FullName) } else { "" }
        if (Is-Redirect $text) { return }
        $title = Parse-FmTitle $text
        $section = Parse-FmSection $text
        if (Write-RedirectStub $_.FullName $canonicalPath $title $section) {
            $Stats.canonical_redirects++
        }
    }
}

# Vendor scorecards only in section 17
Write-Host "Phase 5b: vendor/platform scorecards -> section 17 only"
@("Vendor_Scorecards.md", "Platform_Scorecards.md") | ForEach-Object {
    $name = $_
    Get-ChildItem $DocsRoot -Recurse -Filter $name -File | Where-Object {
        $_.FullName -notmatch '17_Technology_Comparisons' -and $_.FullName -notmatch '\\_meta\\'
    } | ForEach-Object {
        if (Remove-FileSafe $_.FullName) { $Stats.canonical_redirects++ }
    }
}

Write-Host "  Canonical kept: $($Stats.canonical_kept) Redirects: $($Stats.canonical_redirects)"

Write-Host "Phase 6: reorganize section 02 legacy folders"
$deRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture"
$ingestRoot = Join-Path $deRoot "02.01_Data_Ingestion_Architecture"
$map02 = @{
    "04.03_Data_Ingestion"       = "02.01_Data_Ingestion_Architecture"
    "04.08_CDC_Architecture"     = "02.01_Data_Ingestion_Architecture"
    "04.04_Data_Transformation"  = "02.02_Data_Transformation_Architecture"
    "04.06_Batch_Processing"     = "02.02_Data_Transformation_Architecture"
    "04.11_Lakehouse_Engineering" = "02.02_Data_Transformation_Architecture"
    "04.09_DataOps"              = "02.03_Data_Orchestration_Architecture"
    "04.10_Workflow_Orchestration" = "02.03_Data_Orchestration_Architecture"
    "04.12_Metadata_Driven_Engineering" = "02.03_Data_Orchestration_Architecture"
    "04.18_Platform_Engineering" = "02.03_Data_Orchestration_Architecture"
}

foreach ($entry in $map02.GetEnumerator()) {
    $srcDir = Join-Path $ingestRoot $entry.Key
    $destDir = Join-Path $deRoot $entry.Value
    if (-not (Test-Path $srcDir)) { continue }
    Get-ChildItem $srcDir -Recurse -File -Filter *.md | ForEach-Object {
        $rel = $_.FullName.Substring($srcDir.Length + 1)
        $dest = Join-Path $destDir $rel
        if (Test-Path $dest) {
            if (Remove-FileSafe $_.FullName) { $Stats.section02_moves++ }
        }
        else {
            Ensure-Dir (Split-Path $dest -Parent)
            if (-not $DryRun) { Move-Item -LiteralPath $_.FullName -Destination $dest -Force }
            $Stats.section02_moves++
        }
    }
}

# Move overview/strategy/governance/maturity/case studies - keep in 02.01 or delete case studies already done
$keepIn201 = @("04.01_Overview", "04.02_Data_Engineering_Strategy", "04.05_Data_Pipeline_Architecture",
    "04.13_Data_Quality_Engineering", "04.17_Enterprise_Data_Frameworks", "04.19_Performance_Optimization",
    "04.20_Cost_Optimization", "04.21_AI_Assisted_Data_Engineering", "04.22_Reference_Architectures",
    "04.23_Data_Engineering_Governance", "04.24_Data_Engineering_Maturity")

# Reliability topics from 02.04 -> 02.05
$reliabilityNames = @(
    "Reliability_Architecture.md", "Reliability_Engineering.md", "Reliability_Metrics.md", "Reliability_Scorecard.md",
    "Resilience_Patterns.md", "Recovery_Strategies.md", "Disaster_Recovery.md", "DRE_Framework.md",
    "Error_Budget_Framework.md", "SLO_Framework.md", "SLO_Management.md", "SLA_Framework.md", "SLA_Monitoring.md",
    "RCA_Framework.md", "Root_Cause_Analysis.md", "Failure_Analysis.md", "Incident_Management.md"
)
$obsRoot = Join-Path $deRoot "02.04_Data_Observability_Architecture"
$relRoot = Join-Path $deRoot "02.05_Data_Reliability_Architecture"
Ensure-Dir $relRoot
foreach ($name in $reliabilityNames) {
    $src = Join-Path $obsRoot $name
    if (-not (Test-Path $src)) { continue }
    $dest = Join-Path $relRoot $name
    if (Test-Path $dest) { Remove-FileSafe $src }
    else {
        if (-not $DryRun) { Move-Item -LiteralPath $src -Destination $dest -Force }
        $Stats.reliability_moves++
    }
}

Write-Host "  Section 02 moves: $($Stats.section02_moves) Reliability moves: $($Stats.reliability_moves)"

Write-Host "Phase 7: cleanup empty legacy directories"
if (-not $DryRun) {
    foreach ($sec in @("00_Architecture_Governance", "04_Cloud_Data_Platforms", "02_Data_Engineering_Architecture")) {
        $base = Join-Path $DocsRoot $sec
        if (-not (Test-Path $base)) { continue }
        for ($i = 0; $i -lt 8; $i++) {
            Get-ChildItem $base -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
                $children = Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue
                if (-not $children) {
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

Write-Host "Phase 8: deduplication report"
$totalMd = (Get-ChildItem $DocsRoot -Recurse -Filter *.md | Where-Object {
    $_.Name -ne 'README.md' -and $_.FullName -notmatch '\\_meta\\|\\_hubs\\'
}).Count
$redirects = (Get-ChildItem $DocsRoot -Recurse -Filter *.md | Where-Object {
    $t = [IO.File]::ReadAllText($_.FullName); $t -match '(?m)^status:\s*redirect'
}).Count

$report = @(
    "# Deduplication Execution Report",
    "",
    "Generated on $Today.",
    "",
    "| Action | Count |",
    "| --- | ---: |",
    "| Purged nested legacy in section 00 | $($Stats.purge_00) |",
    "| Purged nested legacy in section 04 | $($Stats.purge_04) |",
    "| Removed redundant subsections | $($Stats.purge_redundant_subsections) |",
    "| Removed duplicate case studies | $($Stats.purge_case_studies) |",
    "| Canonical redirects written | $($Stats.canonical_redirects) |",
    "| Section 02 file moves | $($Stats.section02_moves) |",
    "| Reliability moves to 02.05 | $($Stats.reliability_moves) |",
    "| Remaining topic files | $totalMd |",
    "| Redirect stubs | $redirects |",
    ""
)
if (-not $DryRun) {
    [IO.File]::WriteAllText((Join-Path $MetaDir "deduplication_execution_report.md"), ($report -join "`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host "Done. Remaining topics: $totalMd Redirects: $redirects"
if ($DryRun) { Write-Host "(Dry run)" }
