# Generate Top 10 open-source orchestration learning guides
$Base = Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture\02.03.03_Top_10"
$Base = [System.IO.Path]::GetFullPath($Base)

$RemoveFolders = @(
    "02.03.03.05_Cloud_Composer_Learning_Guide", "02.03.03.06_MWAA_Learning_Guide",
    "02.03.03.07_Azure_Data_Factory_Learning_Guide", "02.03.03.08_Step_Functions_Learning_Guide",
    "02.03.03.09_Cloud_Workflows_Learning_Guide",
    "02.03.03.10_Temporal_Learning_Guide", "02.03.03.11_Argo_Workflows_Learning_Guide"
)

$Techs = @(
    @{ id="02.03.03.02"; folder="02.03.03.02_Apache_Airflow_Learning_Guide"; rank=1; name="Apache Airflow"; short="Airflow"; section="02.03.03.02"; tags="airflow, open-source"; desc="the de facto open source DAG orchestrator for batch data pipelines"; prereq="Python 3.9+, basic DAG concepts"; docs="https://airflow.apache.org/docs/"; pricing="https://airflow.apache.org/"; category="Open source DAG orchestrator" },
    @{ id="02.03.03.03"; folder="02.03.03.03_Prefect_Learning_Guide"; rank=2; name="Prefect"; short="Prefect"; section="02.03.03.03"; tags="prefect, open-source"; desc="a modern Python-native workflow engine with self-hosted agents and optional Prefect Cloud"; prereq="Python 3.9+"; docs="https://docs.prefect.io/"; pricing="https://www.prefect.io/pricing"; category="Open source Python orchestration" },
    @{ id="02.03.03.04"; folder="02.03.03.04_Dagster_Learning_Guide"; rank=3; name="Dagster"; short="Dagster"; section="02.03.03.04"; tags="dagster, open-source, assets"; desc="an asset-centric orchestrator with software-defined assets, partitions, and built-in lineage"; prereq="Python, data pipeline concepts"; docs="https://docs.dagster.io/"; pricing="https://dagster.io/pricing"; category="Open source asset orchestrator" },
    @{ id="02.03.03.05"; folder="02.03.03.05_Temporal_Learning_Guide"; rank=4; name="Temporal"; short="Temporal"; section="02.03.03.05"; tags="temporal, durable-execution, open-source"; desc="a durable execution platform for fault-tolerant, long-running workflows (self-host or Temporal Cloud)"; prereq="Go/Java/Python/TypeScript SDK basics"; docs="https://docs.temporal.io/"; pricing="https://temporal.io/pricing"; category="Durable execution (open source core)" },
    @{ id="02.03.03.06"; folder="02.03.03.06_Argo_Workflows_Learning_Guide"; rank=5; name="Argo Workflows"; short="Argo"; section="02.03.03.06"; tags="argo, kubernetes, cncf, open-source"; desc="a CNCF Kubernetes-native workflow engine for containerized batch and ML pipelines"; prereq="Kubernetes, containers"; docs="https://argo-workflows.readthedocs.io/"; pricing="https://argo-workflows.readthedocs.io/"; category="Kubernetes-native workflows" },
    @{ id="02.03.03.07"; folder="02.03.03.07_Kestra_Learning_Guide"; rank=6; name="Kestra"; short="Kestra"; section="02.03.03.07"; tags="kestra, open-source, yaml"; desc="an open source declarative orchestrator with YAML flows, plugins, and a built-in UI"; prereq="YAML, Docker or Kubernetes"; docs="https://kestra.io/docs/"; pricing="https://kestra.io/pricing"; category="Declarative open source orchestrator" },
    @{ id="02.03.03.08"; folder="02.03.03.08_Flyte_Learning_Guide"; rank=7; name="Flyte"; short="Flyte"; section="02.03.03.08"; tags="flyte, kubernetes, ml, open-source"; desc="a Kubernetes-native workflow platform for data and ML pipelines with strong typing and caching"; prereq="Python, Kubernetes basics"; docs="https://docs.flyte.org/"; pricing="https://union.ai/pricing"; category="K8s data/ML orchestrator" },
    @{ id="02.03.03.09"; folder="02.03.03.09_Luigi_Learning_Guide"; rank=8; name="Luigi"; short="Luigi"; section="02.03.03.09"; tags="luigi, spotify, open-source"; desc="Spotify's lightweight Python batch pipeline framework with dependency graphs and target abstractions"; prereq="Python"; docs="https://luigi.readthedocs.io/"; pricing="https://luigi.readthedocs.io/"; category="Lightweight Python batch framework" },
    @{ id="02.03.03.10"; folder="02.03.03.10_Metaflow_Learning_Guide"; rank=9; name="Metaflow"; short="Metaflow"; section="02.03.03.10"; tags="metaflow, netflix, ml, open-source"; desc="Netflix's human-centric framework for data science and ML workflows with local-to-cloud scaling"; prereq="Python, AWS optional for Metaflow plugins"; docs="https://docs.metaflow.org/"; pricing="https://docs.metaflow.org/"; category="ML/data workflow framework" },
    @{ id="02.03.03.11"; folder="02.03.03.11_Mage_Learning_Guide"; rank=10; name="Mage"; short="Mage"; section="02.03.03.11"; tags="mage, open-source, notebook"; desc="an open source hybrid notebook and pipeline tool with scheduling, observability, and modular blocks"; prereq="Python/SQL, Docker"; docs="https://docs.mage.ai/"; pricing="https://www.mage.ai/pricing"; category="Notebook-style pipeline orchestrator" }
)

