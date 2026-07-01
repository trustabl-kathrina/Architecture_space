# Move 02.07 Event & Streaming under 02.01.02 Streaming; scaffold Batch and Near-real-time.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$DeRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture"
$IngestRoot = Join-Path $DeRoot "02.01_Data_Ingestion_Architecture"
$OldStreamRoot = Join-Path $DeRoot "02.07_Event_And_Streaming_Architecture"
$NewStreamRoot = Join-Path $IngestRoot "02.01.02_Streaming"
$BatchRoot = Join-Path $IngestRoot "02.01.01_Batch_Ingestion"
$NrtRoot = Join-Path $IngestRoot "02.01.03_Near_Real_Time_Ingestion"
$Today = Get-Date -Format "yyyy-MM-dd"

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

function Rename-TreePrefix([string]$Root, [string]$OldPrefix, [string]$NewPrefix) {
    if (-not (Test-Path $Root)) { return 0 }
    $ops = @()
    Get-ChildItem $Root -Recurse -Force | ForEach-Object {
        if ($_.Name -match "^$([regex]::Escape($OldPrefix))") {
            $ops += [pscustomobject]@{
                Path = $_.FullName
                NewName = $NewPrefix + $_.Name.Substring($OldPrefix.Length)
                IsDir = $_.PSIsContainer
            }
        }
    }
    $count = 0
    foreach ($op in ($ops | Sort-Object { $_.Path.Length } -Descending)) {
        $parent = Split-Path $op.Path -Parent
        $dest = Join-Path $parent $op.NewName
        if (Test-Path $dest) { continue }
        if (-not (Test-Path -LiteralPath $op.Path)) { continue }
        if ($DryRun) { $count++; continue }
        try {
            if ($op.IsDir) {
                [System.IO.Directory]::Move((To-LongPath $op.Path), (To-LongPath $dest))
            } else {
                [System.IO.File]::Move((To-LongPath $op.Path), (To-LongPath $dest))
            }
            $count++
        } catch {
            Write-Warning "Rename failed: $($op.Path) -> $($op.NewName): $_"
        }
    }
    return $count
}

function Update-TextPrefixes([string]$Text) {
    $t = $Text
    $repl = @(
        @{ O = '02_Data_Engineering_Architecture/02.07_Event_And_Streaming_Architecture'; N = '02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming' }
        @{ O = '02.07_Event_And_Streaming_Architecture'; N = '02.01_Data_Ingestion_Architecture/02.01.02_Streaming' }
        @{ O = '02.07.'; N = '02.01.02.' }
        @{ O = 'section: "02.07.'; N = 'section: "02.01.02.' }
        @{ O = 'section: "02.07"'; N = 'section: "02.01.02"' }
        @{ O = 'domain_id: "02.07"'; N = 'domain_id: "02.01.02"' }
        @{ O = 'id: "02.07"'; N = 'id: "02.01.02"' }
        @{ O = '| 02.07 |'; N = '| 02.01.02 |' }
        @{ O = '02.07 Event'; N = '02.01.02 Streaming' }
        @{ O = '02.07 consolidation'; N = '02.01.02 streaming consolidation' }
        @{ O = 'section_02.07_'; N = 'section_02.01.02_' }
    )
    foreach ($r in $repl) { $t = $t.Replace($r.O, $r.N) }
    # Downstream of stream processing (was 02.07)
    $t = [regex]::Replace($t, '(?i)downstream of stream processing \(02\.07\)', 'downstream of stream processing (02.01.02)')
    $t = [regex]::Replace($t, '(?i)Boundary with 02\.07', 'Boundary with 02.01.02')
    $t = [regex]::Replace($t, '\| Ingest & process \| 02\.07 \|', '| Ingest & process | 02.01.02 |')
    $t = [regex]::Replace($t, 'subgraph sec207 \[02\.07\]', 'subgraph sec20102 [02.01.02]')
    return $t
}

