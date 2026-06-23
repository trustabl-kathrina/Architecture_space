param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$SecRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming"
$Today = Get-Date -Format "yyyy-MM-dd"

$Renames = @(
    @{ Parent = "02.01.02.01_Fundamentals"; Map = @{
        "Overview" = "02.01.02.01.01_Overview"
        "Strategy" = "02.01.02.01.02_Strategy"
        "Core_Concepts" = "02.01.02.01.03_Core_Concepts"
        "CDC_Architecture" = "02.01.02.01.04_CDC_Architecture"
        "EventOps" = "02.01.02.01.05_EventOps"
    }}
    @{ Parent = "02.01.02.02_Cloud_Services"; Map = @{
        "Overview" = "02.01.02.02.01_Overview"
        "GCP" = "02.01.02.02.02_GCP"
        "AWS" = "02.01.02.02.03_AWS"
        "Azure" = "02.01.02.02.04_Azure"
        "Cross_Cloud" = "02.01.02.02.05_Cross_Cloud"
    }}
    @{ Parent = "02.01.02.03_Open_Source"; Map = @{
        "Overview" = "02.01.02.02.06.01_Overview"
        "Apache_Kafka" = "02.01.02.02.06.02_Apache_Kafka"
        "Apache_Pulsar" = "02.01.02.02.06.03_Apache_Pulsar"
        "Apache_Flink" = "02.01.02.02.06.04_Apache_Flink"
        "Spark_Structured_Streaming" = "02.01.02.02.06.05_Spark_Structured_Streaming"
        "Beam" = "02.01.02.02.06.06_Beam"
    }}
    @{ Parent = "02.01.02.04_Architecture_Patterns"; Map = @{
        "Event_Driven_Patterns" = "02.01.02.04.01_Event_Driven_Patterns"
        "Stream_Processing_Patterns" = "02.01.02.04.02_Stream_Processing_Patterns"
        "Integration_Patterns" = "02.01.02.04.03_Integration_Patterns"
        "CQRS_and_Event_Sourcing" = "02.01.02.04.04_CQRS_and_Event_Sourcing"
        "Reference_Architectures" = "02.01.02.04.05_Reference_Architectures"
    }}
)

$Stats = @{ renamed = 0; fm_fixed = 0; links_fixed = 0 }

function Infer-Section([string]$RelPath) {
    if ($RelPath -match '(^|[\\/])(\d{2}\.\d{2})([\\/]|$)') { return $Matches[2] }
    if ($RelPath -match '(^|[\\/])(\d{2}\.\d{2}\.\d{2})([\\/]|$)') { return $Matches[2] }
    return "09"
}

Write-Host "Phase 1: rename topic-group folders"
foreach ($group in $Renames) {
    $parentPath = Join-Path $SecRoot $group.Parent
    foreach ($entry in $group.Map.GetEnumerator()) {
        $src = Join-Path $parentPath $entry.Key
        $dest = Join-Path $parentPath $entry.Value
        if (-not (Test-Path $src)) { continue }
        if (Test-Path $dest) { Write-Warning "Skip exists: $($entry.Value)"; continue }
        if (-not $DryRun) { Rename-Item -LiteralPath $src -NewName $entry.Value }
        $Stats.renamed++
        Write-Host "  $($group.Parent)/$($entry.Key) -> $($entry.Value)"
    }
}

# Build link replacement table (full path fragments only — never bare folder names)
$LinkReplacements = @{}
foreach ($group in $Renames) {
    foreach ($entry in $group.Map.GetEnumerator()) {
        $old = "$($group.Parent)/$($entry.Key)"
        $new = "$($group.Parent)/$($entry.Value)"
        $LinkReplacements[$old.Replace('\', '/')] = $new.Replace('\', '/')
    }
}

Write-Host "Phase 2: fix front matter section field"
Get-ChildItem $SecRoot -Recurse -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($SecRoot.Length + 1).Replace('\', '/')
    $expected = Infer-Section $rel
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') { return }
    $fm = $Matches[1]
    $body = $Matches[2]
    $changed = $false
    if ($fm -match '(?m)^section:\s*"?([^"`n]+)"?') {
        if ($Matches[1].Trim() -ne $expected) {
            $fm = $fm -replace '(?m)^section:\s*"?[^"`n]+"?', "section: `"$expected`""
            $changed = $true
        }
    }
    if ($changed) {
        if (-not $DryRun) {
            [IO.File]::WriteAllText($_.FullName, "---`n$fm`n---`n$body".TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
        }
        $Stats.fm_fixed++
    }
}

Write-Host "Phase 3: update markdown links in docs/"
$patterns = $LinkReplacements.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending
Get-ChildItem $DocsRoot -Recurse -Filter *.md | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($p in $patterns) {
        $text = $text.Replace($p.Key.Replace('/', '\'), $p.Value.Replace('/', '\'))
        $text = $text.Replace($p.Key, $p.Value)
    }
    if ($text -ne $orig) {
        if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) }
        $Stats.links_fixed++
    }
}

Write-Host "Done. Renamed=$($Stats.renamed) FM=$($Stats.fm_fixed) Links=$($Stats.links_fixed)"
if ($DryRun) { Write-Host "(Dry run)" }
