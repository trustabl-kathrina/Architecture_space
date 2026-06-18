# Standardize internal subfolder and file numbering under 02.01 ingestion modes.
# Reference: 02.01.02_Streaming — SS subsection, SS.TT topic group, SS.TT.NN topic file.
# Cloud provider slots: .01 Overview, .02 GCP, .03 AWS, .04 Azure, .05 Cross_Cloud
# Top subsections: .01 Fundamentals … .09 Reference_Architectures
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$IngestRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture"
$BatchRoot = Join-Path $IngestRoot "02.01.01_Batch_Ingestion"
$NrtRoot = Join-Path $IngestRoot "02.01.03_Near_Real_Time_Ingestion"
$SharedRoot = Join-Path $IngestRoot "02.01.04_Shared_Foundations"
$Today = Get-Date -Format "yyyy-MM-dd"

function To-LongPath([string]$Path) {
    $p = [System.IO.Path]::GetFullPath($Path)
    if ($p.StartsWith('\\?\')) { return $p }
    if ($p.StartsWith('\\')) { return '\\?\UNC\' + $p.Substring(2) }
    return '\\?\' + $p
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function Move-PathSafe([string]$Src, [string]$Dst) {
    if (-not (Test-Path $Src)) { Write-Host "  skip (missing): $Src"; return $false }
    if (Test-Path $Dst) { Write-Host "  skip (exists): $Dst"; return $false }
    Ensure-Dir (Split-Path $Dst -Parent)
    if ($DryRun) { Write-Host "  would: $Src -> $Dst"; return $true }
    if ((Get-Item $Src).PSIsContainer) {
        [System.IO.Directory]::Move((To-LongPath $Src), (To-LongPath $Dst))
    } else {
        [System.IO.File]::Move((To-LongPath $Src), (To-LongPath $Dst))
    }
    Write-Host "  moved: $(Split-Path $Src -Leaf) -> $(Split-Path $Dst -Leaf)"
    return $true
}

function Write-StubMd([string]$Path, [string]$Title, [string]$Section = "02.01", [string]$H1 = $null) {
    if (Test-Path $Path) { return }
    $heading = if ($H1) { $H1 } else { $Title }
    $body = @(
        '---',
        "title: $Title",
        "section: `"$Section`"",
        'status: stub',
        'template: overview',
        "last_reviewed: $Today",
        'owner: architecture-team',
        'tags: []',
        'canonical: true',
        '---',
        '',
        "# $heading",
        '',
        'Subsection index — content to be expanded.'
    ) -join "`n"
    if ($DryRun) { Write-Host "  would create: $Path"; return }
    Ensure-Dir (Split-Path $Path -Parent)
    [IO.File]::WriteAllText((To-LongPath $Path), $body.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}

function Set-SectionFm([string]$FilePath, [string]$Section) {
    if (-not (Test-Path $FilePath)) { return }
    $text = [IO.File]::ReadAllText($FilePath)
    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') { return }
    $fmLines = $Matches[1] -split "`r?`n"
    $body = $Matches[2]
    $newFm = @(); $changed = $false
    foreach ($line in $fmLines) {
        if ($line -match '^section:\s*(.*)$') {
            $val = $Matches[1].Trim().Trim([char]34)
            if ($val -ne $Section) { $newFm += "section: `"$Section`""; $changed = $true }
            else { $newFm += $line }
        } else { $newFm += $line }
    }
    if ($changed -and -not $DryRun) {
        [IO.File]::WriteAllText($FilePath, "---`n$($newFm -join "`n")`n---`n$body".TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    }
}

# --- Phase 1: Batch Cloud Services slot alignment ---
Write-Host "Phase 1: Batch cloud provider renumbering (.03 AWS, .04 Azure, .05 Cross_Cloud)"
$batchCloud = Join-Path $BatchRoot "02.01.01.02_Cloud_Services"
# Deepest first: Cross_Cloud 03 -> 05
Move-PathSafe "$batchCloud\02.01.01.02.03_Cross_Cloud\02.01.01.02.03.01_Informatica.md" `
    "$batchCloud\02.01.01.02.05_Cross_Cloud\02.01.01.02.05.01_Informatica.md" | Out-Null
if (Test-Path "$batchCloud\02.01.01.02.03_Cross_Cloud") {
    if (-not (Test-Path "$batchCloud\02.01.01.02.05_Cross_Cloud")) {
        Move-PathSafe "$batchCloud\02.01.01.02.03_Cross_Cloud" "$batchCloud\02.01.01.02.05_Cross_Cloud" | Out-Null
    }
}
# Azure 02 -> 04
Move-PathSafe "$batchCloud\02.01.01.02.02_Azure\02.01.01.02.02.01_ADF_Batch_Ingestion.md" `
    "$batchCloud\02.01.01.02.04_Azure\02.01.01.02.04.01_ADF_Batch_Ingestion.md" | Out-Null
if (Test-Path "$batchCloud\02.01.01.02.02_Azure") {
    if (-not (Test-Path "$batchCloud\02.01.01.02.04_Azure")) {
        Move-PathSafe "$batchCloud\02.01.01.02.02_Azure" "$batchCloud\02.01.01.02.04_Azure" | Out-Null
    }
}
# AWS 01 -> 03
Move-PathSafe "$batchCloud\02.01.01.02.01_AWS\02.01.01.02.01.01_Glue.md" `
    "$batchCloud\02.01.01.02.03_AWS\02.01.01.02.03.01_Glue.md" | Out-Null
if (Test-Path "$batchCloud\02.01.01.02.01_AWS") {
    if (-not (Test-Path "$batchCloud\02.01.01.02.03_AWS")) {
        Move-PathSafe "$batchCloud\02.01.01.02.01_AWS" "$batchCloud\02.01.01.02.03_AWS" | Out-Null
    }
}

Write-Host "Phase 2: Batch subsection alignment (.07 Interview, .08 Integration, .09 Reference)"
Move-PathSafe "$BatchRoot\02.01.01.07_Reference_Architectures\README.md" `
    "$BatchRoot\02.01.01.09_Reference_Architectures\README.md" | Out-Null
if (Test-Path "$BatchRoot\02.01.01.07_Reference_Architectures") {
    if (-not (Test-Path "$BatchRoot\02.01.01.09_Reference_Architectures")) {
        Move-PathSafe "$BatchRoot\02.01.01.07_Reference_Architectures" "$BatchRoot\02.01.01.09_Reference_Architectures" | Out-Null
    }
}
Write-StubMd "$BatchRoot\02.01.01.07_Interview_Questions\README.md" "Interview Questions README" "02.01" "Interview Questions"
Write-StubMd "$BatchRoot\02.01.01.08_Integration_Patterns\README.md" "Integration Patterns README" "02.01" "Integration Patterns"

Write-Host "Phase 3: Batch Open Source + Cloud stubs"
$osReadme = "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.01_Overview\README.md"
if (Test-Path $osReadme) {
    Move-PathSafe $osReadme "$BatchRoot\02.01.01.03_Open_Source\README.md" | Out-Null
}
Write-StubMd "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.01_Overview\02.01.01.03.01.01_Open_Source_Batch_Landscape.md" "Open Source Batch Landscape"
Write-StubMd "$BatchRoot\02.01.01.02_Cloud_Services\README.md" "Cloud Services README" "02.01" "Cloud Services"
Write-StubMd "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.01_Overview\02.01.01.02.01.01_Cloud_Batch_Reference_Architecture.md" "Cloud Batch Reference Architecture"
Ensure-Dir "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.02_GCP"
Write-StubMd "$BatchRoot\02.01.01.04_Architecture_Patterns\README.md" "Architecture Patterns README" "02.01" "Architecture Patterns"
Set-SectionFm "$BatchRoot\02.01.01.01_Fundamentals\README.md" "02.01"

# --- Phase 4: NRT subsection slot alignment ---
Write-Host "Phase 4: NRT renumbering (Reference .04 -> .09, Architecture .03 -> .04)"
# Reference first (frees .04)
Move-PathSafe "$NrtRoot\02.01.03.04_Reference_Architectures\02.01.03.04.01_Real_Time_Analytics_Platform.md" `
    "$NrtRoot\02.01.03.09_Reference_Architectures\02.01.03.09.01_Real_Time_Analytics_Platform.md" | Out-Null
if (Test-Path "$NrtRoot\02.01.03.04_Reference_Architectures") {
    if (-not (Test-Path "$NrtRoot\02.01.03.09_Reference_Architectures")) {
        Move-PathSafe "$NrtRoot\02.01.03.04_Reference_Architectures" "$NrtRoot\02.01.03.09_Reference_Architectures" | Out-Null
    }
}
# Architecture 03 -> 04
Move-PathSafe "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns\02.01.03.03.01.01_Query_Based_CDC.md" `
    "$NrtRoot\02.01.03.04_Architecture_Patterns\02.01.03.04.01_CDC_Patterns\02.01.03.04.01.01_Query_Based_CDC.md" | Out-Null
Move-PathSafe "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns\02.01.03.03.01.02_Trigger_Based_CDC.md" `
    "$NrtRoot\02.01.03.04_Architecture_Patterns\02.01.03.04.01_CDC_Patterns\02.01.03.04.01.02_Trigger_Based_CDC.md" | Out-Null
if (Test-Path "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns") {
    if (-not (Test-Path "$NrtRoot\02.01.03.04_Architecture_Patterns\02.01.03.04.01_CDC_Patterns")) {
        Move-PathSafe "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns" `
            "$NrtRoot\02.01.03.04_Architecture_Patterns\02.01.03.04.01_CDC_Patterns" | Out-Null
    }
}
if (Test-Path "$NrtRoot\02.01.03.03_Architecture_Patterns") {
    $left = Get-ChildItem "$NrtRoot\02.01.03.03_Architecture_Patterns" -Recurse -ErrorAction SilentlyContinue
    if (-not $left -or $left.Count -eq 0) {
        if (-not $DryRun) { Remove-Item "$NrtRoot\02.01.03.03_Architecture_Patterns" -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "Phase 5: NRT Cloud + stubs"
$nrtGcpOld = "$NrtRoot\02.01.03.02_Cloud_Services\02.01.03.02.01_GCP"
$nrtGcpNew = "$NrtRoot\02.01.03.02_Cloud_Services\02.01.03.02.02_GCP"
if (Test-Path $nrtGcpOld) { Move-PathSafe $nrtGcpOld $nrtGcpNew | Out-Null }
Write-StubMd "$NrtRoot\02.01.03.02_Cloud_Services\README.md" "Cloud Services README" "02.01" "Cloud Services"
Write-StubMd "$NrtRoot\02.01.03.02_Cloud_Services\02.01.03.02.01_Overview\02.01.03.02.01.01_Cloud_NRT_Reference_Architecture.md" "Cloud NRT Reference Architecture"
Write-StubMd "$NrtRoot\02.01.03.04_Architecture_Patterns\README.md" "Architecture Patterns README" "02.01" "Architecture Patterns"
Write-StubMd "$NrtRoot\02.01.03.09_Reference_Architectures\README.md" "Reference Architectures README" "02.01" "Reference Architectures"
Write-StubMd "$NrtRoot\02.01.03.01_Fundamentals\02.01.03.01.02_Micro_Batch_Patterns\02.01.03.01.02.01_Micro_Batch_Patterns.md" "Micro Batch Patterns"
Write-StubMd "$NrtRoot\02.01.03.07_Interview_Questions\README.md" "Interview Questions README" "02.01" "Interview Questions"
Write-StubMd "$NrtRoot\02.01.03.08_Integration_Patterns\README.md" "Integration Patterns README" "02.01" "Integration Patterns"
Set-SectionFm "$NrtRoot\02.01.03.01_Fundamentals\README.md" "02.01"

# --- Phase 6: Shared Foundations — add topic-group depth ---
Write-Host "Phase 6: Shared Foundations topic-group depth"
$sharedGroups = @(
    @{ Sub = "02.01.04.01_Overview"; Group = "02.01.04.01.01_Core" }
    @{ Sub = "02.01.04.02_Data_Engineering_Strategy"; Group = "02.01.04.02.01_Strategy" }
    @{ Sub = "02.01.04.03_Data_Pipeline_Architecture"; Group = "02.01.04.03.01_Pipeline" }
    @{ Sub = "02.01.04.04_Enterprise_Data_Frameworks"; Group = "02.01.04.04.01_Frameworks" }
    @{ Sub = "02.01.04.05_Reference_Architectures"; Group = "02.01.04.05.01_Platforms" }
    @{ Sub = "02.01.04.06_Cross_Mode_Ingestion"; Group = "02.01.04.06.01_Ingestion" }
)
foreach ($sg in $sharedGroups) {
    $subPath = Join-Path $SharedRoot $sg.Sub
    $groupPath = Join-Path $subPath $sg.Group
    Ensure-Dir $groupPath
    $files = Get-ChildItem $subPath -Filter "*.md" -File -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($f in $files) {
        if ($f.Name -match '^(02\.01\.04\.\d{2})\.(\d{2})_(.+)\.md$') {
            $subPrefix = $Matches[1]
            $num = $Matches[2]
            $rest = $Matches[3]
            $newName = "$subPrefix.01.$num`_$rest.md"
            $dst = Join-Path $groupPath $newName
            Move-PathSafe $f.FullName $dst | Out-Null
        }
    }
    Write-StubMd (Join-Path $subPath "README.md") "$($sg.Sub) README" "02.01" ($(Split-Path $sg.Sub -Leaf) -replace '^\d+_\d+_\d+_\d+_','')
}

# --- Phase 7: global link replacements ---
Write-Host "Phase 7: global link updates"
$baseRepl = @(
    # Batch cloud
    @{ O = '02.01.01.02.01_AWS/02.01.01.02.01.01_Glue'; N = '02.01.01.02.03_AWS/02.01.01.02.03.01_Glue' }
    @{ O = '02.01.01.02.02_Azure/02.01.01.02.02.01_ADF_Batch_Ingestion'; N = '02.01.01.02.04_Azure/02.01.01.02.04.01_ADF_Batch_Ingestion' }
    @{ O = '02.01.01.02.03_Cross_Cloud/02.01.01.02.03.01_Informatica'; N = '02.01.01.02.05_Cross_Cloud/02.01.01.02.05.01_Informatica' }
    @{ O = '02.01.01.07_Reference_Architectures'; N = '02.01.01.09_Reference_Architectures' }
    # NRT
    @{ O = '02.01.03.04_Reference_Architectures/02.01.03.04.01_Real_Time_Analytics_Platform'; N = '02.01.03.09_Reference_Architectures/02.01.03.09.01_Real_Time_Analytics_Platform' }
    @{ O = '02.01.03.04_Reference_Architectures'; N = '02.01.03.09_Reference_Architectures' }
    @{ O = '02.01.03.03_Architecture_Patterns/02.01.03.03.01_CDC_Patterns/02.01.03.03.01.01_Query_Based_CDC'; N = '02.01.03.04_Architecture_Patterns/02.01.03.04.01_CDC_Patterns/02.01.03.04.01.01_Query_Based_CDC' }
    @{ O = '02.01.03.03_Architecture_Patterns/02.01.03.03.01_CDC_Patterns/02.01.03.03.01.02_Trigger_Based_CDC'; N = '02.01.03.04_Architecture_Patterns/02.01.03.04.01_CDC_Patterns/02.01.03.04.01.02_Trigger_Based_CDC' }
    @{ O = '02.01.03.03_Architecture_Patterns'; N = '02.01.03.04_Architecture_Patterns' }
    # Shared topic-group depth
    @{ O = '02.01.04.02_Data_Engineering_Strategy/02.01.04.02.01.'; N = '02.01.04.02_Data_Engineering_Strategy/02.01.04.02.01_Strategy/02.01.04.02.01.' }
    @{ O = '02.01.04.03_Data_Pipeline_Architecture/02.01.04.03.01.'; N = '02.01.04.03_Data_Pipeline_Architecture/02.01.04.03.01_Pipeline/02.01.04.03.01.' }
    @{ O = '02.01.04.04_Enterprise_Data_Frameworks/02.01.04.04.01.'; N = '02.01.04.04_Enterprise_Data_Frameworks/02.01.04.04.01_Frameworks/02.01.04.04.01.' }
    @{ O = '02.01.04.05_Reference_Architectures/02.01.04.05.01.'; N = '02.01.04.05_Reference_Architectures/02.01.04.05.01_Platforms/02.01.04.05.01.' }
    @{ O = '02.01.04.06_Cross_Mode_Ingestion/02.01.04.06.01.'; N = '02.01.04.06_Cross_Mode_Ingestion/02.01.04.06.01_Ingestion/02.01.04.06.01.' }
)
$repl = [System.Collections.Generic.List[object]]::new()
$repl.AddRange($baseRepl)
foreach ($sg in $sharedGroups) {
    if ($sg.Group -match '02\.01\.04\.(\d{2})\.01') {
        $ss = $Matches[1]
        for ($i = 1; $i -le 20; $i++) {
            $nn = '{0:D2}' -f $i
            [void]$repl.Add(@{ O = "02.01.04.$ss.$nn`_"; N = "02.01.04.$ss.01.$nn`_" })
        }
    }
}

$repl = $repl | Sort-Object { $_.O.Length } -Descending
$globalFixed = 0
Get-ChildItem $RepoRoot -Recurse -Include *.md,*.yaml,*.yml -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.FullName -match '\\(\.git|site|node_modules)\\') { return }
    if ($_.Name -match 'renumber_02_01_internal') { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    $updated = $text
    foreach ($r in $repl) { $updated = $updated.Replace($r.O, $r.N) }
    if ($updated -ne $text) {
        if (-not $DryRun) { [IO.File]::WriteAllText((To-LongPath $_.FullName), $updated, [Text.UTF8Encoding]::new($false)) }
        $globalFixed++
    }
}
Write-Host "  updated $globalFixed files repo-wide"

Write-Host "Done."
