# PowerShell runner for enhance_top10_oss_modules.py (parses block content from the .py source)
$ErrorActionPreference = "Stop"
$Repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$Base = Join-Path $Repo "docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture\02.03.03_Top_10"
$PySource = Join-Path $PSScriptRoot "enhance_top10_oss_modules.py"
$utf8 = New-Object System.Text.UTF8Encoding $false
$Marker = "## Related"

function Get-PyGuideBlocks([string]$Content, [string]$Name) {
    $pattern = "(?ms)^$([regex]::Escape($Name)) = \{(.*?)^\}"
    if ($Content -notmatch $pattern) { return @{} }
    $blocks = @{}
    foreach ($m in [regex]::Matches($Matches[1], '"(\d{2})":\s*"""(.*?)"""', 'Singleline')) {
        $blocks[$m.Groups[1].Value] = $m.Groups[2].Value.Trim()
    }
    return $blocks
}

function Insert-BeforeRelated([string]$Path, [string]$Block) {
    if (-not [IO.File]::Exists($Path)) { return $false }
    $text = [IO.File]::ReadAllText($Path, $utf8)
    if ($text.Contains($Block.Trim())) { return $false }
    if ($text -notmatch [regex]::Escape($Marker)) {
        $text = $text.TrimEnd() + "`n`n" + $Block.Trim() + "`n"
    } else {
        $idx = $text.IndexOf($Marker)
        $text = $text.Substring(0, $idx) + $Block.Trim() + "`n`n" + $text.Substring($idx)
    }
    [IO.File]::WriteAllText($Path, $text, $utf8)
    return $true
}

$py = [IO.File]::ReadAllText($PySource, $utf8)
# Top 10 slot map: .05 Temporal, .06 Argo — .10 Metaflow, .11 Mage (not Temporal/Argo)
$Specs = @(
    @{ Folder = "02.03.03.02_Apache_Airflow_Learning_Guide"; Var = "AIRFLOW" },
    @{ Folder = "02.03.03.03_Prefect_Learning_Guide"; Var = "PREFECT" },
    @{ Folder = "02.03.03.04_Dagster_Learning_Guide"; Var = "DAGSTER" },
    @{ Folder = "02.03.03.05_Temporal_Learning_Guide"; Var = "TEMPORAL" },
    @{ Folder = "02.03.03.06_Argo_Workflows_Learning_Guide"; Var = "ARGO" }
)
$Suffix = @{
    "01" = "01_Overview.md"; "02" = "02_Architecture.md"; "03" = "03_How_To_Use.md"
    "04" = "04_Scenarios.md"; "05" = "05_Limitations_And_Scenarios.md"; "06" = "06_Costing.md"
    "07" = "07_Production_Configuration.md"; "08" = "08_Evaluation_Criteria.md"; "09" = "09_Benchmarking.md"
}

$updated = 0
$skipped = 0
foreach ($spec in $Specs) {
    $blocks = Get-PyGuideBlocks $py $spec.Var
    $sec = ($spec.Folder -split "_")[0]
    foreach ($num in $blocks.Keys | Sort-Object) {
        $mod = ($Suffix[$num] -split "_", 2)[1] -replace "\.md$", ""
        $fname = "$sec.$num`_$mod.md"
        $path = Join-Path (Join-Path $Base $spec.Folder) $fname
        if (-not [IO.File]::Exists($path)) {
            Write-Error "Missing guide module (check SPECS folder IDs): $path"
            $skipped++
            continue
        }
        if (Insert-BeforeRelated $path $blocks[$num]) { $updated++ }
    }
}
Write-Host "Enhanced $updated module files ($skipped skipped)"
if ($skipped -gt 0) { exit 1 }
