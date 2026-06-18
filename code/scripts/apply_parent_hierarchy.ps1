param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$Today = Get-Date -Format "yyyy-MM-dd"

# Section roots: old relative path under docs -> new relative path under docs
$SectionMoves = @(
    @{
        Old = "00_Architecture_Governance\00.10_Data_Governance_And_Metadata"
        New = "00_Architecture_Governance/00.10_Data_Governance_And_Metadata"
        OldPrefix = "07."
        NewPrefix = "00.10."
    },
    @{
        Old = "02_Data_Engineering_Architecture\02.06_Data_Storage_Architecture"
        New = "02_Data_Engineering_Architecture/02.06_Data_Storage_Architecture"
        OldPrefix = "03."
        NewPrefix = "02.06."
    },
    @{
        Old = "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming"
        New = "02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming"
        OldPrefix = "09."
        NewPrefix = "02.01.02."
    },
    @{
        Old = "08_Analytics_Architecture\08.08_Analytics_Architecture/08.10_Real_Time_Analytics_Architecture"
        New = "08_Analytics_Architecture/08.10_Real_Time_Analytics_Architecture"
        OldPrefix = "10."
        NewPrefix = "08.10."
    },
    @{
        Old = "11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.12_Agentic_AI_Architecture"
        New = "11_AI_Data_Architecture/11.12_Agentic_AI_Architecture"
        OldPrefix = "12."
        NewPrefix = "11.12."
    }
)

function Rename-PathPrefix([string]$Name, [string]$OldPrefix, [string]$NewPrefix) {
    if ($Name -match "^$([regex]::Escape($OldPrefix))") {
        return $NewPrefix + $Name.Substring($OldPrefix.Length)
    }
    return $null
}

