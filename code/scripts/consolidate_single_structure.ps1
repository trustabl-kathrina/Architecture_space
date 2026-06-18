param(
    [switch]$DryRun,
    [switch]$SkipDelete
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$OldRoot = Join-Path $RepoRoot "Enterprise Transformation"
$NewRoot = Join-Path $RepoRoot "docs"
$Today = Get-Date -Format "yyyy-MM-dd"
$MetaDir = Join-Path $NewRoot "_meta"

$Stats = @{
    copied = 0
    skipped_redirect = 0
    skipped_exists = 0
    skipped_missing_source = 0
    errors = 0
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function Is-Redirect([string]$Text) {
    return ($Text -match '(?m)^status:\s*redirect\s*$')
}

function Get-StatusRank([string]$Text) {
    if ($Text -match '(?m)^status:\s*(\S+)') {
        $s = $Matches[1]
        $rank = @{ stub = 0; archived = 0; draft = 1; review = 2; complete = 3; redirect = -1 }
        if ($rank.ContainsKey($s)) { return $rank[$s] }
    }
    return 0
}

function Copy-Safe([string]$Source, [string]$Dest) {
    $dir = Split-Path $Dest -Parent
    Ensure-Dir $dir
    if (-not $DryRun) {
        [IO.File]::Copy($Source, $Dest, $true)
    }
}

function Load-MigrationMap() {
    $mapPath = Join-Path $MetaDir "migration_map.yaml"
    $yaml = Get-Content $mapPath -Raw -Encoding UTF8
    $items = @()
    foreach ($m in [regex]::Matches($yaml, '(?ms)- old_path: "([^"]+)"\s+new_path: "([^"]+)"\s+status:\s*(\S+)\s+migration_action:\s*(\S+)')) {
        $items += [pscustomobject]@{
            old_path = $m.Groups[1].Value
            new_path = $m.Groups[2].Value
            status   = $m.Groups[3].Value
            action   = $m.Groups[4].Value
        }
    }
    return $items
}

if (-not (Test-Path $OldRoot)) {
    Write-Host "Enterprise Transformation/ not found - already consolidated."
    exit 0
}

Write-Host "Phase 1: migrate remaining legacy content into docs/"
$items = Load-MigrationMap
$total = $items.Count
$i = 0

foreach ($item in $items) {
    $i++
    if ($i % 500 -eq 0) { Write-Host "  Progress: $i / $total" }

    $oldPath = Join-Path $RepoRoot ($item.old_path -replace '/', '\')
    $newPath = Join-Path $RepoRoot ($item.new_path -replace '/', '\')

    if (-not (Test-Path $oldPath)) {
        $Stats.skipped_missing_source++
        continue
    }

    $oldText = [IO.File]::ReadAllText($oldPath)
    if (Is-Redirect $oldText) {
        $Stats.skipped_redirect++
        continue
    }

    if (Test-Path $newPath) {
        $newText = [IO.File]::ReadAllText($newPath)
        if (Is-Redirect $newText) {
            $Stats.skipped_exists++
            continue
        }
        if ((Get-StatusRank $newText) -ge (Get-StatusRank $oldText)) {
            $Stats.skipped_exists++
            continue
        }
    }

    try {
        Copy-Safe $oldPath $newPath
        $Stats.copied++
    }
    catch {
        $Stats.errors++
        Write-Warning "Failed: $($item.old_path) -> $($item.new_path): $_"
    }
}

Write-Host "  Copied: $($Stats.copied)"
Write-Host "  Skipped (legacy redirect): $($Stats.skipped_redirect)"
Write-Host "  Skipped (docs already has content): $($Stats.skipped_exists)"
Write-Host "  Skipped (missing source): $($Stats.skipped_missing_source)"
Write-Host "  Errors: $($Stats.errors)"

Write-Host "Phase 2: verify docs/ file counts"
$docsMd = @(Get-ChildItem $NewRoot -Recurse -Filter *.md -ErrorAction SilentlyContinue).Count
Write-Host "  docs/ markdown files: $docsMd"

if (-not $SkipDelete -and -not $DryRun -and $Stats.errors -eq 0) {
    Write-Host "Phase 3: remove Enterprise Transformation/"
    Remove-Item -LiteralPath $OldRoot -Recurse -Force -ErrorAction Stop
    Write-Host "  Removed legacy tree."
}
elseif ($DryRun) {
    Write-Host "Phase 3: (dry run) would remove Enterprise Transformation/"
}
else {
    Write-Host "Phase 3: skipped delete (errors or -SkipDelete)"
}

Write-Host "Phase 4: update metadata"
$report = @(
    "# Consolidation Report",
    "",
    "Generated on $Today.",
    "",
    "## Summary",
    "",
    "The repository now uses a single content root: docs/.",
    "",
    "| Metric | Count |",
    "| --- | ---: |",
    "| Files copied from legacy | $($Stats.copied) |",
    "| Legacy redirects skipped (canonical already in docs/) | $($Stats.skipped_redirect) |",
    "| Targets already present in docs/ | $($Stats.skipped_exists) |",
    "| docs/ markdown files after consolidation | $docsMd |",
    "| Legacy tree removed | $(if ($SkipDelete -or $DryRun) { 'no' } else { 'yes' }) |",
    "",
    "## Structure",
    "",
    "- docs/ - single documentation root (21 sections, hubs, meta)",
    "- code/ - scripts, templates, MkDocs config",
    ""
)

if (-not $DryRun) {
    [IO.File]::WriteAllText((Join-Path $MetaDir "consolidation_report.md"), ($report -join "`n"), [Text.UTF8Encoding]::new($false))

    $redirectNote = @(
        "# Redirect Index",
        "",
        "Generated on $Today.",
        "",
        "Legacy Enterprise Transformation/ has been consolidated into docs/.",
        "All content now lives under the 21-section taxonomy in docs/.",
        "",
        "See [migration_map.yaml](migration_map.yaml) for the historical old-to-new path mapping.",
        "",
        "See [consolidation_report.md](consolidation_report.md) for the merge summary.",
        ""
    )
    [IO.File]::WriteAllText((Join-Path $MetaDir "redirects.md"), ($redirectNote -join "`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host "Done."