$Modules = @(
    @("01","Overview","overview"), @("02","Architecture","concept"), @("03","How_To_Use","concept"),
    @("04","Scenarios","concept"), @("05","Limitations_And_Scenarios","concept"), @("06","Costing","evaluation"),
    @("07","Production_Configuration","concept"), @("08","Evaluation_Criteria","evaluation"), @("09","Benchmarking","evaluation")
)

$ModuleFocus = @{
    "01"="What it is, mental model, when to use"; "02"="Components, control vs execution plane";
    "03"="Author, deploy, invoke, operate"; "04"="Enterprise pipeline patterns";
    "05"="Quotas, constraints, mitigations"; "06"="Self-host and OSS cost models";
    "07"="HA, security, monitoring recipes"; "08"="Scorecard vs peer technologies";
    "09"="Reference load and sizing profiles"
}

foreach ($f in $RemoveFolders) {
    $p = Join-Path $Base $f
    if (Test-Path $p) { Remove-Item $p -Recurse -Force; Write-Host "Removed $f" }
}

function Get-Frontmatter($title, $section, $template, $tags) {
@"
---
title: $title
section: "$section"
status: complete
template: $template
last_reviewed: 2026-06-20
owner: architecture-team
tags: [$tags, top-10, learning-guide, open-source]
canonical: true
---

"@
}

$count = 0
foreach ($t in $Techs) {
    $dir = Join-Path $Base $t.folder
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $modRows = ($Modules | ForEach-Object { "| $($_[0]) | [$($_[1].Replace('_',' '))]($($t.id).$($_[0])_$($_[1]).md) | $($ModuleFocus[$_[0]]) |" }) -join "`n"
    $readme = (Get-Frontmatter "$($t.name) Learning Guide" $t.section "hub" $t.tags) + @"

# $($t.name) Learning Guide

> **Rank #$($t.rank)** in [Top 10 Open Source Orchestration](../02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md).

Structured learning path for **$($t.desc)**.

For managed cloud orchestrators (Composer, MWAA, ADF, Step Functions, Workflows), see [02.03.02 Cloud Services](../../02.03.02_Cloud_Services/README.md).

## Prerequisites

- $($t.prereq)
- [Top 10 rankings](../02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md)

## Modules

| # | Module | Focus |
| ---: | --- | --- |
$modRows

## Quick links

- [Top 10 README](../README.md)
- [Official documentation]($($t.docs))
- [Official pricing / OSS license]($($t.pricing))
"@
    Set-Content -Path (Join-Path $dir "README.md") -Value $readme -Encoding UTF8
    $count++

    foreach ($m in $Modules) {
        $num, $modName, $template = $m
        $prefix = "$($t.id).$num"
        $hnum = [int]$num
        $body = switch ($num) {
            "01" { @"
# $hnum. $($t.name) Overview

## What is $($t.short)?

**$($t.name)** is $($t.desc). Category: **$($t.category)**.

## Why Top 10 rank #$($t.rank)?

Ranked in [Top 10 Open Source Orchestration](../02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md) for adoption in data engineering, OSS community, and production fit — **excluding** hyperscaler managed services covered in [Cloud Services](../../02.03.02_Cloud_Services/README.md).

## When to use $($t.short)

| Use when… | Consider alternatives when… |
| --- | --- |
| $($t.category) matches your platform strategy | Managed cloud-only standard → [Cloud Services](../../02.03.02_Cloud_Services/README.md) |
| Team prefers $($t.short) model | Portable DAG mesh → **Airflow** or **Prefect** |
| Self-host or bring-your-own K8s | Serverless cloud glue only → Step Functions / Workflows in Cloud Services |

## Learning path

Continue to [Architecture](${prefix}_Architecture.md) or [Scenarios](${prefix}_Scenarios.md).
"@
            }
            "02" { @"
# $hnum. Architecture of $($t.name)

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Definitions, scheduling, metadata, APIs |
| **Execution plane** | Task/workflow runs, workers, integrations |

See [official architecture docs]($($t.docs)) and [orchestration reference model](../../02.03.01_Fundamentals/02.03.01.01_Overview/02.03.01.01.03_Orchestration_Reference_Model.md).

## Design principle

**Thin orchestrator, fat compute** — $($t.short) coordinates; Spark, warehouses, and containers execute heavy work.
"@
            }
            default { @"
# $hnum. $($t.name) $($modName.Replace('_',' '))

See [official documentation]($($t.docs)) and [Top 10 hub](../README.md).

Module focus: $($ModuleFocus[$num])
"@
            }
        }
        $title = "$($t.name) $($modName.Replace('_',' '))"
        $content = (Get-Frontmatter $title $t.section $template $t.tags) + $body + @"

## Related

- [Top 10 README](../README.md)
- [$($t.name) hub](../README.md)
"@
        Set-Content -Path (Join-Path $dir "${prefix}_${modName}.md") -Value $content -Encoding UTF8
        $count++
    }
}
Write-Host "Wrote $count guide files"
