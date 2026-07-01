# Generate section README files and master docs index
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"

$SectionDescriptions = @{
    "01_Enterprise_Strategy_And_Operating_Model" = "Enterprise vision, strategy, operating models, governance, and transformation foundations."
    "02_Enterprise_Architecture" = "Enterprise architecture frameworks, capability models, target state, and architecture governance."
    "03_Data_Architecture" = "Enterprise data architecture, domain modeling, mesh/fabric patterns, and data platform design."
    "04_Data_Engineering" = "Data ingestion, pipelines, streaming, DataOps, and data product engineering practices."
    "05_Analytics_Architecture" = "BI, reporting, semantic layers, self-service analytics, and decision intelligence."
    "06_AI_Architecture" = "Enterprise AI frameworks, MLOps, generative AI, model lifecycle, and AI governance."
    "07_Agentic_AI_Architecture" = "Agent design patterns, orchestration, AgentOps, digital workforce, and multi-agent systems."
    "08_Governance_And_Metadata" = "Data, AI, and agent governance; metadata strategy; catalogs; lineage; and compliance."
    "09_Data_Mesh_And_Domain_Architecture" = "Domain-driven data mesh, data products, federated governance, and mesh operating models."
    "10_Lakehouse_And_Modern_Data_Platforms" = "Lakehouse, medallion, open table formats, and modern data platform engineering."
    "11_Integration_Architecture" = "API, event-driven, data, and application integration patterns and platforms."
    "12_Real_Time_And_Event_Driven_Architecture" = "Event streaming, CQRS, event sourcing, real-time analytics, and EventOps."
    "13_MDM_And_Reference_Data" = "Master data management, golden records, reference data, and MDM platforms."
    "14_Security_And_Privacy" = "Enterprise security, zero trust, data privacy, AI/agent security, and compliance."
    "15_Data_Quality_And_Observability" = "Data quality frameworks, observability, data contracts, and reliability engineering."
    "16_Cloud_Architecture" = "Cloud strategy, hybrid/multi-cloud, Kubernetes, serverless, and cloud FinOps."
    "17_Platform_Engineering" = "Internal developer platforms, golden paths, platform product management, and DevEx."
    "18_FinOps_And_Cost_Optimization" = "FinOps operating model, cost allocation, chargeback/showback, and workload optimization."
    "19_Enterprise_Automation" = "Process automation, hyperautomation, intelligent document processing, and agentic automation."
    "20_Industry_Specific_Patterns" = "Industry reference architectures, capability models, and vertical data/AI patterns."
    "21_Architecture_Decision_Frameworks" = "Architecture decision records, technology selection, and decision governance."
    "22_POCs_And_Benchmarking" = "Proof-of-concept results, benchmarks, and hands-on architecture evaluations."
    "23_Transformation_Roadmaps" = "Enterprise transformation roadmaps, gap assessments, and value realization."
    "24_Vendor_Evaluation_Frameworks" = "Vendor evaluation frameworks, RFP management, and technology benchmarking."
    "25_Future_Trends_And_Emerging_Architecture" = "Technology radar, future enterprise architecture, and emerging AI/agent trends."
}

function Get-FrontMatterStatus([string]$Path) {
    $text = Get-Content -Path $Path -Raw -Encoding UTF8
    if ($text -match '(?m)^status:\s*(\w+)') { return $Matches[1] }
    return 'stub'
}

function Get-StatusCounts([string]$Dir) {
    $counts = @{ complete = 0; draft = 0; review = 0; stub = 0 }
    Get-ChildItem -Path $Dir -Recurse -Filter "*.md" | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
        $s = Get-FrontMatterStatus $_.FullName
        if ($counts.ContainsKey($s)) { $counts[$s]++ } else { $counts.stub++ }
    }
    return $counts
}

function Get-SubsectionLabel([string]$Name) {
    if ($Name -match '^\d{2}\.\d{2}_(.+)$') { return ($Matches[1] -replace '_', ' ') }
    return ($Name -replace '_', ' ')
}

