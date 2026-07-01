param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$DocsRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "docs"
$Sec09 = "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming"

$Stats = @{ collapsed = 0; reverted = 0 }

Write-Host "Phase 1: collapse duplicated NN.NN.NN_ prefixes"
for ($i = 0; $i -lt 5; $i++) {
    $round = 0
    Get-ChildItem $DocsRoot -Recurse -Filter *.md | ForEach-Object {
        $text = [IO.File]::ReadAllText($_.FullName)
        $new = [regex]::Replace($text, '(\d{2}\.\d{2}\.\d{2})_\1_', '${1}_')
        if ($new -ne $text) {
            if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $new, [Text.UTF8Encoding]::new($false)) }
            $round++
        }
    }
    $Stats.collapsed += $round
    if ($round -eq 0) { break }
}

Write-Host "  Rounds fixed: $($Stats.collapsed)"

Write-Host "Phase 2: revert stray replacements outside 02.07"
$cloudRevert = @{
    "02.01.02.02.03_AWS" = "AWS"
    "02.01.02.02.04_Azure" = "Azure"
    "02.01.02.02.02_GCP" = "GCP"
}

Get-ChildItem $DocsRoot -Recurse -Filter *.md | Where-Object {
    $_.FullName -notmatch [regex]::Escape($Sec09)
} | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($e in $cloudRevert.GetEnumerator()) {
        $text = $text.Replace($e.Key, $e.Value)
    }
    $text = $text -replace '_09\.01\.02_Strategy', '_Strategy'
    $text = $text -replace 'Enterprise_09\.01\.02_Strategy_And_Operating_Model', 'Enterprise_Strategy_And_Operating_Model'
    $text = $text -replace '09\.01\.02_Strategy_And_Operating_Model', 'Strategy_And_Operating_Model'
    $text = $text -replace '/09\.01\.01_Overview/', '/Overview/'
    $text = $text -replace '\\09\.01\.01_Overview\\', '\Overview\'
    if ($text -ne $orig) {
        if (-not $DryRun) { [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) }
        $Stats.reverted++
    }
}

Write-Host "Phase 3: fix front matter in 02.07 only"
$SecRoot = Join-Path $DocsRoot $Sec09
Get-ChildItem $SecRoot -Recurse -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring($SecRoot.Length + 1).Replace('\', '/')
    $expected = if ($rel -match '(^|/)(\d{2}\.\d{2}\.\d{2})(/|$)') { $Matches[2] }
                elseif ($rel -match '(^|/)(\d{2}\.\d{2})(/|$)') { $Matches[2] }
                else { "09" }
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
        $fm = $Matches[1]; $body = $Matches[2]
        if ($fm -match '(?m)^section:\s*"?([^"`n]+)"?') {
            if ($Matches[1].Trim() -ne $expected) {
                $fm = $fm -replace '(?m)^section:\s*"?[^"`n]+"?', "section: `"$expected`""
                if (-not $DryRun) {
                    [IO.File]::WriteAllText($_.FullName, "---`n$fm`n---`n$body".TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
                }
            }
        }
    }
}

Write-Host "Phase 4: fix internal links in 02.07 only"
$pathMap = @{}
foreach ($group in @(
    @{ P = "02.01.02.01_Fundamentals"; M = @{
        "Overview"="02.01.02.01.01_Overview"; "Strategy"="02.01.02.01.02_Strategy"; "Core_Concepts"="02.01.02.01.03_Core_Concepts"
        "CDC_Architecture"="02.01.02.01.04_CDC_Architecture"; "EventOps"="02.01.02.01.05_EventOps" }}
    @{ P = "02.01.02.02_Cloud_Services"; M = @{
        "Overview"="02.01.02.02.01_Overview"; "GCP"="02.01.02.02.02_GCP"; "AWS"="02.01.02.02.03_AWS"
        "Azure"="02.01.02.02.04_Azure"; "Cross_Cloud"="02.01.02.02.05_Cross_Cloud" }}
    @{ P = "02.01.02.03_Open_Source"; M = @{
        "Overview"="02.01.02.02.06.01_Overview"; "Apache_Kafka"="02.01.02.02.06.02_Apache_Kafka"; "Apache_Pulsar"="02.01.02.02.06.03_Apache_Pulsar"
        "Apache_Flink"="02.01.02.02.06.04_Apache_Flink"; "Spark_Structured_Streaming"="02.01.02.02.06.05_Spark_Structured_Streaming"; "Beam"="02.01.02.02.06.06_Beam" }}
    @{ P = "02.01.02.04_Architecture_Patterns"; M = @{
        "Event_Driven_Patterns"="02.01.02.04.01_Event_Driven_Patterns"; "Stream_Processing_Patterns"="02.01.02.04.02_Stream_Processing_Patterns"
        "Integration_Patterns"="02.01.02.04.03_Integration_Patterns"; "CQRS_and_Event_Sourcing"="02.01.02.04.04_CQRS_and_Event_Sourcing"
        "Reference_Architectures"="02.01.02.04.05_Reference_Architectures" }}
)) {
    foreach ($e in $group.M.GetEnumerator()) {
        $pathMap["$($group.P)/$($e.Key)"] = "$($group.P)/$($e.Value)"
    }
}

Get-ChildItem $SecRoot -Recurse -Filter *.md | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($e in ($pathMap.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending)) {
        $text = $text.Replace($e.Key.Replace('/', '\'), $e.Value.Replace('/', '\'))
        $text = $text.Replace($e.Key, $e.Value)
    }
    if ($text -ne $orig -and -not $DryRun) {
        [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false))
    }
}

# Fix cross-links from section 02
$deLink = Join-Path $DocsRoot "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture\Overview\What_Is_Data_Engineering.md"
if (Test-Path $deLink) {
    $t = [IO.File]::ReadAllText($deLink)
    $n = $t -replace '09\.01_Fundamentals/Strategy/', '02.01.02.01_Fundamentals/02.01.02.01.02_Strategy/'
    if ($n -ne $t -and -not $DryRun) { [IO.File]::WriteAllText($deLink, $n, [Text.UTF8Encoding]::new($false)) }
}

Write-Host "Done. Collapsed=$($Stats.collapsed) Reverted=$($Stats.reverted)"
