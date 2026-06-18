param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$SecRoot = Join-Path $DocsRoot "09_Event_And_Streaming_Architecture"
$MapFile = Join-Path $DocsRoot "_meta\section_09_migration_map.yaml"
$SecPrefix = "09_Event_And_Streaming_Architecture/"

function Get-BaseName([string]$FileName) {
    $base = [IO.Path]::GetFileNameWithoutExtension($FileName)
    if ($base -match '^\d{2}\.\d{2}(?:\.\d{2})?\.\d{2}_(.+)$') { return $Matches[1] }
    return $base
}

function Get-FolderPrefix([string]$FolderName) {
    if ($FolderName -match '^(\d{2}\.\d{2}\.\d{2})_') { return $Matches[1] }
    if ($FolderName -match '^(\d{2}\.\d{2})_') { return $Matches[1] }
    return $null
}

# Build reading order from migration map canonical_targets
$OrderByDir = @{}
Get-Content $MapFile | ForEach-Object {
    if ($_ -match '^\s*-\s+(.+\.md)\s*$') {
        $rel = $Matches[1].Replace('\', '/')
        $dir = Split-Path $rel -Parent
        if ($dir) { $dir = $dir.Replace('\', '/') }
        $file = Split-Path $rel -Leaf
        if (-not $OrderByDir.ContainsKey($dir)) { $OrderByDir[$dir] = [System.Collections.Generic.List[string]]::new() }
        if ($OrderByDir[$dir] -notcontains $file) { [void]$OrderByDir[$dir].Add($file) }
    }
}

$Renames = @()  # @{ OldRel; NewRel; OldName; NewName }

Get-ChildItem $SecRoot -Recurse -Directory | ForEach-Object {
    $folderName = $_.Name
    $prefix = Get-FolderPrefix $folderName
    if (-not $prefix) { return }

    $relDir = $_.FullName.Substring($SecRoot.Length + 1).Replace('\', '/')
    $files = Get-ChildItem $_.FullName -File -Filter *.md | Where-Object { $_.Name -ne 'README.md' }
    if ($files.Count -eq 0) { return }

    $ordered = @()
    if ($OrderByDir.ContainsKey($relDir)) {
        foreach ($f in $OrderByDir[$relDir]) {
            $want = Get-BaseName $f
            $match = $files | Where-Object { (Get-BaseName $_.Name) -eq $want } | Select-Object -First 1
            if ($match) { $ordered += $match }
        }
    }
    foreach ($f in ($files | Sort-Object Name)) {
        $base = Get-BaseName $f.Name
        if (-not ($ordered | Where-Object { (Get-BaseName $_.Name) -eq $base })) { $ordered += $f }
    }

    $seq = 1
    foreach ($f in $ordered) {
        $base = Get-BaseName $f.Name
        $newName = if ($prefix -match '^\d{2}\.\d{2}\.\d{2}$') {
            "{0}.{1:D2}_{2}.md" -f $prefix, $seq, $base
        } else {
            "{0}.{1:D2}_{2}.md" -f $prefix, $seq, $base
        }
        $seq++
        if ($f.Name -eq $newName) { continue }
        $oldRel = "$relDir/$($f.Name)"
        $newRel = "$relDir/$newName"
        $Renames += [pscustomobject]@{ OldRel = $oldRel; NewRel = $newRel; OldName = $f.Name; NewName = $newName; FullPath = $f.FullName }
    }
}

Write-Host "Planned file renames: $($Renames.Count)"
$Renames | ForEach-Object { Write-Host "  $($_.OldRel) -> $($_.NewName)" }

if ($DryRun) { Write-Host "(Dry run - no changes written)"; return }

# Two-phase rename to avoid collisions
$temp = 0
foreach ($r in $Renames) {
    $tmpName = "__renametmp_{0}__.md" -f $temp++
    Rename-Item -LiteralPath $r.FullPath -NewName $tmpName
    $r | Add-Member -NotePropertyName TempName -NotePropertyValue $tmpName -Force
}
foreach ($r in $Renames) {
    $dir = Split-Path $r.FullPath -Parent
    Rename-Item -LiteralPath (Join-Path $dir $r.TempName) -NewName $r.NewName
}

# Update links repo-wide (full path fragments only - never bare filenames globally)
$LinkReplacements = @{}
foreach ($r in $Renames) {
    $oldKey = ($SecPrefix + $r.OldRel).Replace('\', '/')
    $newKey = ($SecPrefix + $r.NewRel).Replace('\', '/')
    $LinkReplacements[$oldKey] = $newKey
    $LinkReplacements[$r.OldRel.Replace('\', '/')] = $r.NewRel.Replace('\', '/')
}
$patterns = $LinkReplacements.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending

$linksFixed = 0
Get-ChildItem $DocsRoot -Recurse -Filter *.md | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($p in $patterns) {
        $text = $text.Replace($p.Key.Replace('/', '\'), $p.Value.Replace('/', '\'))
        $text = $text.Replace($p.Key, $p.Value)
    }
    # Relative links within section 09 only (skip if target already numbered)
    if ($_.FullName.StartsWith($SecRoot)) {
        foreach ($r in $Renames) {
            $text = $text.Replace("($($r.OldName))", "($($r.NewName))")
            $text = $text.Replace("/$($r.OldName))", "/$($r.NewName))")
            $text = $text.Replace("/$($r.OldName)#", "/$($r.NewName)#")
        }
        $text = [regex]::Replace($text, '(\d{2}\.\d{2}(?:\.\d{2})?\.\d{2})_\1_', '$1_')
    }
    if ($text -ne $orig) {
        [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false))
        $linksFixed++
    }
}

# Update migration map
if (Test-Path $MapFile) {
    $mapText = [IO.File]::ReadAllText($MapFile)
    foreach ($p in $patterns) {
        $mapText = $mapText.Replace($p.Key, $p.Value)
    }
    [IO.File]::WriteAllText($MapFile, $mapText, [Text.UTF8Encoding]::new($false))
}

Write-Host "Done. Renamed=$($Renames.Count) Links=$linksFixed"
