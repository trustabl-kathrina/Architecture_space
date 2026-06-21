# Organize 02.03 Data Orchestration Architecture to match 02.01.02 Streaming hierarchy.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$OrchRoot = Join-Path $DocsRoot "02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture"
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

function Write-StubReadme([string]$Path, [string]$Section, [string]$Title) {
    $body = @(
        '---',
        "title: $Title README",
        "section: `"$Section`"",
        'status: stub',
        'template: overview',
        "last_reviewed: $Today",
        'owner: architecture-team',
        'tags: [orchestration]',
        'canonical: true',
        '---',
        '',
        "# $Title",
        '',
        "Subsection index for 02.03 Data Orchestration Architecture."
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
    return "02.03"
}

# --- Phase 1: scaffold folders ---
Write-Host "Phase 1: scaffold folders"
$dirs = @(
    "$OrchRoot\02.03.01_Fundamentals\02.03.01.01_Overview",
    "$OrchRoot\02.03.01_Fundamentals\02.03.01.02_Strategy",
    "$OrchRoot\02.03.01_Fundamentals\02.03.01.03_Core_Concepts",
    "$OrchRoot\02.03.01_Fundamentals\02.03.01.04_Governance",
    "$OrchRoot\02.03.01_Fundamentals\02.03.01.05_DataOps",
    "$OrchRoot\02.03.01_Fundamentals\02.03.01.06_Active_Metadata",
    "$OrchRoot\02.03.02_Cloud_Services\02.03.02.01_Overview",
    "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering",
    "$OrchRoot\02.03.02_Cloud_Services\02.03.02.03_AWS",
    "$OrchRoot\02.03.02_Cloud_Services\02.03.02.04_Azure",
    "$OrchRoot\02.03.02_Cloud_Services\02.03.02.05_Cross_Cloud",
    "$OrchRoot\02.03.03_Open_Source\02.03.03.01_Overview",
    "$OrchRoot\02.03.03_Open_Source\02.03.03.02_Apache_Airflow",
    "$OrchRoot\02.03.03_Open_Source\02.03.03.03_Prefect",
    "$OrchRoot\02.03.03_Open_Source\02.03.03.04_Dagster",
    "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns",
    "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven",
    "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.03_Platform_Patterns",
    "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.04_AI_Assisted",
    "$OrchRoot\02.03.05_Benchmarks",
    "$OrchRoot\02.03.06_Comparisons",
    "$OrchRoot\02.03.07_Interview_Questions",
    "$OrchRoot\02.03.08_Integration_Patterns",
    "$OrchRoot\02.03.09_Reference_Architectures"
)
foreach ($d in $dirs) { Ensure-Dir $d }

Write-StubReadme "$OrchRoot\02.03.01_Fundamentals\README.md" "02.03.01" "Fundamentals"
Write-StubReadme "$OrchRoot\02.03.02_Cloud_Services\README.md" "02.03.02" "Cloud Services"
Write-StubReadme "$OrchRoot\02.03.03_Open_Source\README.md" "02.03.03" "Open Source"
Write-StubReadme "$OrchRoot\02.03.04_Architecture_Patterns\README.md" "02.03.04" "Architecture Patterns"
Write-StubReadme "$OrchRoot\02.03.05_Benchmarks\README.md" "02.03.05" "Benchmarks"
Write-StubReadme "$OrchRoot\02.03.06_Comparisons\README.md" "02.03.06" "Comparisons"
Write-StubReadme "$OrchRoot\02.03.07_Interview_Questions\README.md" "02.03.07" "Interview Questions"
Write-StubReadme "$OrchRoot\02.03.08_Integration_Patterns\README.md" "02.03.08" "Integration Patterns"
Write-StubReadme "$OrchRoot\02.03.09_Reference_Architectures\README.md" "02.03.09" "Reference Architectures"

# --- Phase 2: relocate root loose files ---
Write-Host "Phase 2: relocate root loose files"
$rootMoves = @(
    # Fundamentals
    @{ S = "Orchestration_Strategy.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.02_Strategy\02.03.01.02.01_Orchestration_Strategy.md" }
    @{ S = "Scheduling_Patterns.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.03_Core_Concepts\02.03.01.03.01_Scheduling_Patterns.md" }
    @{ S = "Dependency_Management.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.03_Core_Concepts\02.03.01.03.02_Dependency_Management.md" }
    @{ S = "Retry_Strategies.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.03_Core_Concepts\02.03.01.03.03_Retry_Strategies.md" }
    @{ S = "SLA_Management.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.03_Core_Concepts\02.03.01.03.04_SLA_Management.md" }
    @{ S = "Orchestration_Governance.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.04_Governance\02.03.01.04.01_Orchestration_Governance.md" }
    @{ S = "Platform_Governance.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.04_Governance\02.03.01.04.02_Platform_Governance.md" }
    @{ S = "DataOps_Framework.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.05_DataOps\02.03.01.05.01_DataOps_Framework.md" }
    @{ S = "DataOps_Maturity_Model.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.05_DataOps\02.03.01.05.02_DataOps_Maturity_Model.md" }
    @{ S = "Enterprise_DataOps_Playbook.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.05_DataOps\02.03.01.05.03_Enterprise_DataOps_Playbook.md" }
    @{ S = "Active_Metadata.md"; D = "$OrchRoot\02.03.01_Fundamentals\02.03.01.06_Active_Metadata\02.03.01.06.01_Active_Metadata.md" }
    # Cloud Services
    @{ S = "Managed_Workflows.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.01_Overview\02.03.02.01.01_Managed_Workflows.md" }
    @{ S = "Platform_Provisioning.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.01_Platform_Provisioning.md" }
    @{ S = "Environment_Automation.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.02_Environment_Automation.md" }
    @{ S = "Environment_Management.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.03_Environment_Management.md" }
    @{ S = "Infrastructure_As_Code.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.04_Infrastructure_As_Code.md" }
    @{ S = "Terraform_Framework.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.05_Terraform_Framework.md" }
    @{ S = "Kubernetes_For_Data.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.06_Kubernetes_For_Data.md" }
    @{ S = "Platform_Observability.md"; D = "$OrchRoot\02.03.02_Cloud_Services\02.03.02.02_Platform_Engineering\02.03.02.02.07_Platform_Observability.md" }
    # Open Source
    @{ S = "Airflow_Architecture.md"; D = "$OrchRoot\02.03.03_Open_Source\02.03.03.02_Apache_Airflow\02.03.03.02.01_Airflow_Architecture.md" }
    @{ S = "Prefect_Architecture.md"; D = "$OrchRoot\02.03.03_Open_Source\02.03.03.03_Prefect\02.03.03.03.01_Prefect_Architecture.md" }
    @{ S = "Dagster_Architecture.md"; D = "$OrchRoot\02.03.03_Open_Source\02.03.03.04_Dagster\02.03.03.04.01_Dagster_Architecture.md" }
    # Architecture Patterns — DataOps
    @{ S = "CI_CD_For_Data.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns\02.03.04.01.01_CI_CD_For_Data.md" }
    @{ S = "GitOps_For_Data.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns\02.03.04.01.02_GitOps_For_Data.md" }
    @{ S = "Data_Deployment_Strategy.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns\02.03.04.01.03_Data_Deployment_Strategy.md" }
    @{ S = "Data_Release_Management.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns\02.03.04.01.04_Data_Release_Management.md" }
    @{ S = "Data_Testing_Strategy.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns\02.03.04.01.05_Data_Testing_Strategy.md" }
    @{ S = "Automated_Validation.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.01_DataOps_Patterns\02.03.04.01.06_Automated_Validation.md" }
    # Architecture Patterns — Metadata Driven
    @{ S = "Metadata_Driven_Framework.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.01_Metadata_Driven_Framework.md" }
    @{ S = "Metadata_Driven_ETL.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.02_Metadata_Driven_ETL.md" }
    @{ S = "Metadata_Driven_Transformations.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.03_Metadata_Driven_Transformations.md" }
    @{ S = "Configuration_Driven_Processing.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.04_Configuration_Driven_Processing.md" }
    @{ S = "Dynamic_Pipeline_Generation.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.05_Dynamic_Pipeline_Generation.md" }
    @{ S = "Metadata_Automation.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.06_Metadata_Automation.md" }
    @{ S = "Metadata_Orchestration.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.02_Metadata_Driven\02.03.04.02.07_Metadata_Orchestration.md" }
    # Architecture Patterns — Platform
    @{ S = "Internal_Developer_Platform.md"; D = "$OrchRoot\02.03.04_Architecture_Patterns\02.03.04.03_Platform_Patterns\02.03.04.03.01_Internal_Developer_Platform.md" }
    @{ S = "Self_Service_Platform.md"; D = "$OrchRoot\02.03.08_Integration_Patterns\02.03.08.01_Self_Service_Platform.md" }
    @{ S = "Self_Service_Engineering.md"; D = "$OrchRoot\02.03.08_Integration_Patterns\02.03.08.02_Self_Service_Engineering.md" }
    # Reference Architectures
    @{ S = "Metadata_Reference_Architecture.md"; D = "$OrchRoot\02.03.09_Reference_Architectures\02.03.09.01_Metadata_Reference_Architecture.md" }
)

$movedCount = 0
foreach ($m in $rootMoves) {
    $src = Join-Path $OrchRoot $m.S
    if (Move-FileMapped $src $m.D) { $movedCount++ }
}

# AI Assisted folder
Write-Host "Phase 3: relocate AI_Assisted_Data_Engineering"
$aiMap = @(
    @{ S = "AI_Data_Engineering_Overview.md"; N = "02.03.04.04.01_AI_Data_Engineering_Overview.md" }
    @{ S = "Agentic_Data_Engineering.md"; N = "02.03.04.04.02_Agentic_Data_Engineering.md" }
    @{ S = "AI_Code_Generation.md"; N = "02.03.04.04.03_AI_Code_Generation.md" }
    @{ S = "AI_Data_Mapping.md"; N = "02.03.04.04.04_AI_Data_Mapping.md" }
    @{ S = "AI_Data_Quality.md"; N = "02.03.04.04.05_AI_Data_Quality.md" }
    @{ S = "AI_Lineage_Generation.md"; N = "02.03.04.04.06_AI_Lineage_Generation.md" }
    @{ S = "AI_Metadata_Management.md"; N = "02.03.04.04.07_AI_Metadata_Management.md" }
    @{ S = "AI_Pipeline_Generation.md"; N = "02.03.04.04.08_AI_Pipeline_Generation.md" }
    @{ S = "AI_Test_Generation.md"; N = "02.03.04.04.09_AI_Test_Generation.md" }
    @{ S = "Autonomous_Data_Platforms.md"; N = "02.03.04.04.10_Autonomous_Data_Platforms.md" }
)
$aiSrcDir = Join-Path $OrchRoot "AI_Assisted_Data_Engineering"
$aiDstDir = Join-Path $OrchRoot "02.03.04_Architecture_Patterns\02.03.04.04_AI_Assisted"
foreach ($item in $aiMap) {
    $src = Join-Path $aiSrcDir $item.S
    $dst = Join-Path $aiDstDir $item.N
    if (Move-FileMapped $src $dst) { $movedCount++ }
}
if (Test-Path $aiSrcDir) {
    $remaining = Get-ChildItem $aiSrcDir -Recurse -Force -ErrorAction SilentlyContinue
    if ($remaining.Count -eq 0) {
        if (-not $DryRun) { Remove-Item $aiSrcDir -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "  removed empty: AI_Assisted_Data_Engineering"
    }
}

# --- Phase 4: global link updates ---
Write-Host "Phase 4: global link updates"
$linkReplacements = @()
foreach ($m in $rootMoves) {
    $oldRel = "02.03_Data_Orchestration_Architecture/$($m.S)"
    $newRel = "02.03_Data_Orchestration_Architecture/" + ($m.D.Substring($OrchRoot.Length + 1) -replace '\\', '/')
    $linkReplacements += @{ O = $oldRel; N = $newRel }
}
foreach ($item in $aiMap) {
    $linkReplacements += @{
        O = "02.03_Data_Orchestration_Architecture/AI_Assisted_Data_Engineering/$($item.S)"
        N = "02.03_Data_Orchestration_Architecture/02.03.04_Architecture_Patterns/02.03.04.04_AI_Assisted/$($item.N)"
    }
}

$globalFixed = 0
Get-ChildItem $RepoRoot -Recurse -Include *.md,*.yaml,*.yml -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.FullName -match '\\(\.git|site|node_modules)\\') { return }
    if ($_.Name -eq 'organize_02_03_orchestration.ps1') { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    $updated = $text
    foreach ($r in $linkReplacements) { $updated = $updated.Replace($r.O, $r.N) }
    if ($updated -ne $text) {
        if (-not $DryRun) { [IO.File]::WriteAllText((To-LongPath $_.FullName), $updated, [Text.UTF8Encoding]::new($false)) }
        $globalFixed++
    }
}
Write-Host "  updated $globalFixed files repo-wide"

# --- Phase 5: fix front matter section under moved tree ---
Write-Host "Phase 5: fix front matter"
$fmFixed = 0
if (Test-Path $OrchRoot) {
    foreach ($filePath in [System.IO.Directory]::EnumerateFiles((To-LongPath $OrchRoot), '*.md', 'AllDirectories')) {
        $norm = $filePath -replace '^\\\\\?\\', ''
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
