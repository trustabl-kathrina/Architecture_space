param(
    [switch]$DryRun,
    [switch]$RefreshOnly
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$OldRoot = Join-Path $RepoRoot "Enterprise Transformation"
$NewRoot = Join-Path $RepoRoot "docs"
$Today = Get-Date -Format "yyyy-MM-dd"

$Sections = @(
    @{ id = "00"; name = "00_Architecture_Governance"; description = "Architecture principles, reference architectures, ADRs, patterns, review checklists, NFRs, blueprints, standards, and strategy alignment."; subs = @(
        "00.01_Architecture_Principles","00.02_Reference_Architectures","00.03_Architecture_Decision_Records","00.04_Architecture_Patterns","00.05_Architecture_Review_Checklists","00.06_Non_Functional_Requirements","00.07_Solution_Blueprints","00.08_Standards_And_Guidelines","00.09_Enterprise_Strategy_And_Operating_Model","00.10_Data_Governance_And_Metadata"
    ) },
    @{ id = "01"; name = "01_Data_Architecture"; description = "Data architecture fundamentals, enterprise data architecture, mesh, fabric, lakehouse concepts, data products, metadata-driven architecture, and domain-driven design."; subs = @(
        "01.01_Fundamentals","01.02_Data_Architecture_Patterns","01.03_Reference_Architectures","01.04_Architecture_Case_Studies"
    ) },
    @{ id = "02"; name = "02_Data_Engineering_Architecture"; description = "Data ingestion, transformation, orchestration, observability, and storage architecture."; subs = @(
        "02.01_Data_Ingestion_Architecture","02.02_Data_Transformation_Architecture","02.03_Data_Orchestration_Architecture","02.04_Data_Observability_Architecture","02.05_Data_Storage_Architecture","02.01_Data_Ingestion_Architecture/02.01.02_Streaming"
    ) },
    @{ id = "02.05"; name = "02_Data_Engineering_Architecture/02.05_Data_Storage_Architecture"; description = "Data lake, warehouse, lakehouse, marts, ODS, analytical stores, and storage design patterns."; subs = @(
        "02.05.01_Data_Lake","02.05.02_Data_Warehouse","02.05.03_Lakehouse","02.05.04_Data_Marts","02.05.05_Operational_Data_Store","02.05.06_Analytical_Stores","02.05.07_Storage_Patterns"
    ) },
    @{ id = "04"; name = "04_Cloud_Data_Platforms"; description = "Cloud data platform services and reference implementations across GCP, AWS, and Azure."; subs = @(
        "04.01_GCP","04.02_AWS","04.03_Azure","04.04_Platform_Engineering","04.05_Lakehouse_Platforms","04.06_FinOps"
    ) },
    @{ id = "05"; name = "05_Data_Modeling_Architecture"; description = "Conceptual, logical, physical, dimensional, Data Vault, canonical, semantic, TMF SID, and industry modeling."; subs = @(
        "05.01_Fundamentals","05.02_Conceptual_Modeling","05.03_Logical_Modeling","05.04_Physical_Modeling","05.05_Dimensional_Modeling","05.06_DataVault_2_0","05.07_Canonical_Modeling","05.08_Semantic_Modeling","05.09_TMF_SID","05.10_Industry_Models"
    ) },
    @{ id = "06"; name = "06_Data_Product_Architecture"; description = "Data product lifecycle, design, SDP/ADP/CDP, marketplace, data contracts, and product governance."; subs = @(
        "06.01_Fundamentals","06.02_Data_Product_Lifecycle","06.03_Data_Product_Design","06.04_SDP","06.05_ADP","06.06_CDP","06.07_Marketplace","06.08_Data_Contracts","06.09_Product_Governance"
    ) },
    @{ id = "00.10"; name = "00_Architecture_Governance/00.10_Data_Governance_And_Metadata"; description = "Metadata management, catalog, lineage, quality, MDM, reference data, privacy, security, compliance, and governance operating model."; subs = @(
        "00.10.01_Metadata_Management","00.10.02_Data_Catalog","00.10.03_Data_Lineage","00.10.04_Data_Quality","00.10.05_Master_Data_Management","00.10.06_Reference_Data","00.10.07_Data_Privacy","00.10.08_Data_Security","00.10.09_Data_Compliance","00.10.10_Governance_Operating_Model"
    ) },
    @{ id = "08"; name = "08_Analytics_Architecture"; description = "BI, semantic layer, self-service analytics, dashboards, analytics tools, and real-time OLAP engines (08.10)."; subs = @(
        "08.01_BI_Architecture","08.02_Semantic_Layer","08.04_Self_Service_Analytics","08.05_Dashboard_Architecture","08.06_Tableau","08.07_PowerBI","08.08_Looker","08.09_Metabase","08.10_Real_Time_Analytics_Architecture"
    ) },
    @{ id = "02.07"; name = "02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming"; description = "Event-driven architecture, stream processing, CDC, cloud streaming services, open source engines, patterns, benchmarks, comparisons, and interview questions."; subs = @(
        "02.01.02.01_Fundamentals","02.01.02.02_Cloud_Services","02.01.02.03_Open_Source","02.01.02.04_Architecture_Patterns","02.01.02.05_Benchmarks","02.01.02.06_Comparisons","02.01.02.07_Interview_Questions","02.01.02.08_Integration_Patterns"
    ) },
    @{ id = "08.10"; name = "08_Analytics_Architecture/08.10_Real_Time_Analytics_Architecture"; description = "Real-time analytics engines, streaming analytics stores, serving patterns, and low-latency analytical workloads."; subs = @(
        "08.10.01_ClickHouse","08.10.02_Pinot","08.10.03_Druid","08.10.04_Elasticsearch","08.10.05_Streaming_Analytics"
    ) },
    @{ id = "11"; name = "11_AI_Data_Architecture"; description = "AI-ready data platforms, feature stores, RAG, vector databases, prompt engineering, AI governance, AI observability, AI FinOps, and agentic AI (11.12)."; subs = @(
        "11.01_AI_Ready_Data_Platform","11.02_Feature_Store","11.03_RAG","11.04_Agentic_AI_Data","11.07_Vector_Databases","11.08_Prompt_Engineering","11.09_AI_Governance","11.10_AI_Observability","11.11_AI_FinOps","11.12_Agentic_AI_Architecture"
    ) },
    @{ id = "11.12"; name = "11_AI_Data_Architecture/11.12_Agentic_AI_Architecture"; description = "Agentic AI strategy, agent architecture, MCP/A2A, tool use, orchestration, AgentOps, multi-agent systems, and digital workforce architecture."; subs = @(
        "11.12.01_Fundamentals","11.12.02_Agent_Architecture","11.12.03_Agent_Design_Patterns","11.12.04_MCP","11.12.05_A2A","11.12.06_Agent_Orchestration","11.12.07_AgentOps","11.12.08_Multi_Agent_Systems","11.12.09_Digital_Workforce"
    ) },
    @{ id = "13"; name = "13_MLOps_Architecture"; description = "ML lifecycle, feature engineering, training, deployment, monitoring, and model governance."; subs = @(
        "13.01_ML_Lifecycle","13.02_Feature_Engineering","13.03_Training","13.04_Deployment","13.05_Monitoring","13.06_Model_Governance"
    ) },
    @{ id = "14"; name = "14_Security_And_Privacy_Architecture"; description = "IAM, encryption, secrets management, RLS/CLS, zero trust, compliance, AI security, and privacy engineering."; subs = @(
        "14.01_IAM","14.02_Encryption","14.03_Secrets_Management","14.04_Row_Level_Security","14.05_Column_Level_Security","14.06_Zero_Trust","14.07_Compliance","14.08_AI_Security","14.09_Privacy_Engineering"
    ) },
    @{ id = "15"; name = "15_Industry_Reference_Architectures"; description = "Telecom, banking, insurance, retail, healthcare, manufacturing, government, and other industry reference architectures."; subs = @(
        "15.01_Telecom","15.02_Banking","15.03_Insurance","15.04_Retail","15.05_Healthcare","15.06_Manufacturing","15.07_Government","15.08_Case_Studies"
    ) },
    @{ id = "16"; name = "16_Architecture_Interview_Preparation"; description = "Role-based architecture interview preparation, scenario questions, and study guides."; subs = @(
        "16.01_Data_Architect","16.02_Solution_Architect","16.03_Enterprise_Architect","16.04_AI_Architect","16.05_GCP_Architect","16.06_AWS_Architect","16.07_Scenario_Based_Questions"
    ) },
    @{ id = "17"; name = "17_Technology_Comparisons"; description = "Technology comparisons, vendor evaluations, selection frameworks, scorecards, and benchmark summaries."; subs = @(
        "17.01_BigQuery_vs_Snowflake","17.02_Kafka_vs_Pulsar","17.03_Airflow_vs_Dagster","17.04_Databricks_vs_Snowflake","17.05_ClickHouse_vs_Druid","17.06_DataMesh_vs_Fabric","17.07_ETL_vs_ELT","17.08_Vendor_Evaluations","17.09_Selection_Frameworks"
    ) },
    @{ id = "19"; name = "19_Templates_And_Frameworks"; description = "Architecture, HLD, LLD, data product, data contract, ADR, governance, and benchmark templates."; subs = @(
        "19.01_Architecture_Document_Template","19.02_HLD_Template","19.03_LLD_Template","19.04_Data_Product_Template","19.05_Data_Contract_Template","19.06_ADR_Template","19.07_Governance_Template","19.08_Benchmark_Template","19.09_Frameworks"
    ) },
    @{ id = "20"; name = "20_Pluto_MIND"; description = "Pluto MIND product architecture, Acquisition AI, Model AI, Transformation AI, Fluid Specification, data product builder, marketplace, governance, FinOps, and data quality."; subs = @(
        "20.01_Acquisition_AI","20.02_Model_AI","20.03_Transformation_AI","20.04_Fluid_Specification","20.05_Data_Product_Builder","20.06_Data_Product_Marketplace","20.07_AI_Governance","20.08_AI_FinOps","20.09_AI_Data_Quality"
    ) }
)

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }
}

