# Organize 02.01 Data Ingestion: scaffold Batch, NRT, Shared Foundations; relocate legacy root content.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$IngestRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture"
$BatchRoot = Join-Path $IngestRoot "02.01.01_Batch_Ingestion"
$StreamRoot = Join-Path $IngestRoot "02.01.02_Streaming"
$NrtRoot = Join-Path $IngestRoot "02.01.03_Near_Real_Time_Ingestion"
$SharedRoot = Join-Path $IngestRoot "02.01.04_Shared_Foundations"
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

function Move-FileMapped([string]$Src, [string]$Dst) {
    if (-not (Test-Path $Src)) { Write-Host "  skip (missing): $Src"; return $false }
    if (Test-Path $Dst) { Write-Host "  skip (exists): $Dst"; return $false }
    Ensure-Dir (Split-Path $Dst -Parent)
    if ($DryRun) { Write-Host "  would move: $(Split-Path $Src -Leaf) -> $Dst"; return $true }
    [System.IO.File]::Move((To-LongPath $Src), (To-LongPath $Dst))
    Write-Host "  moved: $(Split-Path $Src -Leaf) -> $(Split-Path $Dst -Leaf)"
    return $true
}

function Write-RedirectStub([string]$Path, [string]$Section, [string]$Title, [string]$RedirectRel) {
    $dir = Split-Path $Path -Parent
    Ensure-Dir $dir
    $body = @(
        '---',
        "title: $Title (Moved)",
        "section: `"$Section`"",
        'status: complete',
        'template: redirect',
        "last_reviewed: $Today",
        'owner: architecture-team',
        'tags: [redirect]',
        'canonical: false',
        "redirect_to: $RedirectRel",
        '---',
        '',
        "# Moved",
        '',
        "This document now lives at [$RedirectRel]($RedirectRel)."
    ) -join "`n"
    if ($DryRun) { Write-Host "  would write redirect: $Path"; return }
    [IO.File]::WriteAllText((To-LongPath $Path), $body.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}

function Write-StubReadme([string]$Path, [string]$Section, [string]$Title) {
    $body = @(
        '---',
        "title: $Title README",
        "section: `"$Section`"",
        'status: stub',
        'template: overview',
        "last_reviewed: $Today",
        'owner: architecture-team',
        'tags: []',
        'canonical: true',
        '---',
        '',
        "# $Title",
        '',
        'Subsection index — content to be expanded.'
    ) -join "`n"
    if ($DryRun) { return }
    Ensure-Dir (Split-Path $Path -Parent)
    if (-not (Test-Path $Path)) {
        [IO.File]::WriteAllText((To-LongPath $Path), $body.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    }
}

function Infer-Section([string]$RelPath) {
    $r = $RelPath.Replace('\', '/')
    if ($r -match '(?:^|/)(\d{2}(?:\.\d{2}){1,5})(?:[._/]|$)') { return $Matches[1] }
    if ($r -match '(?:^|/)(\d{2})_') { return $Matches[1] }
    return "02.01"
}

# --- Phase 1: scaffold subsection folders ---
Write-Host "Phase 1: scaffold folders"
$dirs = @(
    "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.01_Overview",
    "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.02_Ingestion_Patterns",
    "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.03_Platform",
    "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.01_AWS",
    "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.02_Azure",
    "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.03_Cross_Cloud",
    "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.01_Overview",
    "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.02_Apache_NiFi",
    "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.03_SaaS_ETL",
    "$BatchRoot\02.01.01.04_Architecture_Patterns\02.01.01.04.01_ETL_ELT",
    "$BatchRoot\02.01.01.05_Benchmarks",
    "$BatchRoot\02.01.01.06_Comparisons",
    "$BatchRoot\02.01.01.07_Reference_Architectures",
    "$NrtRoot\02.01.03.01_Fundamentals\02.01.03.01.01_Strategy",
    "$NrtRoot\02.01.03.01_Fundamentals\02.01.03.01.02_Micro_Batch_Patterns",
    "$NrtRoot\02.01.03.02_Cloud_Services\02.01.03.02.01_GCP",
    "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns",
    "$NrtRoot\02.01.03.04_Reference_Architectures",
    "$NrtRoot\02.01.03.05_Benchmarks",
    "$NrtRoot\02.01.03.06_Comparisons",
    "$SharedRoot\02.01.04.01_Overview",
    "$SharedRoot\02.01.04.02_Data_Engineering_Strategy",
    "$SharedRoot\02.01.04.03_Data_Pipeline_Architecture",
    "$SharedRoot\02.01.04.04_Enterprise_Data_Frameworks",
    "$SharedRoot\02.01.04.05_Reference_Architectures",
    "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion",
    "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.01_Overview",
    "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture"
)
foreach ($d in $dirs) { Ensure-Dir $d }

Write-StubReadme "$BatchRoot\02.01.01.05_Benchmarks\README.md" "02.01.01.05" "Benchmarks"
Write-StubReadme "$BatchRoot\02.01.01.06_Comparisons\README.md" "02.01.01.06" "Comparisons"
Write-StubReadme "$BatchRoot\02.01.01.07_Reference_Architectures\README.md" "02.01.01.07" "Reference Architectures"
Write-StubReadme "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.01_Overview\README.md" "02.01.01.03.01" "Open Source Batch Landscape"
Write-StubReadme "$NrtRoot\02.01.03.05_Benchmarks\README.md" "02.01.03.05" "Benchmarks"
Write-StubReadme "$NrtRoot\02.01.03.06_Comparisons\README.md" "02.01.03.06" "Comparisons"
Write-StubReadme "$NrtRoot\02.01.03.01_Fundamentals\02.01.03.01.02_Micro_Batch_Patterns\README.md" "02.01.03.01.02" "Micro-Batch Patterns"
Write-StubReadme "$SharedRoot\README.md" "02.01.04" "Shared Foundations"

# --- Phase 2: relocate root loose files ---
Write-Host "Phase 2: relocate root loose files"
$rootMoves = @(
    @{ S = "Batch_Ingestion.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.01_Overview\02.01.01.01.01.01_Batch_Ingestion.md" }
    @{ S = "Batch_Integration.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.01_Overview\02.01.01.01.01.02_Batch_Integration.md" }
    @{ S = "File_Based_Ingestion.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.02_Ingestion_Patterns\02.01.01.01.02.01_File_Based_Ingestion.md" }
    @{ S = "Database_Ingestion.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.02_Ingestion_Patterns\02.01.01.01.02.02_Database_Ingestion.md" }
    @{ S = "SaaS_Ingestion.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.02_Ingestion_Patterns\02.01.01.01.02.03_SaaS_Ingestion.md" }
    @{ S = "API_Ingestion.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.02_Ingestion_Patterns\02.01.01.01.02.04_API_Ingestion.md" }
    @{ S = "Glue.md"; D = "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.01_AWS\02.01.01.02.01.01_Glue.md" }
    @{ S = "Informatica.md"; D = "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.03_Cross_Cloud\02.01.01.02.03.01_Informatica.md" }
    @{ S = "NiFi.md"; D = "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.02_Apache_NiFi\02.01.01.03.02.01_NiFi.md" }
    @{ S = "Airbyte.md"; D = "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.03_SaaS_ETL\02.01.01.03.03.01_Airbyte.md" }
    @{ S = "Fivetran.md"; D = "$BatchRoot\02.01.01.03_Open_Source\02.01.01.03.03_SaaS_ETL\02.01.01.03.03.02_Fivetran.md" }
    @{ S = "ETL_Architecture.md"; D = "$BatchRoot\02.01.01.04_Architecture_Patterns\02.01.01.04.01_ETL_ELT\02.01.01.04.01.01_ETL_Architecture.md" }
    @{ S = "ELT_Architecture.md"; D = "$BatchRoot\02.01.01.04_Architecture_Patterns\02.01.01.04.01_ETL_ELT\02.01.01.04.01.02_ELT_Architecture.md" }
    @{ S = "Event_Ingestion.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.01_Overview\02.01.02.01.01.04_Event_Ingestion.md" }
    @{ S = "Streaming_Ingestion.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.01_Overview\02.01.02.01.01.05_Streaming_Ingestion.md" }
    @{ S = "Streaming_Integration.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.01_Overview\02.01.02.01.01.06_Streaming_Integration.md" }
    @{ S = "CDC_Architecture.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.05_CDC_Architecture.md" }
    @{ S = "CDC_Architecture_Patterns.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.06_CDC_Architecture_Patterns.md" }
    @{ S = "CDC_Governance.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.07_CDC_Governance.md" }
    @{ S = "CDC_Ingestion.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.08_CDC_Ingestion.md" }
    @{ S = "CDC_Monitoring.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.09_CDC_Monitoring.md" }
    @{ S = "CDC_Optimization.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.10_CDC_Optimization.md" }
    @{ S = "CDC_Reference_Model.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.11_CDC_Reference_Model.md" }
    @{ S = "Log_Based_CDC.md"; D = "$StreamRoot\02.01.02.01_Fundamentals\02.01.02.01.04_CDC_Architecture\02.01.02.01.04.12_Log_Based_CDC.md" }
    @{ S = "Query_Based_CDC.md"; D = "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns\02.01.03.03.01.01_Query_Based_CDC.md" }
    @{ S = "Trigger_Based_CDC.md"; D = "$NrtRoot\02.01.03.03_Architecture_Patterns\02.01.03.03.01_CDC_Patterns\02.01.03.03.01.02_Trigger_Based_CDC.md" }
    @{ S = "Ingestion_Patterns.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.01_Ingestion_Patterns.md" }
    @{ S = "Ingestion_Standards.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.02_Ingestion_Standards.md" }
    @{ S = "Source_Onboarding_Framework.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.03_Source_Onboarding_Framework.md" }
    @{ S = "Data_Contracts.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.04_Data_Contracts.md" }
    @{ S = "Data_Integration_Framework.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.05_Data_Integration_Framework.md" }
    @{ S = "Data_Replication.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.06_Data_Replication.md" }
    @{ S = "Data_Synchronization.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.07_Data_Synchronization.md" }
    @{ S = "Data_Virtualization.md"; D = "$SharedRoot\02.01.04.06_Cross_Mode_Ingestion\02.01.04.06.08_Data_Virtualization.md" }
)
$movedCount = 0
foreach ($m in $rootMoves) {
  $src = Join-Path $IngestRoot $m.S
  if (Move-FileMapped $src $m.D) { $movedCount++ }
}

# Batch internal renames (already in batch root)
$batchInternal = @(
    @{ S = "$BatchRoot\02.01.01.01_Batch_Data_Platform.md"; D = "$BatchRoot\02.01.01.01_Fundamentals\02.01.01.01.03_Platform\02.01.01.01.03.01_Batch_Data_Platform.md" }
    @{ S = "$BatchRoot\02.01.01.02_ADF_Batch_Ingestion.md"; D = "$BatchRoot\02.01.01.02_Cloud_Services\02.01.01.02.02_Azure\02.01.01.02.02.01_ADF_Batch_Ingestion.md" }
)
foreach ($m in $batchInternal) {
    if (Move-FileMapped $m.S $m.D) { $movedCount++ }
}

# NRT internal rename
$nrtInternal = @(
    @{ S = "$NrtRoot\02.01.03.01_Real_Time_Data_Strategy.md"; D = "$NrtRoot\02.01.03.01_Fundamentals\02.01.03.01.01_Strategy\02.01.03.01.01.01_Real_Time_Data_Strategy.md" }
)
foreach ($m in $nrtInternal) {
    if (Move-FileMapped $m.S $m.D) { $movedCount++ }
}

# Redirect stubs for duplicate / consolidated topics at root
Write-Host "Phase 3: redirect stubs for consolidated root topics"
if (Test-Path (Join-Path $IngestRoot "CDC_Overview.md")) {
    Write-RedirectStub (Join-Path $IngestRoot "CDC_Overview.md") "02.01.02.01.04.01" "CDC Overview" "02.01.02_Streaming/02.01.02.01_Fundamentals/02.01.02.01.04_CDC_Architecture/02.01.02.01.04.01_CDC_Overview.md"
}
if (Test-Path (Join-Path $IngestRoot "Kafka_Connect.md")) {
    Write-RedirectStub (Join-Path $IngestRoot "Kafka_Connect.md") "02.01.02.03.02.04" "Kafka Connect" "02.01.02_Streaming/02.01.02.03_Open_Source/02.01.02.03.02_Apache_Kafka/02.01.02.03.02.04_Kafka_Connect.md"
}
if (Test-Path (Join-Path $IngestRoot "Dataflow.md")) {
    Write-RedirectStub (Join-Path $IngestRoot "Dataflow.md") "02.01.02.02.02.05" "GCP Dataflow" "02.01.02_Streaming/02.01.02.02_Cloud_Services/02.01.02.02.02_GCP/02.01.02.02.02.05_Dataflow_Learning_Guide/README.md"
}
# Root Ingestion_Framework duplicates Enterprise — redirect if both exist
$entIngestion = Join-Path $IngestRoot "Enterprise_Data_Frameworks\Ingestion_Framework.md"
if ((Test-Path (Join-Path $IngestRoot "Ingestion_Framework.md")) -and (Test-Path $entIngestion)) {
    Write-RedirectStub (Join-Path $IngestRoot "Ingestion_Framework.md") "02.01.04.04.05" "Ingestion Framework" "02.01.04_Shared_Foundations/02.01.04.04_Enterprise_Data_Frameworks/02.01.04.04.05_Ingestion_Framework.md"
}

# --- Phase 4: move legacy folders into 02.01.04 with numbering ---
Write-Host "Phase 4: relocate legacy folders to 02.01.04"

$overviewMap = @(
    @{ F = "What_Is_Data_Engineering.md"; N = "02.01.04.01.01_What_Is_Data_Engineering.md" }
    @{ F = "Data_Engineering_Vision.md"; N = "02.01.04.01.02_Data_Engineering_Vision.md" }
    @{ F = "Data_Engineering_Capability_Map.md"; N = "02.01.04.01.03_Data_Engineering_Capability_Map.md" }
    @{ F = "Data_Engineering_Maturity_Model.md"; N = "02.01.04.01.04_Data_Engineering_Maturity_Model.md" }
    @{ F = "Data_Engineering_Roles_And_Responsibilities.md"; N = "02.01.04.01.05_Data_Engineering_Roles_And_Responsibilities.md" }
    @{ F = "Data_Engineering_Principles.md"; N = "02.01.04.01.06_Data_Engineering_Principles.md" }
    @{ F = "Data_Engineering_Target_State.md"; N = "02.01.04.01.07_Data_Engineering_Target_State.md" }
    @{ F = "Data_Engineering_Operating_Model.md"; N = "02.01.04.01.08_Data_Engineering_Operating_Model.md" }
)
$i = 0
foreach ($item in $overviewMap) {
    $src = Join-Path $IngestRoot "Overview\$($item.F)"
    $dst = Join-Path $SharedRoot "02.01.04.01_Overview\$($item.N)"
    if (Move-FileMapped $src $dst) { $i++ }
}

$strategyFiles = @(
    "Data_Engineering_Strategy.md", "Cloud_Data_Engineering_Strategy.md", "Data_Automation_Strategy.md",
    "Data_Engineering_Roadmap.md", "Data_Modernization_Strategy.md", "Data_Product_Delivery_Strategy.md",
    "Enterprise_Data_Platform_Strategy.md", "Technology_Standardization.md"
)
$si = 1
foreach ($f in $strategyFiles) {
    $base = [IO.Path]::GetFileNameWithoutExtension($f)
    $dst = Join-Path $SharedRoot "02.01.04.02_Data_Engineering_Strategy\02.01.04.02.$('{0:D2}' -f $si)_$base.md"
    Move-FileMapped (Join-Path $IngestRoot "Data_Engineering_Strategy\$f") $dst | Out-Null
    $si++
}

$pipelineFiles = Get-ChildItem (Join-Path $IngestRoot "Data_Pipeline_Architecture") -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object Name
$pi = 1
foreach ($f in $pipelineFiles) {
    $base = $f.BaseName
    $dst = Join-Path $SharedRoot "02.01.04.03_Data_Pipeline_Architecture\02.01.04.03.$('{0:D2}' -f $pi)_$base.md"
    Move-FileMapped $f.FullName $dst | Out-Null
    $pi++
}

$frameworkFiles = Get-ChildItem (Join-Path $IngestRoot "Enterprise_Data_Frameworks") -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object Name
$fi = 1
foreach ($f in $frameworkFiles) {
    $base = $f.BaseName
    $dst = Join-Path $SharedRoot "02.01.04.04_Enterprise_Data_Frameworks\02.01.04.04.$('{0:D2}' -f $fi)_$base.md"
    Move-FileMapped $f.FullName $dst | Out-Null
    $fi++
}

$refMoves = @(
    @{ S = "Enterprise_Lakehouse.md"; N = "02.01.04.05.01_Enterprise_Lakehouse.md" }
    @{ S = "Multi_Cloud_Data_Platform.md"; N = "02.01.04.05.02_Multi_Cloud_Data_Platform.md" }
    @{ S = "Telecom_Data_Platform.md"; N = "02.01.04.05.03_Telecom_Data_Platform.md" }
    @{ S = "AI_Ready_Data_Platform.md"; N = "02.01.04.05.04_AI_Ready_Data_Platform.md" }
    @{ S = "Data_Product_Platform.md"; N = "02.01.04.05.05_Data_Product_Platform.md" }
    @{ S = "Metadata_Driven_Platform.md"; N = "02.01.04.05.06_Metadata_Driven_Platform.md" }
    @{ S = "Real_Time_Analytics_Platform.md"; N = "02.01.03.04.01_Real_Time_Analytics_Platform.md"; Root = $NrtRoot; Sub = "02.01.03.04_Reference_Architectures" }
)
foreach ($r in $refMoves) {
    if ($r.Sub) {
        $dst = Join-Path $NrtRoot "$($r.Sub)\$($r.N)"
    } else {
        $dst = Join-Path $SharedRoot "02.01.04.05_Reference_Architectures\$($r.N)"
    }
    Move-FileMapped (Join-Path $IngestRoot "Reference_Architectures\$($r.S)") $dst | Out-Null
}

# Remove empty legacy folders
Write-Host "Phase 5: remove empty legacy folders"
$legacyDirs = @("Overview", "Data_Engineering_Strategy", "Data_Pipeline_Architecture", "Enterprise_Data_Frameworks", "Reference_Architectures")
foreach ($ld in $legacyDirs) {
    $p = Join-Path $IngestRoot $ld
    if (-not (Test-Path $p)) { continue }
    $remaining = Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue
    if ($remaining.Count -eq 0) {
        if (-not $DryRun) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "  removed empty: $ld"
    } else {
        Write-Host "  kept (not empty): $ld ($($remaining.Count) items)"
    }
}

# --- Phase 6: link replacements ---
Write-Host "Phase 6: global link updates"
$linkReplacements = @(
    @{ O = '02.01_Data_Ingestion_Architecture/Overview/'; N = '02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/02.01.04.01_Overview/' }
    @{ O = '02.01_Data_Ingestion_Architecture/Data_Engineering_Strategy/'; N = '02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/02.01.04.02_Data_Engineering_Strategy/' }
    @{ O = '02.01_Data_Ingestion_Architecture/Data_Pipeline_Architecture/'; N = '02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/02.01.04.03_Data_Pipeline_Architecture/' }
    @{ O = '02.01_Data_Ingestion_Architecture/Enterprise_Data_Frameworks/'; N = '02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/02.01.04.04_Enterprise_Data_Frameworks/' }
    @{ O = '02.01_Data_Ingestion_Architecture/Reference_Architectures/'; N = '02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/02.01.04.05_Reference_Architectures/' }
    @{ O = '02.01.01_Batch_Ingestion/02.01.01.01_Batch_Data_Platform.md'; N = '02.01.01_Batch_Ingestion/02.01.01.01_Fundamentals/02.01.01.01.03_Platform/02.01.01.01.03.01_Batch_Data_Platform.md' }
    @{ O = '02.01.01_Batch_Ingestion/02.01.01.02_ADF_Batch_Ingestion.md'; N = '02.01.01_Batch_Ingestion/02.01.01.02_Cloud_Services/02.01.01.02.02_Azure/02.01.01.02.02.01_ADF_Batch_Ingestion.md' }
    @{ O = '02.01.03_Near_Real_Time_Ingestion/02.01.03.01_Real_Time_Data_Strategy.md'; N = '02.01.03_Near_Real_Time_Ingestion/02.01.03.01_Fundamentals/02.01.03.01.01_Strategy/02.01.03.01.01.01_Real_Time_Data_Strategy.md' }
    @{ O = 'Reference_Architectures/Real_Time_Analytics_Platform.md'; N = '02.01.03_Near_Real_Time_Ingestion/02.01.03.04_Reference_Architectures/02.01.03.04.01_Real_Time_Analytics_Platform.md' }
    @{ O = 'Reference_Architectures/Batch_Data_Platform.md'; N = '02.01.01_Batch_Ingestion/02.01.01.01_Fundamentals/02.01.01.01.03_Platform/02.01.01.01.03.01_Batch_Data_Platform.md' }
    @{ O = 'Overview/What_Is_Data_Engineering.md'; N = '02.01.04_Shared_Foundations/02.01.04.01_Overview/02.01.04.01.01_What_Is_Data_Engineering.md' }
    @{ O = 'Data_Engineering_Strategy/Data_Engineering_Strategy.md'; N = '02.01.04_Shared_Foundations/02.01.04.02_Data_Engineering_Strategy/02.01.04.02.01_Data_Engineering_Strategy.md' }
    @{ O = 'Data_Pipeline_Architecture/Pipeline_Reference_Model.md'; N = '02.01.04_Shared_Foundations/02.01.04.03_Data_Pipeline_Architecture/02.01.04.03.08_Pipeline_Reference_Model.md' }
    @{ O = 'Enterprise_Data_Frameworks/Ingestion_Framework.md'; N = '02.01.04_Shared_Foundations/02.01.04.04_Enterprise_Data_Frameworks/02.01.04.04.05_Ingestion_Framework.md' }
    @{ O = 'Reference_Architectures/Enterprise_Lakehouse.md'; N = '02.01.04_Shared_Foundations/02.01.04.05_Reference_Architectures/02.01.04.05.01_Enterprise_Lakehouse.md' }
    # Root loose file paths (relative under 02.01)
    @{ O = '02.01_Data_Ingestion_Architecture/Batch_Ingestion.md'; N = '02.01_Data_Ingestion_Architecture/02.01.01_Batch_Ingestion/02.01.01.01_Fundamentals/02.01.01.01.01_Overview/02.01.01.01.01.01_Batch_Ingestion.md' }
    @{ O = '02.01_Data_Ingestion_Architecture/ETL_Architecture.md'; N = '02.01_Data_Ingestion_Architecture/02.01.01_Batch_Ingestion/02.01.01.04_Architecture_Patterns/02.01.01.04.01_ETL_ELT/02.01.01.04.01.01_ETL_Architecture.md' }
    @{ O = '02.01_Data_Ingestion_Architecture/CDC_Architecture.md'; N = '02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/02.01.02.01.04_CDC_Architecture/02.01.02.01.04.05_CDC_Architecture.md' }
    @{ O = '02.01_Data_Ingestion_Architecture/Ingestion_Patterns.md'; N = '02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/02.01.04.06_Cross_Mode_Ingestion/02.01.04.06.01_Ingestion_Patterns.md' }
)

# Per-file replacements for overview (unnumbered -> numbered)
foreach ($item in $overviewMap) {
    $linkReplacements += @{ O = "Overview/$($item.F)"; N = "02.01.04_Shared_Foundations/02.01.04.01_Overview/$($item.N)" }
}

$globalFixed = 0
Get-ChildItem $RepoRoot -Recurse -Include *.md,*.yaml,*.yml -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.FullName -match '\\(\.git|site|node_modules)\\') { return }
    if ($_.Name -eq 'organize_02_01_ingestion_modes.ps1') { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    $updated = $text
    foreach ($r in $linkReplacements) { $updated = $updated.Replace($r.O, $r.N) }
    if ($updated -ne $text) {
        if (-not $DryRun) { [IO.File]::WriteAllText((To-LongPath $_.FullName), $updated, [Text.UTF8Encoding]::new($false)) }
        $globalFixed++
    }
}
Write-Host "  updated $globalFixed files repo-wide"

# --- Phase 7: fix front matter section under moved trees ---
Write-Host "Phase 7: fix front matter"
$fmFixed = 0
$trees = @($BatchRoot, $NrtRoot, $SharedRoot)
foreach ($tree in $trees) {
    if (-not (Test-Path $tree)) { continue }
    foreach ($filePath in [System.IO.Directory]::EnumerateFiles((To-LongPath $tree), '*.md', 'AllDirectories')) {
        $norm = $filePath -replace '^\\\\\?\\',''
        $text = [IO.File]::ReadAllText($filePath)
        $rel = $norm.Substring($DocsRoot.Length + 1)
        $expected = Infer-Section $rel
        if ($text -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
            $fmLines = $Matches[1] -split "`r?`n"
            $body = $Matches[2]
            $newFm = @(); $changed = $false
            foreach ($line in $fmLines) {
                if ($line -match '^section:\s*(.*)$') {
                    $val = $Matches[1].Trim().Trim([char]34)
                    if ($val -ne $expected) { $newFm += "section: `"$expected`""; $changed = $true }
                    else { $newFm += $line }
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

Write-Host "Done. Root moves: $movedCount"