function Infer-Section([string]$RelPath) {
    $r = $RelPath.Replace('\', '/')
    if ($r -match '(?:^|/)(\d{2}(?:\.\d{2}){1,5})(?:[._/]|$)') { return $Matches[1] }
    if ($r -match '(?:^|/)(\d{2})_') { return $Matches[1] }
    return "02"
}

Write-Host "Phase 1: create ingestion mode folders"
Ensure-Dir $BatchRoot
Ensure-Dir $NewStreamRoot
Ensure-Dir $NrtRoot

Write-Host "Phase 2: move 02.07 tree into 02.01.02_Streaming"
if (Test-Path $OldStreamRoot) {
    $children = Get-ChildItem $OldStreamRoot -Force | Where-Object { $_.Name -ne 'README.md' }
    foreach ($child in $children) {
        if ($child.Name -eq '02.01.02_Streaming') { continue }
        $dest = Join-Path $NewStreamRoot $child.Name
        if (Test-Path $dest) { Write-Host "  (already) $($child.Name)"; continue }
        if (-not $DryRun) { Move-Item -LiteralPath $child.FullName -Destination $NewStreamRoot }
        Write-Host "  moved $($child.Name)"
    }
} else {
    Write-Host "  (skip) old 02.07 path absent - content may already be under 02.01.02"
}

Write-Host "Phase 3: renumber 02.07.* -> 02.01.02.* under Streaming"
$renamed = Rename-TreePrefix $NewStreamRoot "02.07." "02.01.02."
Write-Host "  renamed $renamed items"

Write-Host "Phase 4: relocate batch / near-real-time seed content"
$moves = @(
    @{ Src = Join-Path $IngestRoot "Reference_Architectures\Batch_Data_Platform.md"; Dst = Join-Path $BatchRoot "02.01.01.01_Batch_Data_Platform.md" }
    @{ Src = Join-Path $IngestRoot "ADF.md"; Dst = Join-Path $BatchRoot "02.01.01.02_ADF_Batch_Ingestion.md" }
    @{ Src = Join-Path $IngestRoot "Reference_Architectures\Streaming_Data_Platform.md"; Dst = Join-Path $NewStreamRoot "02.01.02.09_Reference_Architectures\02.01.02.09.01_Streaming_Data_Platform.md" }
    @{ Src = Join-Path $IngestRoot "Data_Engineering_Strategy\Real_Time_Data_Strategy.md"; Dst = Join-Path $NrtRoot "02.01.03.01_Real_Time_Data_Strategy.md" }
)
foreach ($m in $moves) {
    if (-not (Test-Path $m.Src)) { Write-Host "  skip (missing): $($m.Src)"; continue }
    Ensure-Dir (Split-Path $m.Dst -Parent)
    if (Test-Path $m.Dst) { continue }
    if (-not $DryRun) { Move-Item -LiteralPath $m.Src -Destination $m.Dst }
    Write-Host "  $($m.Src | Split-Path -Leaf) -> $(Split-Path $m.Dst -Leaf)"
}

Write-Host "Phase 5: redirect stub at former 02.07 path"
$redirect = @(
    '---',
    'title: Event And Streaming Architecture (Moved)',
    'section: "02.01.02"',
    'status: complete',
    'template: redirect',
    "last_reviewed: $Today",
    'owner: architecture-team',
    'tags: [streaming, redirect]',
    'canonical: false',
    'redirect_to: ../02.01_Data_Ingestion_Architecture/02.01.02_Streaming/README.md',
    '---',
    '',
    '# Moved to 02.01.02 Streaming',
    '',
    'Event and streaming architecture now lives under **Data Ingestion Architecture**:',
    '',
    '- [02.01.02 Streaming](../02.01_Data_Ingestion_Architecture/02.01.02_Streaming/README.md)',
    '- [02.01 Data Ingestion Architecture](../02.01_Data_Ingestion_Architecture/README.md)'
) -join "`n"
if (-not $DryRun) {
    Ensure-Dir $OldStreamRoot
    [IO.File]::WriteAllText((Join-Path $OldStreamRoot "README.md"), $redirect.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}

Write-Host "Phase 6: update file contents under Streaming + fix front matter"
$fmFixed = 0
if (Test-Path $NewStreamRoot) {
    foreach ($filePath in [System.IO.Directory]::EnumerateFiles((To-LongPath $NewStreamRoot), '*.md', 'AllDirectories')) {
        $norm = $filePath -replace '^\\\\\?\\',''
        $text = [IO.File]::ReadAllText($filePath)
        $updated = Update-TextPrefixes $text
        if ($updated -ne $text -and -not $DryRun) {
            [IO.File]::WriteAllText($filePath, $updated, [Text.UTF8Encoding]::new($false))
        }
        $rel = $norm.Substring($DocsRoot.Length + 1)
        $expected = Infer-Section $rel
        $cur = if ($updated -ne $text) { $updated } else { $text }
        if ($cur -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
            $fmLines = $Matches[1] -split "`r?`n"
            $body = $Matches[2]
            $newFm = @()
            $changed = $false
            foreach ($line in $fmLines) {
                if ($line -match '^section:\s*(.*)$') {
                    $val = $Matches[1].Trim().Trim([char]34)
                    if ($val -ne $expected) {
                        $newFm += "section: `"$expected`""
                        $changed = $true
                    } else { $newFm += $line }
                } else { $newFm += $line }
            }
            if ($changed -and -not $DryRun) {
                [IO.File]::WriteAllText($filePath, "---`n$($newFm -join "`n")`n---`n$body".TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
                $fmFixed++
            }
        }
    }
}
Write-Host "  front matter fixed: $fmFixed"

Write-Host "Phase 7: global link and metadata updates"
$globalFixed = 0
Get-ChildItem $RepoRoot -Recurse -Include *.md,*.yaml,*.yml,*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.FullName -match '\\(\.git|site|node_modules)\\') { return }
    if ($_.Name -eq 'move_streaming_to_02_01.ps1') { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    $updated = Update-TextPrefixes $text
    if ($updated -ne $text) {
            if (-not $DryRun) { [IO.File]::WriteAllText((To-LongPath $_.FullName), $updated, [Text.UTF8Encoding]::new($false)) }
        $globalFixed++
    }
}
Write-Host "  updated $globalFixed files repo-wide"

Write-Host "Done."
