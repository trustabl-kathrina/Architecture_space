# Scaffold 05 Data Modeling Architecture: Traditional, Enterprise, Modern, Industry pillars.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Root = Join-Path $RepoRoot "docs\04_Data_Modeling_Architecture"
$Legacy = Join-Path $Root "05.05_Cross_Cutting_Standards"
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

function Write-TopicStub([string]$Path, [string]$Title, [string]$Section = "05") {
    if (Test-Path $Path) { return $false }
    $body = @(
        '---',
        "title: $Title",
        "section: `"$Section`"",
        'status: stub',
        'template: evaluation',
        "last_reviewed: $Today",
        'owner: architecture-team',
        'tags: [data-modeling]',
        'canonical: true',
        '---',
        '',
        "# $Title",
        '',
        '## Overview',
        "Describe $Title within the data modeling architecture.",
        '',
        '## Key Concepts',
        '',
        '## Design Guidelines',
        '',
        '## Related',
        '- [05 Data Modeling Architecture](../../README.md)'
    ) -join "`n"
    if ($DryRun) { Write-Host "  create: $(Split-Path $Path -Leaf)"; return $true }
    Ensure-Dir (Split-Path $Path -Parent)
    [IO.File]::WriteAllText((To-LongPath $Path), $body.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
    return $true
}

function Write-Readme([string]$Path, [string]$Section, [string]$Title, [string[]]$Children = @()) {
    if (Test-Path $Path) { return }
    $lines = @(
        '---',
        "title: $Title README",
        "section: `"$Section`"",
        'status: stub',
        'template: overview',
        "last_reviewed: $Today",
        'owner: architecture-team',
        'tags: [data-modeling]',
        'canonical: true',
        '---',
        '',
        "# $Title",
        ''
    )
    if ($Children.Count -gt 0) {
        $lines += '## Topics', ''
        foreach ($c in $Children) { $lines += "- $c" }
    }
    if ($DryRun) { return }
    Ensure-Dir (Split-Path $Path -Parent)
    [IO.File]::WriteAllText((To-LongPath $Path), ($lines -join "`n").TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}

# Pillar > Approach > Topics (file suffix without .md)
$tree = @{
    "05.01_Traditional" = @{
        "05.01.01_Relational" = @("ER_Modeling", "Normalization", "Third_Normal_Form", "BCNF")
        "05.01.02_Kimball_Dimensional" = @("Star_Schema", "Snowflake_Schema", "Fact_Modeling", "Dimension_Modeling", "SCD")
        "05.01.03_Inmon_EDW" = @("CIF", "Subject_Areas", "Data_Marts")
        "05.01.04_Data_Vault" = @("DV_1_0", "DV_2_0", "Hubs", "Links", "Satellites")
    }
    "05.02_Enterprise" = @{
        "05.02.01_Domain_Driven" = @("Bounded_Context", "Domain_Model", "Aggregate", "Domain_Events")
        "05.02.02_Canonical" = @("Enterprise_Data_Model", "Common_Data_Model", "Harmonized_Model", "Industry_Models")
        "05.02.03_MDM_Party_Modeling" = @("Customer_360", "Product_360", "Party_Model", "Golden_Record", "Hierarchy_Modeling")
        "05.02.04_Data_Product_Modeling" = @("Data_Contracts", "Product_Schema", "SLA", "Ownership")
    }
    "05.03_Modern" = @{
        "05.03.01_Event_Modeling" = @("Event_Storming", "Event_Sourcing", "CQRS", "Stream_Modeling")
        "05.03.02_Semantic_Modeling" = @("Metrics_Layer", "Business_Glossary", "Semantic_Layer")
        "05.03.03_Knowledge_Graph_Modeling" = @("Ontology", "RDF", "Property_Graph", "Enterprise_Knowledge_Graph")
        "05.03.04_AI_Modeling" = @("RAG_Modeling", "Vector_Modeling", "Embedding_Modeling", "Chunk_Modeling", "Agent_Memory_Modeling")
    }
    "05.04_Industry_Reference_Models" = @(
        @{ F = "05.04.01_TM_Forum_SID.md"; T = "TM Forum SID" }
        @{ F = "05.04.02_BIAN.md"; T = "BIAN" }
        @{ F = "05.04.03_Healthcare.md"; T = "Healthcare" }
        @{ F = "05.04.04_Retail.md"; T = "Retail" }
        @{ F = "05.04.05_Insurance.md"; T = "Insurance" }
    )
}

$created = 0
foreach ($pillar in $tree.Keys | Sort-Object) {
    $pillarPath = Join-Path $Root $pillar
    Ensure-Dir $pillarPath
    $pillarSection = ($pillar -split '_')[0]
    Write-Readme (Join-Path $pillarPath "README.md") $pillarSection ($pillar -replace '^\d+\.\d+_', '' -replace '_', ' ')

    $val = $tree[$pillar]
    if ($val -is [array]) {
        $topicLinks = @()
        foreach ($item in $val) {
            if (Write-TopicStub (Join-Path $pillarPath $item.F) $item.T "05") { $created++ }
            $topicLinks += "[$($item.T)]($($item.F))"
        }
        Write-Readme (Join-Path $pillarPath "README.md") ($pillar -split '_')[0] ($pillar -replace '^\d+\.\d+_', '' -replace '_', ' ') $topicLinks
        continue
    }

    foreach ($approach in $val.Keys | Sort-Object) {
        $approachPath = Join-Path $pillarPath $approach
        Ensure-Dir $approachPath
        $approachSection = ($approach -split '_')[0] + '.' + ($approach -split '_')[1]
        $topicLinks = @()
        $approachPrefix = ($approach -split '_', 2)[0]
        $i = 1
        foreach ($topic in $val[$approach]) {
            $num = '{0:D2}' -f $i
            $fileName = "${approachPrefix}.${num}_${topic}.md"
            $title = ($topic -replace '_', ' ')
            if (Write-TopicStub (Join-Path $approachPath $fileName) $title "05") { $created++ }
            $topicLinks += "[$title]($fileName)"
            $i++
        }
        Write-Readme (Join-Path $approachPath "README.md") $approachSection ($approach -replace '^\d+\.\d+\.\d+_', '' -replace '_', ' ') $topicLinks
    }
}

# Relocate legacy 05.01_Fundamentals
Write-Host "Relocating legacy fundamentals..."
$oldFund = Join-Path $Root "05.01_Fundamentals"
$moves = @(
    @{ S = "Business_Glossary_Model.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.02_Business_Glossary.md" }
    @{ S = "Business_Semantic_Model.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.04_Business_Semantic_Model.md" }
    @{ S = "Metrics_Layer.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.01_Metrics_Layer.md" }
    @{ S = "Semantic_Layer.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.03_Semantic_Layer.md" }
    @{ S = "Semantic_Model.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.05_Semantic_Model.md" }
    @{ S = "Semantic_Standards.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.06_Semantic_Standards.md" }
    @{ S = "Semantic_Governance.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.07_Semantic_Governance.md" }
    @{ S = "Semantic_Interoperability.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.08_Semantic_Interoperability.md" }
    @{ S = "Semantic_Data_Products.md"; D = "05.03_Modern\05.03.02_Semantic_Modeling\05.03.02.09_Semantic_Data_Products.md" }
    @{ S = "Customer_MDM.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.01_Customer_360.md" }
    @{ S = "Product_MDM.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.02_Product_360.md" }
    @{ S = "Party_Data_Model.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.03_Party_Model.md" }
    @{ S = "Golden_Record_Model.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.04_Golden_Record.md" }
    @{ S = "Hierarchy_Management.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.05_Hierarchy_Modeling.md" }
    @{ S = "Supplier_MDM.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.06_Supplier_MDM.md" }
    @{ S = "MDM_Architecture.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.07_MDM_Architecture.md" }
    @{ S = "MDM_Governance.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.08_MDM_Governance.md" }
    @{ S = "MDM_Strategy.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.09_MDM_Strategy.md" }
    @{ S = "Survivorship_Rules.md"; D = "05.02_Enterprise\05.02.03_MDM_Party_Modeling\05.02.03.10_Survivorship_Rules.md" }
    @{ S = "Enterprise_Canonical_Model.md"; D = "05.02_Enterprise\05.02.02_Canonical\05.02.02.01_Enterprise_Data_Model.md" }
    @{ S = "Enterprise_Information_Model.md"; D = "05.02_Enterprise\05.02.02_Canonical\05.02.02.05_Enterprise_Information_Model.md" }
    @{ S = "Enterprise_Conceptual_Model.md"; D = "05.02_Enterprise\05.02.02_Canonical\05.02.02.06_Enterprise_Conceptual_Model.md" }
    @{ S = "Enterprise_Logical_Model.md"; D = "05.01_Traditional\05.01.01_Relational\05.01.01.05_Enterprise_Logical_Model.md" }
    @{ S = "Data_Vault_Standards.md"; D = "05.01_Traditional\05.01.04_Data_Vault\05.01.04.06_Data_Vault_Standards.md" }
    @{ S = "Dimensional_Modeling_Guidelines.md"; D = "05.01_Traditional\05.01.02_Kimball_Dimensional\05.01.02.06_Dimensional_Modeling_Guidelines.md" }
    @{ S = "Enterprise_Ontology.md"; D = "05.03_Modern\05.03.03_Knowledge_Graph_Modeling\05.03.03.01_Ontology.md" }
    @{ S = "Enterprise_Knowledge_Model.md"; D = "05.03_Modern\05.03.03_Knowledge_Graph_Modeling\05.03.03.05_Enterprise_Knowledge_Graph.md" }
    @{ S = "Modeling_Standards.md"; D = "05.05_Cross_Cutting_Standards\05.05.01_Modeling_Standards.md" }
    @{ S = "Naming_Standards.md"; D = "05.05_Cross_Cutting_Standards\05.05.02_Naming_Standards.md" }
    @{ S = "Enterprise_Taxonomy.md"; D = "05.05_Cross_Cutting_Standards\05.05.03_Enterprise_Taxonomy.md" }
    @{ S = "Information_Architecture_Standards.md"; D = "05.05_Cross_Cutting_Standards\05.05.04_Information_Architecture_Standards.md" }
    @{ S = "Information_Classification.md"; D = "05.05_Cross_Cutting_Standards\05.05.05_Information_Classification.md" }
    @{ S = "Information_Domains.md"; D = "05.05_Cross_Cutting_Standards\05.05.06_Information_Domains.md" }
    @{ S = "Information_Flow_Model.md"; D = "05.05_Cross_Cutting_Standards\05.05.07_Information_Flow_Model.md" }
    @{ S = "Information_Lifecycle.md"; D = "05.05_Cross_Cutting_Standards\05.05.08_Information_Lifecycle.md" }
    @{ S = "Information_Ownership.md"; D = "05.05_Cross_Cutting_Standards\05.05.09_Information_Ownership.md" }
    @{ S = "Information_Value_Framework.md"; D = "05.05_Cross_Cutting_Standards\05.05.10_Information_Value_Framework.md" }
    @{ S = "Reference_Data_Model.md"; D = "05.05_Cross_Cutting_Standards\05.05.11_Reference_Data_Model.md" }
)

Ensure-Dir $Legacy
foreach ($m in $moves) {
    $src = Join-Path $oldFund $m.S
    $dst = Join-Path $Root $m.D
    if (Test-Path $dst) {
        if (-not $DryRun) { Remove-Item $dst -Force }
    }
    if (-not (Test-Path $src)) { continue }
    Ensure-Dir (Split-Path $dst -Parent)
    if ($DryRun) { Write-Host "  move: $($m.S) -> $($m.D)"; continue }
    [System.IO.File]::Move((To-LongPath $src), (To-LongPath $dst))
    Write-Host "  moved: $($m.S)"
}

if (Test-Path $oldFund) {
    $left = Get-ChildItem $oldFund -Recurse -ErrorAction SilentlyContinue
    if (-not $left -or $left.Count -eq 0) {
        if (-not $DryRun) { Remove-Item $oldFund -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "  removed empty 05.01_Fundamentals"
    }
}

Write-Readme (Join-Path $Legacy "README.md") "05.05" "Cross-Cutting Standards"
Write-Host "Created $created topic stubs."
