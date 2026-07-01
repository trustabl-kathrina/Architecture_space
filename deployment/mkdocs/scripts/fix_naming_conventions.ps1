param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$MetaDir = Join-Path $DocsRoot "_meta"
$Today = Get-Date -Format "yyyy-MM-dd"

$Stats = @{
    folders_renamed = 0
    section02_moves = 0
    cross_section_moves = 0
    front_matter_fixed = 0
    empty_dirs_removed = 0
    collisions = 0
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function Get-SectionIdFromPath([string]$RelPath) {
    if ($RelPath -match '^(\d{2})_') { return $Matches[1] }
    return $null
}

function Get-SubsectionId([string]$RelPath) {
    if ($RelPath -match '^(\d{2})_[^\\/]+[\\/](\d{2}\.\d{2}_[^\\/]+)') { return $Matches[2] }
    return $null
}

function Strip-LegacyFolderName([string]$Name, [string]$ParentSectionId) {
    if ($Name -match '^(\d{2})\.(\d{2})_(.+)$') {
        if ($Matches[1] -ne $ParentSectionId) { return $Matches[3] }
    }
    if ($Name -match '^(\d{2})_(.+)$') {
        if ($Matches[1] -ne $ParentSectionId) { return $Matches[2] }
    }
    return $null
}

function Is-LegacyFolderName([string]$Name, [string]$ParentSectionId) {
    return $null -ne (Strip-LegacyFolderName $Name $ParentSectionId)
}

function Infer-SectionFromRel([string]$RelPath) {
    if ($RelPath -match '(^|[\\/])(\d{2}\.\d{2})([\\/]|$)') { return $Matches[2] }
    if ($RelPath -match '^(\d{2})_') { return $Matches[1] }
    return "00"
}

function Move-FileSafe([string]$Src, [string]$Dest) {
    if (-not (Test-Path $Src)) { return $false }
    if (Test-Path $Dest) {
        $Stats.collisions++
        if (-not $DryRun) { Remove-Item -LiteralPath $Src -Force }
        return $false
    }
    Ensure-Dir (Split-Path $Dest -Parent)
    if (-not $DryRun) { Move-Item -LiteralPath $Src -Destination $Dest -Force }
    return $true
}

function Rename-DirSafe([string]$Src, [string]$Dest) {
    if (-not (Test-Path $Src)) { return $false }
    if (Test-Path $Dest) { return $false }
    Ensure-Dir (Split-Path $Dest -Parent)
    if (-not $DryRun) { Rename-Item -LiteralPath $Src -NewName (Split-Path $Dest -Leaf) }
    return $true
}

# Section 02 topic groups -> target subsection (after legacy prefix strip)
$DeTopicGroupMap = @{
    "Overview"                      = "02.01_Data_Ingestion_Architecture"
    "Data_Engineering_Strategy"     = "02.01_Data_Ingestion_Architecture"
    "Data_Pipeline_Architecture"    = "02.01_Data_Ingestion_Architecture"
    "Enterprise_Data_Frameworks"    = "02.01_Data_Ingestion_Architecture"
    "Reference_Architectures"       = "02.01_Data_Ingestion_Architecture"
    "Data_Quality_Engineering"      = "02.04_Data_Observability_Architecture"
    "Performance_Optimization"      = "02.02_Data_Transformation_Architecture"
    "AI_Assisted_Data_Engineering"  = "02.03_Data_Orchestration_Architecture"
    "Data_Engineering_Governance"   = "02.03_Data_Orchestration_Architecture"
    "Data_Engineering_Maturity"     = "02.04_Data_Observability_Architecture"
}

# Cost optimization belongs in cloud FinOps
$CrossSectionMoves = @{
    "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture\Cost_Optimization" = "04_Cloud_Data_Platforms\04.06_FinOps\Cost_Optimization"
}

Write-Host "Phase 1: rename nested legacy folders (strip foreign NN / NN.SS prefixes)"

$allDirs = Get-ChildItem $DocsRoot -Recurse -Directory |
    Where-Object { $_.FullName -notmatch '\\_meta\\|\\_hubs\\' } |
    Sort-Object { $_.FullName.Length } -Descending

foreach ($dir in $allDirs) {
    $rel = $dir.FullName.Substring($DocsRoot.Length + 1)
    $secId = Get-SectionIdFromPath $rel
    if (-not $secId) { continue }

    $stripped = Strip-LegacyFolderName $dir.Name $secId
    if (-not $stripped) { continue }

    $parent = Split-Path $dir.FullName -Parent
    $dest = Join-Path $parent $stripped
    if ($dir.FullName -eq $dest) { continue }

    if (Test-Path $dest) {
        # Merge: move files from legacy dir into existing stripped dir
        Get-ChildItem $dir.FullName -Recurse -File | ForEach-Object {
            $innerRel = $_.FullName.Substring($dir.FullName.Length + 1)
            $target = Join-Path $dest $innerRel
            if (Move-FileSafe $_.FullName $target) { $Stats.folders_renamed++ }
        }
        if (-not $DryRun) {
            Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    elseif (Rename-DirSafe $dir.FullName $dest) {
        $Stats.folders_renamed++
    }
}

Write-Host "  Renamed/merged: $($Stats.folders_renamed)"

Write-Host "Phase 2: reorganize section 02 topic groups into correct subsections"
$deRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture"
foreach ($entry in $DeTopicGroupMap.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($entry.Value)) { continue }
    $srcDir = Join-Path $deRoot "02.01_Data_Ingestion_Architecture\$($entry.Key)"
    $destSub = Join-Path $deRoot $entry.Value
    if (-not (Test-Path $srcDir)) { continue }
    if ($entry.Value -eq "02.01_Data_Ingestion_Architecture") { continue }

    Get-ChildItem $srcDir -Recurse -File -Filter *.md | ForEach-Object {
        $rel = $_.FullName.Substring($srcDir.Length + 1)
        $dest = Join-Path $destSub (Join-Path $entry.Key $rel)
        if (Move-FileSafe $_.FullName $dest) { $Stats.section02_moves++ }
    }
    if (-not $DryRun -and (Test-Path $srcDir)) {
        $left = Get-ChildItem $srcDir -Recurse -File -ErrorAction SilentlyContinue
        if (-not $left) { Remove-Item -LiteralPath $srcDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "  Section 02 moves: $($Stats.section02_moves)"

Write-Host "Phase 3: cross-section moves (Cost_Optimization -> FinOps)"
foreach ($entry in $CrossSectionMoves.GetEnumerator()) {
    $srcDir = Join-Path $DocsRoot ($entry.Key -replace '/', '\')
    $destDir = Join-Path $DocsRoot ($entry.Value -replace '/', '\')
    if (-not (Test-Path $srcDir)) { continue }
    Get-ChildItem $srcDir -Recurse -File -Filter *.md | ForEach-Object {
        $rel = $_.FullName.Substring($srcDir.Length + 1)
        $dest = Join-Path $destDir $rel
        if (Move-FileSafe $_.FullName $dest) { $Stats.cross_section_moves++ }
    }
    if (-not $DryRun -and (Test-Path $srcDir)) {
        $left = Get-ChildItem $srcDir -Recurse -File -ErrorAction SilentlyContinue
        if (-not $left) { Remove-Item -LiteralPath $srcDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "  Cross-section moves: $($Stats.cross_section_moves)"

Write-Host "Phase 4: fix front matter section field from path"
Get-ChildItem $DocsRoot -Recurse -Filter *.md | Where-Object {
    $_.Name -ne 'README.md' -and $_.FullName -notmatch '\\_meta\\|\\_hubs\\'
} | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    $expected = Infer-SectionFromRel ($rel -replace '\\', '/')
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') { return }
    $fm = $Matches[1]
    $body = $Matches[2]
    if ($fm -match '(?m)^section:\s*"?([^"`n]+)"?') {
        $current = $Matches[1].Trim()
        if ($current -eq $expected) { return }
    }
    if ($fm -match '(?m)^section:\s*"?[^"`n]+"?') {
        $newFm = $fm -replace '(?m)^section:\s*"?[^"`n]+"?', "section: `"$expected`""
    }
    else {
        $newFm = "section: `"$expected`"`n" + $fm
    }
    if ($fm -match '(?m)^last_reviewed:') {
        $newFm = $newFm -replace '(?m)^last_reviewed:\s*.*$', "last_reviewed: $Today"
    }
    $newText = "---`n$newFm`n---`n$body"
    if (-not $DryRun) {
        [IO.File]::WriteAllText($_.FullName, $newText.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    }
    $Stats.front_matter_fixed++
}

Write-Host "  Front matter updates: $($Stats.front_matter_fixed)"

Write-Host "Phase 5: remove empty directories"
if (-not $DryRun) {
    for ($i = 0; $i -lt 10; $i++) {
        Get-ChildItem $DocsRoot -Recurse -Directory |
            Where-Object { $_.FullName -notmatch '\\_meta\\|\\_hubs\\' } |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object {
                $children = Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue
                if (-not $children) {
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                    $Stats.empty_dirs_removed++
                }
            }
    }
}

Write-Host "  Empty dirs removed: $($Stats.empty_dirs_removed)"

Write-Host "Phase 6: verify remaining legacy folder names"
$remainingLegacy = 0
Get-ChildItem $DocsRoot -Recurse -Directory | Where-Object { $_.FullName -notmatch '\\_meta\\|\\_hubs\\' } | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    $secId = Get-SectionIdFromPath $rel
    if ($secId -and (Is-LegacyFolderName $_.Name $secId)) { $remainingLegacy++ }
}

$legacyFiles = 0
Get-ChildItem $DocsRoot -Recurse -Filter *.md | Where-Object {
    $_.Name -ne 'README.md' -and $_.FullName -notmatch '\\_meta\\|\\_hubs\\'
} | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    $parts = $rel -split '[\\/]'
    $secId = Get-SectionIdFromPath $rel
    if (-not $secId) { return }
    foreach ($p in $parts) {
        if (Is-LegacyFolderName $p $secId) { $legacyFiles++; break }
    }
}

$report = @(
    "# Naming Convention Fix Report",
    "",
    "Generated on $Today.",
    "",
    "| Action | Count |",
    "| --- | ---: |",
    "| Legacy folders renamed/merged | $($Stats.folders_renamed) |",
    "| Section 02 topic group moves | $($Stats.section02_moves) |",
    "| Cross-section moves | $($Stats.cross_section_moves) |",
    "| Front matter section fixes | $($Stats.front_matter_fixed) |",
    "| Empty directories removed | $($Stats.empty_dirs_removed) |",
    "| Path collisions (duplicate dropped) | $($Stats.collisions) |",
    "| Remaining legacy-named folders | $remainingLegacy |",
    "| Files under legacy-named folders | $legacyFiles |",
    ""
)

if (-not $DryRun) {
    [IO.File]::WriteAllText((Join-Path $MetaDir "naming_convention_report.md"), ($report -join "`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host "Done. Remaining legacy folders: $remainingLegacy Files in legacy paths: $legacyFiles"
if ($DryRun) { Write-Host "(Dry run)" }