function Get-SectionRoot([string]$FullPath) {
    foreach ($m in $SectionMoves) {
        $oldFull = Join-Path $DocsRoot ($m.Old.Replace('/', '\'))
        $newFull = Join-Path $DocsRoot ($m.New.Replace('/', '\'))
        if ($FullPath.StartsWith($newFull)) { return $m }
        # also handle if still at old nested path before section folder rename
        $nestedOld = Join-Path $DocsRoot ($m.New.Split('/')[0])
        $nestedOld = Join-Path $nestedOld $m.Old
        if ($FullPath.StartsWith($nestedOld)) { return $m }
    }
    return $null
}

Write-Host "Phase 1: rename nested section root folders"
foreach ($m in $SectionMoves) {
    $parent = $m.New.Split('/')[0]
    $oldPath = Join-Path $DocsRoot (Join-Path $parent $m.Old)
    $newPath = Join-Path $DocsRoot ($m.New.Replace('/', '\'))
    if (Test-Path $oldPath) {
        if (Test-Path $newPath) { Write-Warning "Skip exists: $($m.New)"; continue }
        if (-not $DryRun) {
            $destParent = Split-Path $newPath -Parent
            if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
            Rename-Item -LiteralPath $oldPath -NewName (Split-Path $newPath -Leaf)
        }
        Write-Host "  $($m.Old) -> $(Split-Path $newPath -Leaf)"
    } elseif (Test-Path $newPath) {
        Write-Host "  (already) $($m.New)"
    }
}

Write-Host "Phase 2: renumber folders and files under moved sections"
$renameOps = @()
foreach ($m in $SectionMoves) {
    $secRoot = Join-Path $DocsRoot ($m.New.Replace('/', '\'))
    if (-not (Test-Path $secRoot)) { continue }
    Get-ChildItem $secRoot -Recurse -Force | ForEach-Object {
        $newName = Rename-PathPrefix $_.Name $m.OldPrefix $m.NewPrefix
        if ($newName -and $newName -ne $_.Name) {
            $renameOps += [pscustomobject]@{
                FullPath = $_.FullName
                NewName = $newName
                Depth = ($_.FullName.Split('\').Count + $_.FullName.Split('/').Count)
            }
        }
    }
}
foreach ($op in ($renameOps | Sort-Object { $_.FullPath.Length } -Descending)) {
    $parent = Split-Path $op.FullPath -Parent
    $dest = Join-Path $parent $op.NewName
    if (Test-Path $dest) { continue }
    if (-not $DryRun) { Rename-Item -LiteralPath $op.FullPath -NewName $op.NewName }
}
Write-Host "  Renamed $($renameOps.Count) items"

Write-Host "Phase 3: update links and path references"
$linkRepl = @{}
foreach ($m in $SectionMoves) {
    $oldSeg = $m.Old
    $newSeg = $m.New.Replace('/', '/')
    $linkRepl["docs/$oldSeg"] = "docs/$newSeg"
    $linkRepl[$oldSeg] = $newSeg
    # prefix swaps inside paths (longest first applied later)
    $linkRepl[$m.OldPrefix] = $m.NewPrefix
}
# Remove dangerous bare prefix-only keys from global replace - handle in path context only
$pathLinkRepl = @{}
foreach ($m in $SectionMoves) {
    $pathLinkRepl["docs/$($m.Old)"] = "docs/$($m.New)"
    $pathLinkRepl[$m.Old] = $m.New
    $pathLinkRepl["../$($m.Old)"] = "../$($m.New)"
    $pathLinkRepl["../../$($m.Old)"] = "../../$($m.New)"
    $pathLinkRepl["../../../$($m.Old)"] = "../../../$($m.New)"
    $pathLinkRepl["../../../../$($m.Old)"] = "../../../../$($m.New)"
}
# Number prefix replacements within known section paths only
$numRepl = @()
foreach ($m in $SectionMoves) {
    $numRepl += [pscustomobject]@{ Old = $m.OldPrefix; New = $m.NewPrefix; Root = $m.New }
}
$numRepl = $numRepl | Sort-Object { $_.Old.Length } -Descending

$linksFixed = 0
Get-ChildItem $DocsRoot -Recurse -Filter *.md | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($p in ($pathLinkRepl.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending)) {
        $text = $text.Replace($p.Key.Replace('/', '\'), $p.Value.Replace('/', '\'))
        $text = $text.Replace($p.Key, $p.Value)
    }
    # Replace old numeric prefixes only in paths containing moved section roots
    foreach ($m in $SectionMoves) {
        $newRoot = $m.New.Replace('/', '/')
        if ($text -notmatch [regex]::Escape($newRoot)) { continue }
        $text = [regex]::Replace($text, "($([regex]::Escape($m.OldPrefix)))(\d{2})", { $m.NewPrefix + $args[0].Groups[2].Value })
    }
    if ($text -ne $orig) {
        if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) }
        $linksFixed++
    }
}
Write-Host "  Links updated in $linksFixed files"

Write-Host "Phase 4: fix relative links inside moved section trees"
$innerFixed = 0
foreach ($m in $SectionMoves) {
    $secRoot = Join-Path $DocsRoot ($m.New.Replace('/', '\'))
    if (-not (Test-Path $secRoot)) { continue }
    Get-ChildItem $secRoot -Recurse -Filter *.md | ForEach-Object {
        $text = [IO.File]::ReadAllText($_.FullName)
        $orig = $text
        $text = [regex]::Replace($text, "($([regex]::Escape($m.OldPrefix)))(\d{2})", { $m.NewPrefix + $args[0].Groups[2].Value })
        if ($text -ne $orig) {
            if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) }
            $innerFixed++
        }
    }
}
Write-Host "  Inner links fixed in $innerFixed files"

Write-Host "Phase 5: update _meta and config path references"
$metaRoots = @(
    (Join-Path $DocsRoot "_meta"),
    (Join-Path $RepoRoot "code")
)
$metaFixed = 0
foreach ($root in $metaRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Recurse -Include *.yaml,*.yml,*.md,*.ps1 | ForEach-Object {
        $text = [IO.File]::ReadAllText($_.FullName)
        $orig = $text
        foreach ($p in ($pathLinkRepl.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending)) {
            $text = $text.Replace($p.Key.Replace('/', '\'), $p.Value.Replace('/', '\'))
            $text = $text.Replace($p.Key, $p.Value)
        }
        if ($text -ne $orig) {
            if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) }
            $metaFixed++
        }
    }
}
Write-Host "  Meta/config updated in $metaFixed files"

Write-Host "Phase 6: fix front matter section field"
$fmFixed = 0
function Infer-Section([string]$RelPath) {
    $r = $RelPath.Replace('\', '/')
    if ($r -match '(?:^|/)(\d{2}(?:\.\d{2}){1,4})(?:[._/]|$)') { return $Matches[1] }
    if ($r -match '(?:^|/)(\d{2})_') { return $Matches[1] }
    return "00"
}
Get-ChildItem $DocsRoot -Recurse -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    $expected = Infer-Section $rel
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') { return }
    $fm = $Matches[1]
    $body = $Matches[2]
    if ($fm -match '(?m)^section:\s*"?([^"`n]+)"?') {
        $cur = $Matches[1].Trim()
        if ($cur -ne $expected) {
            $fm = $fm -replace '(?m)^section:\s*"?[^"`n]+"?', "section: `"$expected`""
            if (-not $DryRun) {
                [IO.File]::WriteAllText($_.FullName, "---`n$fm`n---`n$body".TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
            }
            $fmFixed++
        }
    }
}
Write-Host "  Front matter fixed in $fmFixed files"

Write-Host "Done."
if ($DryRun) { Write-Host "(Dry run)" }