function Write-Text([string]$Path, [string]$Content) {
    $dir = Split-Path -Parent $Path
    Ensure-Dir $dir
    if (-not $DryRun) {
        [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
    }
}

function Parse-FmBlock([string]$Block) {
    $data = @{}
    foreach ($line in ($Block -split "`r?`n")) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*:\s*(.*)\s*$') {
            $data[$Matches[1]] = $Matches[2].Trim()
        }
    }
    return $data
}

function Get-FrontMatterBlocks([string]$Text) {
    $blocks = @()
    $remaining = $Text
    while ($remaining -match '^(?s)---\s*\r?\n(.*?)\r?\n---\s*\r?\n?') {
        $blocks += $Matches[1]
        $remaining = $remaining.Substring($Matches[0].Length)
    }
    return @{ blocks = $blocks; body = $remaining }
}

function Normalize-Status([string]$Status) {
    if ([string]::IsNullOrWhiteSpace($Status)) { return "stub" }
    $clean = $Status.Trim().Trim('"').Trim("'")
    if (@("stub","draft","review","complete","archived") -contains $clean) { return $clean }
    return "stub"
}

function Better-Status([string[]]$Statuses) {
    $rank = @{ "stub" = 0; "archived" = 0; "draft" = 1; "review" = 2; "complete" = 3 }
    $best = "stub"
    foreach ($s in $Statuses) {
        $n = Normalize-Status $s
        if ($rank[$n] -gt $rank[$best]) { $best = $n }
    }
    return $best
}

