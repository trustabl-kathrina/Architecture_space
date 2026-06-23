param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$OldRoot = Join-Path $RepoRoot "Enterprise Transformation"
if (-not (Test-Path $OldRoot)) { $OldRoot = $null }
$NewRoot = Join-Path $RepoRoot "docs"
$Today = Get-Date -Format "yyyy-MM-dd"
$MetaDir = Join-Path $NewRoot "_meta"

# Known canonical locations (repo-relative, forward slashes)
$CanonicalByFilename = @{
    "Governance_Maturity.md" = "docs/00_Architecture_Governance/00.10_Data_Governance_And_Metadata/00.10.01_Metadata_Management/08.02_Governance_Strategy/Governance_Maturity.md"
    "Showback_Model.md"      = "docs/04_Cloud_Data_Platforms/04.06_FinOps/18.12_Cost_Allocation_And_Chargeback/Showback_Model.md"
}

$SkipDirs = @("\_meta\", "\_hubs\", "\.git\")
$Stats = @{
    migration_redirects = 0
    body_dedup_redirects = 0
    skipped = 0
}

function Should-Skip([string]$FullPath) {
    foreach ($d in $SkipDirs) {
        if ($FullPath -match [regex]::Escape($d)) { return $true }
    }
    if ($FullPath -match '\\README\.md$') { return $true }
    return $false
}

function Repo-Relative([string]$FullPath) {
    return $FullPath.Substring($RepoRoot.Length + 1).Replace('\', '/')
}

function Parse-FmBlock([string]$Block) {
    $data = @{}
    foreach ($line in ($Block -split "`r?`n")) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*:\s*(.*)\s*$') {
            $data[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
        }
    }
    return $data
}

function Get-FrontMatterBlocks([string]$Text) {
    $blocks = @()
    $remaining = $Text
    while ($remaining -match '^(?s)---\s*\r?\n(.*?)\r?\n---\s*\r?\n?') {
        $blocks += $Matches[1]
        $remaining = $remaining.Substring($Matches[0].Length)
    }
    return @{ blocks = $blocks; body = $remaining }
}

function Get-BodyText([string]$Text) {
    $parsed = Get-FrontMatterBlocks $Text
    return $parsed.body.Trim()
}

function Get-BodyHash([string]$FullPath) {
    $text = [IO.File]::ReadAllText($FullPath)
    $body = Get-BodyText $text
    $bytes = [Text.Encoding]::UTF8.GetBytes($body)
    return [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash($bytes)).Replace('-', '')
}

function Get-RelativeLink([string]$FromFile, [string]$ToFile) {
    $fromDir = [IO.Path]::GetDirectoryName((Resolve-Path $FromFile).Path)
    $toPath = (Resolve-Path $ToFile).Path
    $fromUri = New-Object System.Uri(($fromDir.TrimEnd('\') + '\'))
    $toUri = New-Object System.Uri($toPath)
    return [Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString()).Replace('\', '/')
}

function Is-RedirectStub([string]$Text) {
    return ($Text -match '(?m)^status:\s*redirect\s*$') -or ($Text -match '(?m)^template:\s*redirect\s*$')
}

function Is-DomainStub([string]$Body) {
    return ($Body -match 'Domain Application') -or ($Body -match 'Canonical reference')
}

function Write-RedirectStub([string]$TargetPath, [string]$CanonicalFullPath, [string]$Title, [string]$Section) {
    $rel = Get-RelativeLink $TargetPath $CanonicalFullPath
    $canonicalRel = Repo-Relative $CanonicalFullPath
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

> **Moved:** This document is maintained at [$Title]($rel).

This path is preserved for backward compatibility. Edit the canonical document instead.
"@
    if (-not $DryRun) {
        [IO.File]::WriteAllText($TargetPath, $content.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    }
}

function Load-MigrationMap() {
    $mapPath = Join-Path $MetaDir "migration_map.yaml"
    $lines = Get-Content $mapPath -Encoding UTF8
    $items = @()
    $current = @{}
    foreach ($line in $lines) {
        if ($line -match '^\s*-\s+old_path:\s*"(.+)"\s*$') {
            if ($current.Count -gt 0) { $items += [pscustomobject]$current }
            $current = @{ old_path = $Matches[1] }
        }
        elseif ($line -match '^\s+new_path:\s*"(.+)"\s*$') { $current.new_path = $Matches[1] }
        elseif ($line -match '^\s+status:\s*(\S+)') { $current.status = $Matches[1] }
        elseif ($line -match '^\s+migration_action:\s*(\S+)') { $current.migration_action = $Matches[1] }
    }
    if ($current.Count -gt 0) { $items += [pscustomobject]$current }
    return $items
}

function Pick-Canonical([string[]]$Paths) {
    if ($Paths.Count -eq 0) { return $null }
    if ($Paths.Count -eq 1) { return $Paths[0] }

    $name = [IO.Path]::GetFileName($Paths[0])
    if ($CanonicalByFilename.ContainsKey($name)) {
        $canonicalRel = $CanonicalByFilename[$name]
        $canonicalFull = Join-Path $RepoRoot ($canonicalRel -replace '/', '\')
        if (Test-Path $canonicalFull) {
            $match = $Paths | Where-Object { (Repo-Relative $_) -eq $canonicalRel }
            if ($match) { return $match }
            return $canonicalFull
        }
    }

    $scored = foreach ($p in $Paths) {
        $text = [IO.File]::ReadAllText($p)
        $body = Get-BodyText $text
        $fm = @{}
        $parsed = Get-FrontMatterBlocks $text
        if ($parsed.blocks.Count -gt 0) { $fm = Parse-FmBlock $parsed.blocks[-1] }
        $rel = Repo-Relative $p
        $score = 0
        if ($rel -like "docs/*") { $score += 100 }
        if ($fm.canonical -eq "true" -and -not (Is-DomainStub $body)) { $score += 50 }
        if (-not (Is-DomainStub $body)) { $score += 30 }
        if ($fm.status -eq "complete") { $score += 10 }
        $score -= ($rel.Split('/').Count)  # prefer shorter paths
        [pscustomobject]@{ Path = $p; Score = $score }
    }
    return ($scored | Sort-Object Score -Descending | Select-Object -First 1).Path
}

function Get-MarkdownFiles() {
    $files = @()
    foreach ($root in @($OldRoot, $NewRoot)) {
        if (-not $root -or -not (Test-Path $root)) { continue }
        Get-ChildItem $root -Recurse -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not (Should-Skip $_.FullName)) { $files += $_.FullName }
        }
    }
    return $files
}

Write-Host "Phase 1: migration copy deduplication"
$migrationItems = Load-MigrationMap
$migrationReport = @()

foreach ($item in ($migrationItems | Where-Object { $_.migration_action -eq "copied" })) {
    $oldRel = $item.old_path -replace '^Enterprise Transformation/', ''
    $newRel = $item.new_path
    $oldPath = Join-Path $RepoRoot ($item.old_path -replace '/', '\')
    $newPath = Join-Path $RepoRoot ($newRel -replace '/', '\')

    if (-not (Test-Path $oldPath)) { continue }
    if (-not (Test-Path $newPath)) { continue }

    $oldText = [IO.File]::ReadAllText($oldPath)
    if (Is-RedirectStub $oldText) { continue }

    $parsed = Get-FrontMatterBlocks $oldText
    $fm = @{}
    if ($parsed.blocks.Count -gt 0) { $fm = Parse-FmBlock $parsed.blocks[-1] }
    $title = if ($fm.title) { $fm.title } else { [IO.Path]::GetFileNameWithoutExtension($oldPath) -replace '_', ' ' }
    $section = if ($fm.section) { $fm.section } else { "00" }

    Write-RedirectStub $oldPath $newPath $title $section
    $Stats.migration_redirects++
    $migrationReport += "| ``$(Repo-Relative $oldPath)`` | ``$newRel`` | migration |"
}

Write-Host "  Migration redirects: $($Stats.migration_redirects)"

Write-Host "Phase 2: body-identical deduplication"
$files = Get-MarkdownFiles
$byHash = @{}
foreach ($f in $files) {
    if (-not (Test-Path $f)) { continue }
    $text = [IO.File]::ReadAllText($f)
    if (Is-RedirectStub $text) { continue }
    $h = Get-BodyHash $f
    if (-not $byHash.ContainsKey($h)) { $byHash[$h] = @() }
    $byHash[$h] += $f
}

$bodyReport = @()
foreach ($entry in $byHash.GetEnumerator()) {
    $group = $entry.Value
    if ($group.Count -le 1) { continue }

    $canonical = Pick-Canonical $group
    if (-not $canonical) { continue }
    if (-not (Test-Path $canonical)) { continue }

    foreach ($dup in $group) {
        if ($dup -eq $canonical) { continue }
        $dupText = [IO.File]::ReadAllText($dup)
        if (Is-RedirectStub $dupText) { continue }

        $parsed = Get-FrontMatterBlocks $dupText
        $fm = @{}
        if ($parsed.blocks.Count -gt 0) { $fm = Parse-FmBlock $parsed.blocks[-1] }
        $title = if ($fm.title) { $fm.title } else { [IO.Path]::GetFileNameWithoutExtension($dup) -replace '_', ' ' }
        $section = if ($fm.section) { $fm.section } else { "00" }

        Write-RedirectStub $dup $canonical $title $section
        $Stats.body_dedup_redirects++
        $bodyReport += "| ``$(Repo-Relative $dup)`` | ``$(Repo-Relative $canonical)`` | body-identical |"
    }
}

Write-Host "  Body-identical redirects: $($Stats.body_dedup_redirects)"

Write-Host "Phase 3: duplicate report"
$byName = @{}
foreach ($f in (Get-MarkdownFiles)) {
    $name = [IO.Path]::GetFileName($f)
    if (-not $byName.ContainsKey($name)) { $byName[$name] = @() }
    $byName[$name] += $f
}
$remainingFilenameGroups = ($byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }).Count

$remainingBodyGroups = 0
$remainingBodyRedundant = 0
foreach ($f in (Get-MarkdownFiles)) {
    if (-not (Test-Path $f)) { continue }
    if (Is-RedirectStub ([IO.File]::ReadAllText($f))) { continue }
    $h = Get-BodyHash $f
    if (-not $byHash.ContainsKey($h)) { $byHash[$h] = @($f) }
}
# Rebuild hash from non-redirect files only
$cleanHash = @{}
foreach ($f in (Get-MarkdownFiles)) {
    if (-not (Test-Path $f)) { continue }
    $text = [IO.File]::ReadAllText($f)
    if (Is-RedirectStub $text) { continue }
    $h = Get-BodyHash $f
    if (-not $cleanHash.ContainsKey($h)) { $cleanHash[$h] = @() }
    $cleanHash[$h] += $f
}
foreach ($g in ($cleanHash.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 })) {
    $remainingBodyGroups++
    $remainingBodyRedundant += ($g.Value.Count - 1)
}

$report = @(
    "# Deduplication Report",
    "",
    "Generated on $Today.",
    "",
    "## Summary",
    "",
    "| Metric | Count |",
    "| --- | ---: |",
    "| Migration copy redirects | $($Stats.migration_redirects) |",
    "| Body-identical redirects | $($Stats.body_dedup_redirects) |",
    "| Total redirects written | $($Stats.migration_redirects + $Stats.body_dedup_redirects) |",
    "| Remaining duplicate filename groups | $remainingFilenameGroups |",
    "| Remaining body-identical groups | $remainingBodyGroups |",
    "| Remaining redundant body copies | $remainingBodyRedundant |",
    "",
    "> Remaining filename groups may be intentional (same topic, different domain content).",
    "",
    "## Migration redirects",
    "",
    "| From | To | Reason |",
    "| --- | --- | --- |"
) + $migrationReport + @(
    "",
    "## Body-identical redirects",
    "",
    "| From | Canonical | Reason |",
    "| --- | --- | --- |"
) + $bodyReport + @("")

$reportPath = Join-Path $MetaDir "deduplication_report.md"
if (-not $DryRun) {
    [IO.File]::WriteAllText($reportPath, ($report -join "`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host "Phase 4: resolve redirect chains"
$chainFixes = 0

function Resolve-CanonicalPath([string]$StartRel) {
    $seen = @{}
    $currentRel = $StartRel
    while ($true) {
        if ($seen.ContainsKey($currentRel)) { break }
        $seen[$currentRel] = $true
        $currentFull = Join-Path $RepoRoot ($currentRel -replace '/', '\')
        if (-not (Test-Path $currentFull)) { break }
        $text = [IO.File]::ReadAllText($currentFull)
        if ($text -notmatch '(?m)^status:\s*redirect\s*$') { return $currentRel }
        if ($text -match 'canonical_path:\s*"([^"]+)"') {
            $currentRel = $Matches[1]
        }
        else { break }
    }
    return $currentRel
}

Get-ChildItem $OldRoot, $NewRoot -Recurse -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
    if (Should-Skip $_.FullName) { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    if (-not (Is-RedirectStub $text)) { return }
    if ($text -notmatch 'canonical_path:\s*"([^"]+)"') { return }

    $currentCanonical = $Matches[1]
    $finalCanonical = Resolve-CanonicalPath $currentCanonical
    if ($finalCanonical -eq $currentCanonical) { return }

    $finalFull = Join-Path $RepoRoot ($finalCanonical -replace '/', '\')
    if (-not (Test-Path $finalFull)) { return }

    $parsed = Get-FrontMatterBlocks $text
    $fm = @{}
    if ($parsed.blocks.Count -gt 0) { $fm = Parse-FmBlock $parsed.blocks[-1] }
    $title = if ($fm.title) { $fm.title } else { [IO.Path]::GetFileNameWithoutExtension($_.FullName) -replace '_', ' ' }
    $section = if ($fm.section) { $fm.section } else { "00" }

    Write-RedirectStub $_.FullName $finalFull $title $section
    $chainFixes++
}

Write-Host "  Redirect chain fixes: $chainFixes"

Write-Host "Done. Total redirects: $($Stats.migration_redirects + $Stats.body_dedup_redirects)"
Write-Host "Remaining body-identical groups: $remainingBodyGroups (redundant copies: $remainingBodyRedundant)"
Write-Host "Remaining filename groups: $remainingFilenameGroups"
if ($DryRun) { Write-Host "(Dry run - no files written)" }