Get-ChildItem -Path $DocsRoot -Directory | Where-Object { $_.Name -match '^\d{2}_' } | Sort-Object Name | ForEach-Object {
    $section = $_
    $num = $section.Name.Split('_')[0]
    $title = ($section.Name -replace '^\d{2}_', '') -replace '_', ' '
    $desc = $SectionDescriptions[$section.Name]
    if (-not $desc) { $desc = "Enterprise architecture documentation." }

    $counts = Get-StatusCounts $section.FullName
    $total = ($counts.Values | Measure-Object -Sum).Sum

    $lines = @(
        "# $num $title",
        "",
        "> Status: $($counts.complete) complete / $($counts.draft) draft / $($counts.review) review / $($counts.stub) stub ($total topics)",
        "",
        "## Purpose",
        "",
        $desc,
        "",
        "## Start here",
        ""
    )

    $overview = Get-ChildItem -Path $section.FullName -Directory | Where-Object { $_.Name -like '*_Overview' } | Select-Object -First 1
    if ($overview) {
        Get-ChildItem -Path $overview.FullName -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'README.md' } | Select-Object -First 4 | ForEach-Object {
            $rel = $_.FullName.Substring($section.FullName.Length + 1) -replace '\\', '/'
            $docTitle = $_.BaseName -replace '_', ' '
            $lines += "- [$docTitle]($rel)"
        }
    } else {
        $lines += "- Browse subsections below."
    }

    $lines += @("", "## Subsections", "", "| # | Topic | Topics | Key doc | Status |", "| --- | --- | ---: | --- | --- |")

    Get-ChildItem -Path $section.FullName -Directory | Sort-Object Name | ForEach-Object {
        $sub = $_
        $subFiles = Get-ChildItem -Path $sub.FullName -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'README.md' }
        if ($subFiles.Count -eq 0) { return }
        $key = $subFiles | Sort-Object FullName | Select-Object -First 1
        $keyRel = $key.FullName.Substring($section.FullName.Length + 1) -replace '\\', '/'
        $keyStatus = Get-FrontMatterStatus $key.FullName
        $subId = $sub.Name.Split('_')[0]
        $lines += "| $subId | $(Get-SubsectionLabel $sub.Name) | $($subFiles.Count) | [$($key.BaseName -replace '_', ' ')]($keyRel) | $keyStatus |"
    }

    $lines += @("", "## Related", "", "- [Architecture Space README](../README.md)", "- [Contributing](../CONTRIBUTING.md)", "- [Repository README](../../README.md)", "")
    [IO.File]::WriteAllText((Join-Path $section.FullName 'README.md'), ($lines -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
    Write-Host "Wrote $($section.Name)/README.md"
}

# Master index
$master = @("# Architecture Space", "", "Master index of all 21 architecture sections.", "", "| # | Section | Topics | Description |", "| --- | --- | ---: | --- |")
$grand = 0
Get-ChildItem -Path $DocsRoot -Directory | Where-Object { $_.Name -match '^\d{2}_' } | Sort-Object Name | ForEach-Object {
    $section = $_
    $num = $section.Name.Split('_')[0]
    $title = ($section.Name -replace '^\d{2}_', '') -replace '_', ' '
    $count = (Get-ChildItem -Path $section.FullName -Recurse -Filter "*.md" | Where-Object { $_.Name -ne 'README.md' }).Count
    $grand += $count
    $desc = $SectionDescriptions[$section.Name]
    $master += "| $num | [$title]($($section.Name)/README.md) | $count | $desc |"
}
$master += @("", "**Total topics:** $grand", "", "## Cross-cutting hubs", "", "- [Data Mesh Hub](_hubs/Data_Mesh_Hub.md)", "- [FinOps Hub](_hubs/FinOps_Hub.md)", "- [Agentic AI Hub](_hubs/Agentic_AI_Hub.md)", "- [Pluto MIND Hub](_hubs/Pluto_MIND_Hub.md)", "", "## POCs and benchmarks", "", "Completed evaluations live in [18_POCs_And_Benchmarks](18_POCs_And_Benchmarks/README.md).", "")
[IO.File]::WriteAllText((Join-Path $DocsRoot 'README.md'), ($master -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
Write-Host "Wrote docs/README.md"