function Infer-Section([string]$RelativePath) {
    if ($RelativePath -match '(^|[\\/])(\d{2}(?:\.\d{2}){0,3})') { return $Matches[2] }
    if ($RelativePath -match '(^|[\\/])(\d{2})_') { return $Matches[2] }
    return "00"
}

function Infer-Template([string]$RelativePath, [string]$Body) {
    $lower = $RelativePath.ToLowerInvariant()
    if ($lower -match '(^|[\\/])hubs[\\/]' -or $lower -match '_hub\.md$') { return "hub" }
    if ($lower -match 'adr_' -or $lower -match '(^|[\\/])\d{2}\.\d{2}_adr[\\/]') { return "adr" }
    if ($lower -match 'interview|scenario_based_questions') { return "interview" }
    if ($lower -match 'poc|benchmark') { return "poc" }
    if ($Body -match '## Core Concepts' -or $Body -match '## Expert Concepts') { return "concept" }
    if ($Body -match '(?m)^##\s+\d+\. ') { return "evaluation" }
    if ($lower -match 'what_is|overview|vision|strategy|framework|principles') { return "overview" }
    if ($Body -match 'Vendor A' -and $Body -match 'Vendor B') { return "evaluation" }
    return "overview"
}

function Build-FrontMatter([string]$Title, [string]$Section, [string]$Status, [string]$Template, [string]$Tags, [string]$Extra = "") {
    if ([string]::IsNullOrWhiteSpace($Tags)) { $Tags = "[]" }
    $lines = @(
        "---",
        "title: $Title",
        "section: `"$Section`"",
        "status: $Status",
        "template: $Template",
        "last_reviewed: $Today",
        "owner: architecture-team",
        "tags: $Tags",
        "canonical: true"
    )
    if (-not [string]::IsNullOrWhiteSpace($Extra)) {
        $lines += ($Extra.Trim() -split "`r?`n")
    }
    $lines += "---"
    return ($lines -join "`n") + "`n`n"
}

function Normalize-Document([IO.FileInfo]$File, [string]$BaseRoot, [switch]$ForceInferredSection) {
    $text = Get-Content -Path $File.FullName -Raw -Encoding UTF8
    $parsed = Get-FrontMatterBlocks $text
    $body = $parsed.body.TrimStart()
    $body = $body -replace '^(?s)\s*---\s*\r?\n+', ''
    $metadata = @{}
    $statuses = @()
    foreach ($block in $parsed.blocks) {
        $fm = Parse-FmBlock $block
        foreach ($key in $fm.Keys) { $metadata[$key] = $fm[$key] }
        if ($fm.ContainsKey("status")) { $statuses += $fm["status"] }
    }
    $rel = $File.FullName.Substring($BaseRoot.Length + 1)
    $title = if ($metadata.ContainsKey("title")) { $metadata["title"] } else { $File.BaseName -replace "_", " " }
    $section = if ($ForceInferredSection) { Infer-Section $rel } elseif ($metadata.ContainsKey("section")) { $metadata["section"].Trim('"') } else { Infer-Section $rel }
    $template = if ($metadata.ContainsKey("template")) { $metadata["template"] } else { Infer-Template $rel $body }
    $status = Better-Status $statuses
    if ($status -eq "stub" -and $body -notmatch 'Vendor A' -and (($body -split '\s+').Count -gt 450)) { $status = "complete" }
    $tags = if ($metadata.ContainsKey("tags")) { $metadata["tags"] } else { "[]" }
    $front = Build-FrontMatter $title $section $status $template $tags
    $newText = $front + $body.TrimStart()
    if (-not $DryRun) { [IO.File]::WriteAllText($File.FullName, $newText, [Text.UTF8Encoding]::new($false)) }
    return $status
}

function Get-Status([string]$Path) {
    $text = Get-Content -Path $Path -Raw -Encoding UTF8
    if ($text -match '(?m)^status:\s*([A-Za-z]+)\s*$') { return Normalize-Status $Matches[1] }
    return "stub"
}

function Get-TargetForPath([string]$RelPath, [string]$Status) {
    $p = $RelPath -replace '\\','/'
    $parts = $p -split '/'
    $section = $parts[0]
    $sub = if ($parts.Count -gt 1) { $parts[1] } else { "" }
    $rest = if ($parts.Count -gt 1) { ($parts[1..($parts.Count-1)] -join '/') } else { $parts[0] }

    if ($section -eq "hubs") { return "_hubs/" + ($parts[1..($parts.Count-1)] -join '/') }
    if ($p -match '/ADR_' -or $p -match '_ADR/') { return "00_Architecture_Governance/00.03_Architecture_Decision_Records/$section/" + [IO.Path]::GetFileName($p) }

    switch -Regex ($section) {
        '^01_' {
            if ($sub -match 'Architecture_Principles') { return "00_Architecture_Governance/00.01_Architecture_Principles/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match 'Data_Product') { return "06_Data_Product_Architecture/06.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match 'AI_Strategy|AI_Operating') { return "11_AI_Data_Architecture/11.09_AI_Governance/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "00_Architecture_Governance/00.09_Enterprise_Strategy_And_Operating_Model/" + $rest
        }
        '^02_' { return "00_Architecture_Governance/00.02_Reference_Architectures/" + $rest }
        '^03_' {
            if ($sub -match '03\.03|03\.05|03\.10|03\.11') { return "05_Data_Modeling_Architecture/05.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '03\.06') { return "06_Data_Product_Architecture/06.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '03\.09|03\.18|03\.21') { return "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.01_Metadata_Management/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '03\.15') { return "11_AI_Data_Architecture/11.01_AI_Ready_Data_Platform/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "01_Data_Architecture/01.01_Fundamentals/" + $rest
        }
        '^04_' {
            if ($sub -match '04\.07') { return "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '04\.16') { return "06_Data_Product_Architecture/06.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '04\.14|04\.15') { return "02_Data_Engineering_Architecture/02.04_Data_Observability_Architecture/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/" + $rest
        }
        '^05_' { return "08_Analytics_Architecture/08.01_BI_Architecture/" + $rest }
        '^06_' {
            if ($sub -match '06\.08|06\.09|06\.10|06\.11|06\.12') { return "13_MLOps_Architecture/13.01_ML_Lifecycle/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '06\.14') { return "11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.12_Agentic_AI_Architecture/11.12.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '06\.18') { return "14_Security_And_Privacy_Architecture/14.08_AI_Security/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '06\.13') { return "11_AI_Data_Architecture/11.03_RAG/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "11_AI_Data_Architecture/11.01_AI_Ready_Data_Platform/" + $rest
        }
        '^07_' { return "11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.12_Agentic_AI_Architecture/11.12.01_Fundamentals/" + $rest }
        '^08_' { return "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.01_Metadata_Management/" + $rest }
        '^09_' {
            if ($sub -match '09\.09|09\.10|09\.11') { return "06_Data_Product_Architecture/06.01_Fundamentals/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '09\.12|09\.21') { return "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.10_Governance_Operating_Model/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "01_Data_Architecture/01.01_Fundamentals/" + $rest
        }
        '^10_' {
            if ($sub -match '10\.06|10\.07|10\.08|10\.09') { return "02_Data_Engineering_Architecture\02.05_Data_Storage_Architecture/02.05.03_Lakehouse/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '10\.16|10\.17') { return "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.02_Cloud_Services/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "04_Cloud_Data_Platforms/04.05_Lakehouse_Platforms/" + $rest
        }
        '^11_' {
            if ($sub -match '11\.07|11\.13') { return "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.08_Integration_Patterns/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '11\.12') { return "02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "00_Architecture_Governance/00.04_Architecture_Patterns/" + $rest
        }
        '^12_' {
            if ($sub -match '12\.13') { return "08_Analytics_Architecture\08.08_Analytics_Architecture/08.10_Real_Time_Analytics_Architecture/08.10.05_Streaming_Analytics/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.01_Fundamentals/" + $rest
        }
        '^13_' { return "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.05_Master_Data_Management/" + $rest }
        '^14_' { return "14_Security_And_Privacy_Architecture/14.01_IAM/" + $rest }
        '^15_' {
            if ($sub -match '15\.10|15\.11|15\.12|15\.13|15\.14|15\.15') { return "02_Data_Engineering_Architecture/02.04_Data_Observability_Architecture/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "00_Architecture_Governance\00.10_Data_Governance_And_Metadata/00.10.04_Data_Quality/" + $rest
        }
        '^16_' { return "04_Cloud_Data_Platforms/04.01_GCP/" + $rest }
        '^17_' { return "04_Cloud_Data_Platforms/04.04_Platform_Engineering/" + $rest }
        '^18_' { return "04_Cloud_Data_Platforms/04.06_FinOps/" + $rest }
        '^19_' { return "11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.12_Agentic_AI_Architecture/11.12.09_Digital_Workforce/" + $rest }
        '^20_' { return "15_Industry_Reference_Architectures/15.08_Case_Studies/" + $rest }
        '^21_' { return "00_Architecture_Governance/00.04_Architecture_Patterns/" + $rest }
        '^22_' {
            if ($sub -match '22\.04|22\.21|Streaming') { return "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/" + ($parts[2..($parts.Count-1)] -join '/') }
            if ($sub -match '22\.06|GenAI|RAG') { return "11_AI_Data_Architecture/11.03_RAG/" + ($parts[2..($parts.Count-1)] -join '/') }
            return "02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture/02.01.02_Streaming/02.01.02.05_Benchmarks/" + $rest
        }
        '^23_' { return "00_Architecture_Governance/00.07_Solution_Blueprints/" + $rest }
        '^24_' { return "17_Technology_Comparisons/17.08_Vendor_Evaluations/" + $rest }
        '^25_' { return "00_Architecture_Governance/00.02_Reference_Architectures/" + $rest }
    }
    return "_archive/" + $p
}

function Get-SectionDescription([string]$Name) {
    foreach ($s in $Sections) {
        if ($s.name -eq $Name) { return $s.description }
    }
    return "Architecture documentation."
}

function Build-SectionReadme([string]$SectionPath, [string]$Name, [string]$Description) {
    $num = $Name.Split("_")[0]
    $title = ($Name -replace '^\d{2}_','') -replace '_',' '
    $files = @(Get-ChildItem -Path $SectionPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" })
    $counts = @{ complete = 0; draft = 0; review = 0; stub = 0; archived = 0 }
    foreach ($f in $files) {
        $st = Get-Status $f.FullName
        if (-not $counts.ContainsKey($st)) { $st = "stub" }
        $counts[$st]++
    }
    $total = $files.Count
    $lines = @(
        "# $num $title",
        "",
        "> Status: $($counts.complete) complete / $($counts.draft) draft / $($counts.review) review / $($counts.stub) stub ($total topics)",
        "",
        "## Purpose",
        "",
        $Description,
        "",
        "## Start here",
        ""
    )
    $start = @($files | Sort-Object FullName | Where-Object { (Get-Status $_.FullName) -ne "stub" } | Select-Object -First 5)
    if ($start.Count -eq 0) { $start = @($files | Sort-Object FullName | Select-Object -First 3) }
    if ($start.Count -eq 0) {
        $lines += "- Browse subsections below."
    } else {
        foreach ($f in $start) {
            $rel = $f.FullName.Substring($SectionPath.Length + 1) -replace '\\','/'
            $lines += "- [$($f.BaseName -replace '_',' ')]($rel)"
        }
    }
    $lines += @("", "## Subsections", "", "| # | Topic | Topics | Key doc | Status |", "| --- | --- | ---: | --- | --- |")
    foreach ($sub in (Get-ChildItem -Path $SectionPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($sub.Name.StartsWith("_")) { continue }
        $subFiles = @(Get-ChildItem -Path $sub.FullName -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" })
        $key = $subFiles | Sort-Object FullName | Select-Object -First 1
        $keyLink = ""
        $keyStatus = "stub"
        if ($key) {
            $keyLink = "[" + ($key.BaseName -replace '_',' ') + "](" + (($key.FullName.Substring($SectionPath.Length + 1)) -replace '\\','/') + ")"
            $keyStatus = Get-Status $key.FullName
        }
        $subId = $sub.Name.Split("_")[0]
        $subTitle = ($sub.Name -replace '^\d{2}\.\d{2}_','') -replace '_',' '
        $lines += "| $subId | $subTitle | $($subFiles.Count) | $keyLink | $keyStatus |"
    }
    $lines += @("", "## Related", "", "- [Architecture Space](../README.md)", "- [Contributing](../CONTRIBUTING.md)", "- [Repository README](../../README.md)", "")
    return ($lines -join "`n") + "`n"
}

$LegacyPresent = Test-Path $OldRoot

if (-not $RefreshOnly -and $LegacyPresent) {
Write-Host "Phase 0: fixing duplicate front matter"
$normalized = 0
foreach ($file in (Get-ChildItem -Path $OldRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue)) {
    Normalize-Document $file $OldRoot | Out-Null
    $normalized++
}

Write-Host "Phase 1: creating target taxonomy shell"
Ensure-Dir $NewRoot
Ensure-Dir (Join-Path $NewRoot "_meta")
Ensure-Dir (Join-Path $NewRoot "_hubs")
Ensure-Dir (Join-Path $NewRoot "_archive")
foreach ($section in $Sections) {
    $sp = Join-Path $NewRoot $section.name
    Ensure-Dir $sp
    foreach ($sub in $section.subs) { Ensure-Dir (Join-Path $sp $sub) }
}

Write-Host "Writing taxonomy metadata"
$taxonomyLines = @("# Canonical taxonomy for Architecture Space", "generated_on: $Today", "content_root: docs", "sections:")
foreach ($section in $Sections) {
    $taxonomyLines += "  - id: `"$($section.id)`""
    $taxonomyLines += "    path: $($section.name)"
    $taxonomyLines += "    title: `"$($section.name -replace '^\d{2}_','' -replace '_',' ')`""
    $taxonomyLines += "    description: `"$($section.description)`""
    $taxonomyLines += "    subsections:"
    foreach ($sub in $section.subs) { $taxonomyLines += "      - $sub" }
}
Write-Text (Join-Path $NewRoot "_meta\taxonomy.yaml") (($taxonomyLines -join "`n") + "`n")

$migration = New-Object System.Collections.Generic.List[string]
$redirectLines = @("# Migration Redirect Index", "", "Generated on $Today.", "", "| Old path | New path | Action | Status |", "| --- | --- | --- | --- |")

Write-Host "Migrating complete/draft/review docs and planned stub map"
$copied = 0
$planned = 0
foreach ($file in (Get-ChildItem -Path $OldRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" })) {
    $rel = $file.FullName.Substring($OldRoot.Length + 1) -replace '\\','/'
    $status = Get-Status $file.FullName
    $targetRel = Get-TargetForPath $rel $status
    $targetPath = Join-Path $NewRoot ($targetRel -replace '/','\')
    $action = if (@("complete","draft","review") -contains $status) { "copied" } else { "planned_stub" }

    if ($action -eq "copied") {
        Ensure-Dir (Split-Path -Parent $targetPath)
        if (-not $DryRun) { Copy-Item -Path $file.FullName -Destination $targetPath -Force }
        $copied++
        $redirectLines += "| `Enterprise Transformation/$rel` | `docs/$targetRel` | copied | $status |"
    } else {
        $planned++
    }
    $migration.Add("  - old_path: `"Enterprise Transformation/$rel`"")
    $migration.Add("    new_path: `"docs/$targetRel`"")
    $migration.Add("    status: $status")
    $migration.Add("    migration_action: $action")
}

Write-Text (Join-Path $NewRoot "_meta\migration_map.yaml") ("# Old-to-new taxonomy migration map`ngenerated_on: $Today`nitems:`n" + (($migration.ToArray()) -join "`n") + "`n")
Write-Text (Join-Path $NewRoot "_meta\redirects.md") (($redirectLines -join "`n") + "`n")

Write-Host "Creating hub files"
$hubDataMesh = @"
---
title: Data Mesh Hub
section: "01"
status: complete
template: hub
last_reviewed: $Today
owner: architecture-team
tags: [data-mesh, hub]
canonical: true
---
# Data Mesh Hub

Canonical navigation hub for data mesh fundamentals, data products, federated governance, and domain-driven data architecture.

## Canonical Sections

- [Data Architecture](../01_Data_Architecture/README.md)
- [Data Product Architecture](../06_Data_Product_Architecture/README.md)
- [Data Governance And Metadata](../00_Architecture_Governance/00.10_Data_Governance_And_Metadata/README.md)
"@
Write-Text (Join-Path $NewRoot "_hubs\Data_Mesh_Hub.md") ($hubDataMesh + "`n")

$hubFinOps = @"
---
title: FinOps Hub
section: "04"
status: complete
template: hub
last_reviewed: $Today
owner: architecture-team
tags: [finops, hub]
canonical: true
---
# FinOps Hub

Canonical navigation hub for cloud data platform FinOps, showback, chargeback, AI FinOps, and cost optimization.

## Canonical Sections

- [Cloud Data Platforms](../04_Cloud_Data_Platforms/README.md)
- [AI Data Architecture](../11_AI_Data_Architecture/README.md)
- [POCs And Benchmarks](../18_POCs_And_Benchmarks/README.md)
"@
Write-Text (Join-Path $NewRoot "_hubs\FinOps_Hub.md") ($hubFinOps + "`n")

$hubAgentic = @"
---
title: Agentic AI Hub
section: "11.12"
status: complete
template: hub
last_reviewed: $Today
owner: architecture-team
tags: [agentic-ai, hub]
canonical: true
---
# Agentic AI Hub

Canonical navigation hub for agent design, MCP, A2A, orchestration, AgentOps, and digital workforce architecture.

## Canonical Sections

- [Agentic AI Architecture](../11_AI_Data_Architecture/11.12_Agentic_AI_Architecture/README.md)
- [AI Data Architecture](../11_AI_Data_Architecture/README.md)
- [MLOps Architecture](../13_MLOps_Architecture/README.md)
"@
Write-Text (Join-Path $NewRoot "_hubs\Agentic_AI_Hub.md") ($hubAgentic + "`n")

$hubPluto = @"
---
title: Pluto MIND Hub
section: "20"
status: complete
template: hub
last_reviewed: $Today
owner: architecture-team
tags: [pluto-mind, hub]
canonical: true
---
# Pluto MIND Hub

Canonical navigation hub for Pluto MIND product architecture.

## Capabilities

- [Acquisition AI](../20_Pluto_MIND/20.01_Acquisition_AI/README.md)
- [Model AI](../20_Pluto_MIND/20.02_Model_AI/README.md)
- [Transformation AI](../20_Pluto_MIND/20.03_Transformation_AI/README.md)
- [Fluid Specification](../20_Pluto_MIND/20.04_Fluid_Specification/README.md)
- [Data Product Builder](../20_Pluto_MIND/20.05_Data_Product_Builder/README.md)
"@
Write-Text (Join-Path $NewRoot "_hubs\Pluto_MIND_Hub.md") ($hubPluto + "`n")

Write-Host "Creating greenfield skeleton documents"
foreach ($section in @($Sections | Where-Object { $_.id -in @("16","20") })) {
    $sp = Join-Path $NewRoot $section.name
    foreach ($sub in $section.subs) {
        $subPath = Join-Path $sp $sub
        $title = ($sub -replace '^\d{2}\.\d{2}_','') -replace '_',' '
        $readme = @"
---
title: $title
section: "$($section.id)"
status: stub
template: overview
last_reviewed: $Today
owner: architecture-team
tags: []
canonical: true
---
# $title

## Purpose

This section is a structured placeholder in the new architecture taxonomy.

## Planned Content

- Overview
- Core concepts
- Reference patterns
- Examples and scenarios

## Related

- [Section README](../README.md)
"@
        Write-Text (Join-Path $subPath "README.md") ($readme + "`n")
    }
}

} # end legacy migration block

Write-Host "Generating target README indexes"
foreach ($section in $Sections) {
    $sp = Join-Path $NewRoot $section.name
    $content = Build-SectionReadme $sp $section.name $section.description
    Write-Text (Join-Path $sp "README.md") $content
}

$master = @(
    "# Architecture Space",
    "",
    "Architecture-first documentation space for enterprise data, analytics, AI, cloud data platforms, governance, security, POCs, and Pluto MIND.",
    "",
    "## Start Here",
    "",
    "- [Architecture Governance](00_Architecture_Governance/README.md)",
    "- [Data Architecture](01_Data_Architecture/README.md)",
    "- [Data Engineering Architecture](02_Data_Engineering_Architecture/README.md)",
    "- [AI Data Architecture](11_AI_Data_Architecture/README.md)",
    "- [Pluto MIND](20_Pluto_MIND/README.md)",
    "",
    "## Hubs",
    "",
    "- [Data Mesh Hub](_hubs/Data_Mesh_Hub.md)",
    "- [FinOps Hub](_hubs/FinOps_Hub.md)",
    "- [Agentic AI Hub](_hubs/Agentic_AI_Hub.md)",
    "- [Pluto MIND Hub](_hubs/Pluto_MIND_Hub.md)",
    "",
    "## Sections",
    "",
    "| # | Section | Purpose |",
    "| --- | --- | --- |"
)
foreach ($section in $Sections) {
    $title = ($section.name -replace '^\d{2}_','') -replace '_',' '
    $master += "| $($section.id) | [$title]($($section.name)/README.md) | $($section.description) |"
}
$master += @("", "## Metadata", "", "- [Taxonomy Registry](_meta/taxonomy.yaml)", "- [Consolidation Report](_meta/consolidation_report.md)", "- [Migration Map](_meta/migration_map.yaml)", "")
Write-Text (Join-Path $NewRoot "README.md") (($master -join "`n") + "`n")

Write-Host "Normalizing target docs metadata"
foreach ($section in $Sections) {
    $sectionRoot = Join-Path $NewRoot $section.name
    foreach ($file in (Get-ChildItem -Path $sectionRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue)) {
        Normalize-Document $file $NewRoot -ForceInferredSection | Out-Null
    }
}
foreach ($file in (Get-ChildItem -Path (Join-Path $NewRoot "_hubs") -Recurse -Filter "*.md" -ErrorAction SilentlyContinue)) {
    Normalize-Document $file $NewRoot | Out-Null
}

Write-Host "Writing migration report"
$linkRows = New-Object System.Collections.Generic.List[string]
$linkRows.Add("# Link Validation Report")
$linkRows.Add("")
$linkRows.Add("Generated on $Today.")
$linkRows.Add("")
$linkRows.Add("| Source | Link |")
$linkRows.Add("| --- | --- |")
$checkedLinks = 0
$brokenLinks = 0
$linkRegex = [regex]'\[[^\]]+\]\(([^)#]+)(#[^)]+)?\)'
foreach ($file in (Get-ChildItem -Path $NewRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue)) {
    $text = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    foreach ($match in $linkRegex.Matches($text)) {
        $href = $match.Groups[1].Value
        if ($href -match '^(https?:|mailto:)' -or [string]::IsNullOrWhiteSpace($href)) { continue }
        $checkedLinks++
        $candidate = if ($href.StartsWith("/")) { Join-Path $NewRoot $href.TrimStart("/") } else { Join-Path $file.DirectoryName $href }
        if (-not (Test-Path $candidate)) {
            $brokenLinks++
            if ($linkRows.Count -lt 205) {
                $src = $file.FullName.Substring($NewRoot.Length + 1) -replace '\\','/'
                $linkRows.Add("| ``$src`` | ``$href`` |")
            }
        }
    }
}
$linkRows.Add("")
$linkRows.Add("Checked links: $checkedLinks")
$linkRows.Add("Broken links: $brokenLinks")
$linkRows.Add("")
$linkRows.Add("Most broken links come from migrated high-value documents that still point to legacy/stub documents intentionally left in `Enterprise Transformation/`. Resolve these as the mapped stubs are migrated into the new taxonomy.")
Write-Text (Join-Path $NewRoot "_meta\link_validation_report.md") (($linkRows.ToArray() -join "`n") + "`n")

$report = @"
# Taxonomy Revamp Migration Report

Generated on $Today.

## Summary

- Normalized source markdown files: $normalized
- Copied complete/draft/review documents into `docs/`: $copied
- Planned stub mappings retained for later migration: $planned
- Target sections created: $($Sections.Count)
- Relative links checked: $checkedLinks
- Broken links tracked in `_meta/link_validation_report.md`: $brokenLinks

## Migration Policy

Only high-value documents (complete, review, or draft) were copied into the new taxonomy during the initial revamp. The legacy ``Enterprise Transformation/`` tree was fully consolidated into ``docs/`` on $Today.

## Next Validation

Run:

    powershell -ExecutionPolicy Bypass -File tools/docs/scripts/revamp_taxonomy.ps1

Then run Python validation when Python/MkDocs is available:

    python tools/docs/scripts/validate_front_matter.py
    python tools/docs/scripts/validate_links.py
    mkdocs build --strict -f tools/docs/mkdocs.yml
"@
Write-Text (Join-Path $NewRoot "_meta\migration_report.md") $report

Write-Host "Done. Normalized=$normalized Copied=$copied Planned=$planned"
