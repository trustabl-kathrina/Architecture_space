# Consolidate canonical Showback_Model and Governance_Maturity documents
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"

function Write-Doc($RelativePath, $FrontMatter, $Body) {
    $path = Join-Path $DocsRoot $RelativePath
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $content = $FrontMatter.TrimEnd() + "`n---`n`n" + $Body.Trim() + "`n"
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

# Canonical Showback Model
Write-Doc "18_FinOps_And_Cost_Optimization/18.12_Cost_Allocation_And_Chargeback/Showback_Model.md" @"
---
title: Showback Model
section: "18.12"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [finops, showback]
"@ @"
# Showback Model

## Context

Showback allocates cloud and platform costs to consuming teams without actual financial chargeback. It builds cost awareness and accountability while avoiding the organizational friction of full chargeback during early FinOps maturity.

## Definition

**Showback** is a financial transparency practice where infrastructure and platform costs are attributed to business units, products, or domains and reported regularly — without transferring actual budget liability.

## Key principles

1. **Transparency** — Every team sees what they consume.
2. **Attribution** — Costs map to tags, namespaces, or data products.
3. **Education** — Reports drive optimization conversations, not invoices.
4. **Progression** — Showback precedes chargeback in FinOps maturity.

## Implementation model

| Step | Activity |
| --- | --- |
| 1 | Define cost allocation dimensions (BU, product, environment) |
| 2 | Enforce tagging standards across cloud and data platforms |
| 3 | Publish monthly showback reports via FinOps tooling |
| 4 | Review with platform and product owners quarterly |

## Domain applications

- **Cloud (16):** Per-account and per-workload showback via cloud cost tools.
- **Data platform (10):** Per-warehouse, per-query, or per-data-product attribution.
- **Data engineering (04):** Pipeline and cluster cost attribution.
- **Platform engineering (17):** Shared platform costs distributed by consumption.
- **Strategy (01):** Funding model alignment and executive reporting.

## Related

- [FinOps Hub](../../hubs/FinOps_Hub.md)
- [Chargeback Model](Chargeback_Model.md)
- [Cost Allocation Framework](Cost_Allocation_Framework.md)
"@

$showbackDeltas = @{
    "01_Enterprise_Strategy_And_Operating_Model/01.09_Funding_Model/Showback_Model.md" = "01 Funding Model"
    "04_Data_Engineering/04.20_Cost_Optimization/Showback_Model.md" = "04 Data Engineering"
    "10_Lakehouse_And_Modern_Data_Platforms/10.24_Platform_Cost_Optimization/Showback_Model.md" = "10 Lakehouse Platform"
    "16_Cloud_Architecture/16.19_Cloud_FinOps/Showback_Model.md" = "16 Cloud Architecture"
    "17_Platform_Engineering/17.22_Platform_FinOps/Showback_Model.md" = "17 Platform Engineering"
}

foreach ($rel in $showbackDeltas.Keys) {
    $domain = $showbackDeltas[$rel]
    Write-Doc $rel @"
---
title: Showback Model
section: "$($rel.Split('/')[0].Split('_')[0])"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [finops, showback]
"@ @"
# Showback Model — $domain Application

> **Canonical reference:** [Showback Model](../../18_FinOps_And_Cost_Optimization/18.12_Cost_Allocation_And_Chargeback/Showback_Model.md)

## Domain-specific application

This document describes how the enterprise showback model applies within **$domain**.

- Attribute costs using domain-specific tags and namespaces.
- Include shared platform costs proportional to consumption.
- Report monthly to domain product owners and engineering leads.
- Escalate anomalies to the FinOps governance forum.

## Related

- [FinOps Hub](../../hubs/FinOps_Hub.md)
"@
}

# Canonical Governance Maturity
Write-Doc "08_Governance_And_Metadata/08.02_Governance_Strategy/Governance_Maturity.md" @"
---
title: Governance Maturity
section: "08.02"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [governance, maturity]
"@ @"
# Governance Maturity

## Context

Governance maturity measures how effectively an organization manages data, metadata, AI, and architecture decisions — from ad hoc policies to automated, value-driven governance operations.

## Maturity levels

| Level | Name | Characteristics |
| --- | --- | --- |
| 1 | Initial | Reactive, siloed policies; limited tooling |
| 2 | Developing | Defined roles; catalog and glossary started |
| 3 | Defined | Enterprise standards; federated stewardship |
| 4 | Managed | Metrics-driven; automated policy enforcement |
| 5 | Optimized | Continuous improvement; governance as product |

## Assessment dimensions

- **Organization** — Roles, stewardship, operating model
- **Policy** — Standards, compliance, exception management
- **Technology** — Catalog, lineage, quality, access control
- **Process** — Onboarding, change management, incident response
- **Value** — Risk reduction, trust, data/AI adoption

## Domain applicability

Each architecture domain applies this model with domain-specific criteria. Domain copies link here for the canonical framework.

## Related

- [Governance Maturity Model](../08.27_Governance_Maturity/Governance_Maturity_Model.md)
- [Data Mesh Hub](../../hubs/Data_Mesh_Hub.md)
"@

Get-ChildItem -Path $DocsRoot -Recurse -Filter "Governance_Maturity.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    if ($rel -eq "08_Governance_And_Metadata\08.02_Governance_Strategy\Governance_Maturity.md") { return }
    $section = $rel.Split('\')[0].Split('_')[0]
    $depth = ($rel -split '\\').Count - 1
    $prefix = ('../' * $depth)
    Write-Doc ($rel -replace '\\','/') @"
---
title: Governance Maturity
section: "$section"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: [governance, maturity]
"@ @"
# Governance Maturity — Domain Application

> **Canonical reference:** [Governance Maturity](${prefix}08_Governance_And_Metadata/08.02_Governance_Strategy/Governance_Maturity.md)

## Domain context

This document applies the enterprise governance maturity model within this architecture domain. Use the canonical framework for assessment criteria and maturity levels.

## Recommended actions

1. Assess current maturity against the five-level model.
2. Identify gaps in stewardship, policy, and tooling.
3. Align remediation to the domain transformation roadmap.
"@
}

Write-Host "Canonical consolidation complete."
