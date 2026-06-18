param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$SecRoot = Join-Path $DocsRoot "09_Event_And_Streaming_Architecture"
$MetaDir = Join-Path $DocsRoot "_meta"
$MapFile = Join-Path $MetaDir "section_09_migration_map.yaml"
$Today = Get-Date -Format "yyyy-MM-dd"

$Stats = @{
    scaffolded_dirs = 0
    moved = 0
    redirects = 0
    stubs_created = 0
    removed = 0
    front_matter_fixed = 0
    placeholder_stripped = 0
    empty_dirs_removed = 0
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
        $script:Stats.scaffolded_dirs++
    }
}

function Get-RelativeLink([string]$FromFile, [string]$ToFile) {
    $fromDir = [IO.Path]::GetDirectoryName((Resolve-Path $FromFile).Path)
    $toPath = (Resolve-Path $ToFile).Path
    $fromUri = New-Object System.Uri(($fromDir.TrimEnd('\') + '\'))
    $toUri = New-Object System.Uri($toPath)
    return [Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString()).Replace('\', '/')
}

function Parse-FmTitle([string]$Text) {
    if ($Text -match '(?m)^title:\s*(.+)$') { return $Matches[1].Trim().Trim('"') }
    return "Document"
}

function Infer-Section([string]$RelPath) {
    if ($RelPath -match '(^|[\\/])(\d{2}\.\d{2})([\\/]|$)') { return $Matches[2] }
    return "09"
}

function Is-Redirect([string]$Text) {
    return ($Text -match '(?m)^status:\s*redirect\s*$' -or $Text -match '(?m)^template:\s*redirect\s*$')
}

function Get-StatusRank([string]$Status) {
    $r = @{ stub = 0; archived = 0; draft = 1; review = 2; complete = 3; redirect = -1 }
    $s = if ($Status) { $Status.Trim() } else { "stub" }
    if ($r.ContainsKey($s)) { return $r[$s] }
    return 0
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

function Write-StubDoc([string]$Path, [string]$Title, [string]$Section, [string]$Template = "overview") {
    $content = @"
---
title: $Title
section: "$Section"
status: stub
template: $Template
last_reviewed: $Today
owner: architecture-team
tags: [streaming, events]
canonical: true
---

# $Title

> Status: stub — content planned as part of section 09 consolidation.

## Context

Enterprise reference for event and streaming architecture.

## Related

- [Section 09 README](../../README.md)
"@
  if (-not $DryRun) {
    Ensure-Dir (Split-Path $Path -Parent)
    [IO.File]::WriteAllText($Path, $content.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
  }
  $script:Stats.stubs_created++
}

function Move-FileSafe([string]$Src, [string]$Dest) {
    if (-not (Test-Path $Src)) { return $false }
    if ($Src -eq $Dest) { return $false }
    Ensure-Dir (Split-Path $Dest -Parent)
    if (Test-Path $Dest) {
        $srcText = [IO.File]::ReadAllText($Src)
        $destText = [IO.File]::ReadAllText($Dest)
        if (Is-Redirect $srcText) {
            if (-not $DryRun) { Remove-Item -LiteralPath $Src -Force }
            return $false
        }
        $srcRank = 0; $destRank = 0
        if ($srcText -match '(?m)^status:\s*(\S+)') { $srcRank = Get-StatusRank $Matches[1] }
        if ($destText -match '(?m)^status:\s*(\S+)') { $destRank = Get-StatusRank $Matches[1] }
        if ($srcRank -gt $destRank) {
            if (-not $DryRun) { Remove-Item -LiteralPath $Dest -Force; Move-Item -LiteralPath $Src -Destination $Dest -Force }
        }
        else {
            if (-not $DryRun) { Remove-Item -LiteralPath $Src -Force }
        }
    }
    else {
        if (-not $DryRun) { Move-Item -LiteralPath $Src -Destination $Dest -Force }
    }
    $script:Stats.moved++
    return $true
}

function Title-FromFilename([string]$Name) {
    $base = [IO.Path]::GetFileNameWithoutExtension($Name)
    return ($base -replace '_', ' ')
}

# Parse YAML map (minimal parser)
$yaml = [IO.File]::ReadAllText($MapFile)
$canonicalTargets = @()
$inCanonical = $false
foreach ($line in ($yaml -split "`r?`n")) {
    if ($line -match '^canonical_targets:') { $inCanonical = $true; continue }
    if ($inCanonical -and $line -match '^\s+-\s+(.+)$') { $canonicalTargets += $Matches[1].Trim() }
    elseif ($inCanonical -and $line -match '^[a-z_]+:') { $inCanonical = $false }
}

$fileMoves = @()
$inMoves = $false
foreach ($line in ($yaml -split "`r?`n")) {
    if ($line -match '^file_moves:') { $inMoves = $true; continue }
    if ($inMoves -and $line -match '^  - from:\s*(.+)$') { $cur = @{ from = $Matches[1].Trim() } }
    elseif ($inMoves -and $line -match '^\s+to:\s*(.+)$') {
        $cur.to = $Matches[1].Trim()
        $fileMoves += [PSCustomObject]$cur
    }
    elseif ($inMoves -and $line -match '^[a-z_]+:' -and $line -notmatch '^\s+') { $inMoves = $false }
}

$folderRedirects = @{}
$inFolder = $false
foreach ($line in ($yaml -split "`r?`n")) {
    if ($line -match '^folder_redirects:') { $inFolder = $true; continue }
    if ($inFolder -and $line -match '^\s+(\w+):\s*(.+)$') { $folderRedirects[$Matches[1]] = $Matches[2].Trim() }
    elseif ($inFolder -and $line -match '^[a-z_]+:' -and $line -notmatch '^\s+') { $inFolder = $false }
}

$filenameRedirects = @{}
$inFn = $false
foreach ($line in ($yaml -split "`r?`n")) {
    if ($line -match '^filename_redirects:') { $inFn = $true; continue }
    if ($inFn -and $line -match '^\s+(\S+):\s*(.+)$') { $filenameRedirects[$Matches[1]] = $Matches[2].Trim() }
    elseif ($inFn -and $line -match '^[a-z_]+:' -and $line -notmatch '^\s+') { $inFn = $false }
}

$groupCanonical = @{}
$inGroup = $false
foreach ($line in ($yaml -split "`r?`n")) {
    if ($line -match '^group_canonical:') { $inGroup = $true; continue }
    if ($inGroup -and $line -match '^\s+(\w+):\s*(.+)$') { $groupCanonical[$Matches[1]] = $Matches[2].Trim() }
    elseif ($inGroup -and $line -match '^[a-z_]+:' -and $line -notmatch '^\s+') { $inGroup = $false }
}

Write-Host "Phase 0: scaffold target tree"
foreach ($rel in $canonicalTargets) {
    $full = Join-Path $SecRoot ($rel -replace '/', '\')
    Ensure-Dir (Split-Path $full -Parent)
}
foreach ($sub in @("09.01_Fundamentals","09.02_Cloud_Services","09.03_Open_Source","09.04_Architecture_Patterns","09.05_Benchmarks","09.06_Comparisons","09.07_Interview_Questions","09.08_Integration_Patterns")) {
    $readme = Join-Path $SecRoot "$sub\README.md"
    if (-not (Test-Path $readme)) {
        $sid = if ($sub -match '^(\d{2}\.\d{2})') { $Matches[1] } else { "09" }
        $title = ($sub -replace '^\d{2}\.\d{2}_', '') -replace '_', ' '
        $body = @"
---
title: $title README
section: "$sid"
status: stub
template: overview
last_reviewed: $Today
owner: architecture-team
tags: [streaming]
canonical: true
---

# $title

Subsection index for section 09 Event and Streaming Architecture.
"@
        if (-not $DryRun) {
            [IO.File]::WriteAllText($readme, $body.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
        }
    }
}

Write-Host "Phase 1: execute file moves"
foreach ($m in $fileMoves) {
    $src = Join-Path $SecRoot ($m.from -replace '/', '\')
    $dest = Join-Path $SecRoot ($m.to -replace '/', '\')
    Move-FileSafe $src $dest
}

Write-Host "Phase 2: create missing canonical stubs"
foreach ($rel in $canonicalTargets) {
    $full = Join-Path $SecRoot ($rel -replace '/', '\')
    if (-not (Test-Path $full)) {
        $sec = Infer-Section $rel
        $title = Title-FromFilename (Split-Path $full -Leaf)
        $tpl = if ($rel -match 'Benchmark|Comparison|Interview') { "evaluation" } elseif ($rel -match 'Pattern|CQRS|Saga') { "concept" } else { "overview" }
        Write-StubDoc $full $title $sec $tpl
    }
}

# Special merges for CDC patterns
$cdcOverview = Join-Path $SecRoot "09.01_Fundamentals\CDC_Architecture\CDC_Overview.md"
$cdcPatterns = Join-Path $SecRoot "09.01_Fundamentals\CDC_Architecture\Change_Data_Capture_Patterns.md"
if (-not (Test-Path $cdcPatterns)) {
    Write-StubDoc $cdcPatterns "Change Data Capture Patterns" "09.01" "concept"
}
$outbox = Join-Path $SecRoot "09.01_Fundamentals\CDC_Architecture\Outbox_Pattern.md"
if (-not (Test-Path $outbox)) { Write-StubDoc $outbox "Outbox Pattern" "09.01" "concept" }

Write-Host "Phase 3: delete non-canonical files (redirects not retained)"
$canonicalSet = @{}
foreach ($rel in $canonicalTargets) { $canonicalSet[$rel.Replace('/', '\').ToLowerInvariant()] = $true }

function Resolve-CanonicalForFile([string]$RelFromSec, [string]$FileName) {
    $relNorm = $RelFromSec.Replace('/', '\')
    if ($filenameRedirects.ContainsKey($FileName)) {
        return Join-Path $DocsRoot ($filenameRedirects[$FileName] -replace '/', '\')
    }
    foreach ($seg in ($relNorm -split '\\')) {
        if ($groupCanonical.ContainsKey($seg)) {
            return Join-Path $SecRoot ($groupCanonical[$seg] -replace '/', '\')
        }
        if ($folderRedirects.ContainsKey($seg)) {
            return Join-Path $DocsRoot ($folderRedirects[$seg] -replace '/', '\')
        }
    }
    $base = [IO.Path]::GetFileNameWithoutExtension($FileName)
    foreach ($c in $canonicalTargets) {
        if ((Split-Path $c -Leaf) -ieq $FileName) {
            return Join-Path $SecRoot ($c -replace '/', '\')
        }
        if (([IO.Path]::GetFileNameWithoutExtension($c)) -ieq $base) {
            return Join-Path $SecRoot ($c -replace '/', '\')
        }
    }
    return Join-Path $SecRoot "09.01_Fundamentals\Overview\What_Is_Event_Driven_Architecture.md"
}

Get-ChildItem $SecRoot -Recurse -Filter *.md | Where-Object {
    $_.Name -ne 'README.md' -and $_.FullName -notmatch '\\README\.md$'
} | ForEach-Object {
    $relFromSec = $_.FullName.Substring($SecRoot.Length + 1)
    $key = $relFromSec.ToLowerInvariant()
    if ($canonicalSet.ContainsKey($key)) { return }

    $text = [IO.File]::ReadAllText($_.FullName)
    if (Is-Redirect $text) {
        if (-not $DryRun) { Remove-Item -LiteralPath $_.FullName -Force }
        $Stats.removed++
        return
    }

    if (-not $DryRun) { Remove-Item -LiteralPath $_.FullName -Force }
    $Stats.removed++
}

Write-Host "Phase 4: fix front matter and strip legacy placeholders"
Get-ChildItem $SecRoot -Recurse -Filter *.md | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
    $rel = $_.FullName.Substring($SecRoot.Length + 1)
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') { return }
    $fm = $Matches[1]
    $body = $Matches[2]
    $changed = $false

    $expected = Infer-Section ($rel -replace '\\', '/')
    if ($fm -match '(?m)^section:\s*"?([^"`n]+)"?') {
        if ($Matches[1].Trim() -ne $expected) {
            $fm = $fm -replace '(?m)^section:\s*"?[^"`n]+"?', "section: `"$expected`""
            $changed = $true
        }
    }

    if ($body -match '04\.07 Streaming Architecture') {
        $body = $body -replace '04\.07 Streaming Architecture', 'Event and Streaming Architecture'
        $changed = $true
        $Stats.placeholder_stripped++
    }

    if ($changed -and -not $DryRun) {
        [IO.File]::WriteAllText($_.FullName, "---`n$fm`n---`n$body".TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
        $Stats.front_matter_fixed++
    }
}

Write-Host "Phase 5: cleanup empty directories"
if (-not $DryRun) {
    for ($i = 0; $i -lt 12; $i++) {
        Get-ChildItem $SecRoot -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
            $children = Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue
            if (-not $children) {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                $Stats.empty_dirs_removed++
            }
        }
    }
}

$topics = (Get-ChildItem $SecRoot -Recurse -Filter *.md | Where-Object { $_.Name -ne 'README.md' }).Count
$redirects = (Get-ChildItem $SecRoot -Recurse -Filter *.md | Where-Object {
    $t = [IO.File]::ReadAllText($_.FullName); Is-Redirect $t
}).Count
$complete = (Get-ChildItem $SecRoot -Recurse -Filter *.md | Where-Object {
    $t = [IO.File]::ReadAllText($_.FullName); $t -match '(?m)^status:\s*complete\s*$'
}).Count

$report = @(
    "# Section 09 Consolidation Report",
    "",
    "Generated on $Today.",
    "",
    "| Metric | Value |",
    "| --- | ---: |",
    "| Directories scaffolded | $($Stats.scaffolded_dirs) |",
    "| Files moved | $($Stats.moved) |",
    "| Redirects written | $($Stats.redirects) |",
    "| Stubs created | $($Stats.stubs_created) |",
    "| Non-canonical removed | $($Stats.removed) |",
    "| Front matter fixes | $($Stats.front_matter_fixed) |",
    "| Placeholder strips | $($Stats.placeholder_stripped) |",
    "| Empty dirs removed | $($Stats.empty_dirs_removed) |",
    "| Total topic files | $topics |",
    "| Redirect stubs | $redirects |",
    "| Complete docs | $complete |",
    ""
)

if (-not $DryRun) {
    [IO.File]::WriteAllText((Join-Path $MetaDir "section_09_consolidation_report.md"), ($report -join "`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host "Done. Topics=$topics Redirects=$redirects Complete=$complete"
if ($DryRun) { Write-Host "(Dry run)" }
