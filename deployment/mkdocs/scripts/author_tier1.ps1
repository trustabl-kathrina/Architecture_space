# Author Tier 1: What_Is primers and section overview anchors
$ErrorActionPreference = "Stop"
$DocsRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "docs"

function Write-Doc($RelativePath, $Meta, $Body) {
    $path = Join-Path $DocsRoot ($RelativePath -replace '/','\')
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($path, ($Meta.TrimEnd() + "`n---`n`n" + $Body.Trim() + "`n"), [Text.UTF8Encoding]::new($false))
    Write-Host "Authored: $RelativePath"
}

$files = @{
    "01_Data_Architecture/01.01_Fundamentals/Overview/What_Is_Data_Architecture.md" = @{
        title = "What Is Data Architecture"; section = "01.01"
        body = @'
# What Is Data Architecture

## Context
Enterprise architects need a shared understanding of how data is structured, integrated, and governed.

## Definition
Data architecture defines how enterprise data is structured, integrated, governed, and consumed across domains spanning conceptual, logical, and physical layers.

## Scope
In scope: data models, domains, integration patterns, metadata. Out of scope: application UI design, network infrastructure.

## Related
- [Data Architecture Framework](../Data_Architecture_Framework/Data_Architecture_Framework.md)
- [Data Mesh Hub](../../hubs/Data_Mesh_Hub.md)
'@
    }
    "06_AI_Architecture/06.01_Overview/What_Is_AI_Architecture.md" = @{
        title = "What Is AI Architecture"; section = "06.01"
        body = @'
# What Is AI Architecture

## Definition
AI architecture defines how machine learning, generative AI, and intelligent systems are designed, deployed, governed, and operated at enterprise scale.

## Scope
In scope: ML/GenAI platforms, model lifecycle, AI governance. Out of scope: research-only prototypes.

## Related
- [Enterprise AI Framework](../06.03_Enterprise_AI_Framework/Enterprise_AI_Framework.md)
- [Agentic AI Hub](../../hubs/Agentic_AI_Hub.md)
'@
    }
    "07_Agentic_AI_Architecture/00.10.01_Overview/What_Is_Agentic_AI.md" = @{
        title = "What Is Agentic AI"; section = "00.10.01"
        body = @'
# What Is Agentic AI

## Definition
Agentic AI refers to autonomous software agents that plan, reason, use tools, and collaborate to accomplish goals with human oversight.

## Related
- [Agentic AI Framework](../00.10.03_Agentic_AI_Framework/Agentic_AI_Framework.md)
- [Agentic AI Hub](../../hubs/Agentic_AI_Hub.md)
'@
    }
    "09_Data_Mesh_And_Domain_Architecture/02.01.02.01_Overview/What_Is_Data_Mesh.md" = @{
        title = "What Is Data Mesh"; section = "02.01.02.01"
        body = @'
# What Is Data Mesh

## Definition
Data mesh is a decentralized approach where domain teams own and share data as products with federated governance and self-serve platforms.

## Related
- [Data Mesh Hub](../../hubs/Data_Mesh_Hub.md)
- [Data Mesh Framework](../02.01.02.03_Data_Mesh_Framework/Data_Mesh_Framework.md)
'@
    }
    "02_Enterprise_Architecture/02.01_Overview/What_Is_Enterprise_Architecture.md" = @{
        title = "What Is Enterprise Architecture"; section = "02.01"
        body = @'
# What Is Enterprise Architecture

## Definition
Enterprise architecture aligns business strategy with technology through structured views of capabilities, applications, data, and technology.

## Related
- [EA Frameworks](../02.02_EA_Frameworks/EA_Frameworks.md)
'@
    }
    "04_Data_Engineering/04.01_Overview/What_Is_Data_Engineering.md" = @{
        title = "What Is Data Engineering"; section = "04.01"
        body = @'
# What Is Data Engineering

## Definition
Data engineering builds reliable pipelines that ingest, transform, and deliver data for analytics, AI, and operations.

## Related
- [Streaming Architecture](../04.07_Streaming_Architecture/Streaming_Architecture.md)
'@
    }
    "05_Analytics_Architecture/05.01_Overview/What_Is_Analytics_Architecture.md" = @{
        title = "What Is Analytics Architecture"; section = "05.01"
        body = @'
# What Is Analytics Architecture

## Definition
Analytics architecture enables trusted insights through BI, semantic layers, metrics frameworks, and self-service platforms.
'@
    }
    "08_Governance_And_Metadata/08.01_Overview/What_Is_Data_Governance.md" = @{
        title = "What Is Data Governance"; section = "08.01"
        body = @'
# What Is Data Governance

## Definition
Data governance establishes policies, ownership, and controls ensuring data is trusted, compliant, and fit for purpose.

## Related
- [Governance Maturity](../08.02_Governance_Strategy/Governance_Maturity.md)
'@
    }
    "08_Governance_And_Metadata/08.01_Overview/What_Is_Metadata.md" = @{
        title = "What Is Metadata"; section = "08.01"
        body = @'
# What Is Metadata

## Definition
Metadata is data about data describing structure, lineage, quality, ownership, and usage for discovery and automation.
'@
    }
    "10_Lakehouse_And_Modern_Data_Platforms/08.10.01_Overview/What_Is_A_Lakehouse.md" = @{
        title = "What Is A Lakehouse"; section = "08.10.01"
        body = @'
# What Is A Lakehouse

## Definition
A lakehouse combines data lake flexibility with warehouse governance using open table formats on object storage.
'@
    }
    "11_Integration_Architecture/11.01_Overview/What_Is_Integration_Architecture.md" = @{
        title = "What Is Integration Architecture"; section = "11.01"
        body = @'
# What Is Integration Architecture

## Definition
Integration architecture connects applications, data, and events through APIs, messaging, and pipelines.
'@
    }
    "12_Real_Time_And_Event_Driven_Architecture/11.12.01_Overview/What_Is_Event_Driven_Architecture.md" = @{
        title = "What Is Event Driven Architecture"; section = "11.12.01"
        body = @'
# What Is Event Driven Architecture

## Definition
Event-driven architecture uses events as the primary mechanism for communicating state changes between decoupled services.

## Related
- [Event Driven Architecture](Event_Driven_Architecture.md)
'@
    }
    "12_Real_Time_And_Event_Driven_Architecture/11.12.01_Overview/What_Is_Real_Time_Architecture.md" = @{
        title = "What Is Real Time Architecture"; section = "11.12.01"
        body = @'
# What Is Real Time Architecture

## Definition
Real-time architecture processes and delivers data with low latency for operational analytics and automated decisions.
'@
    }
    "13_MDM_And_Reference_Data/13.01_Overview/What_Is_MDM.md" = @{
        title = "What Is MDM"; section = "13.01"
        body = @'
# What Is MDM

## Definition
Master Data Management creates authoritative golden records for core entities like customers, products, and suppliers.
'@
    }
    "13_MDM_And_Reference_Data/13.01_Overview/What_Is_Reference_Data.md" = @{
        title = "What Is Reference Data"; section = "13.01"
        body = @'
# What Is Reference Data

## Definition
Reference data provides standardized codes and classifications used consistently across applications.
'@
    }
    "14_Security_And_Privacy/14.01_Overview/What_Is_Enterprise_Security.md" = @{
        title = "What Is Enterprise Security"; section = "14.01"
        body = @'
# What Is Enterprise Security

## Definition
Enterprise security protects assets through identity, network, application, data, and AI security aligned to zero-trust principles.
'@
    }
    "14_Security_And_Privacy/14.01_Overview/What_Is_Privacy_Engineering.md" = @{
        title = "What Is Privacy Engineering"; section = "14.01"
        body = @'
# What Is Privacy Engineering

## Definition
Privacy engineering embeds privacy-by-design through data minimization, consent management, and compliance controls.
'@
    }
    "15_Data_Quality_And_Observability/15.01_Overview/What_Is_Data_Quality.md" = @{
        title = "What Is Data Quality"; section = "15.01"
        body = @'
# What Is Data Quality

## Definition
Data quality ensures data is accurate, complete, timely, and fit for purpose through rules, profiling, and monitoring.
'@
    }
    "15_Data_Quality_And_Observability/15.01_Overview/What_Is_Data_Observability.md" = @{
        title = "What Is Data Observability"; section = "15.01"
        body = @'
# What Is Data Observability

## Definition
Data observability provides visibility into pipeline health, freshness, schema changes, and anomalies.
'@
    }
    "16_Cloud_Architecture/16.01_Overview/What_Is_Cloud_Architecture.md" = @{
        title = "What Is Cloud Architecture"; section = "16.01"
        body = @'
# What Is Cloud Architecture

## Definition
Cloud architecture designs workloads for scalability, resilience, and cost efficiency across cloud environments.
'@
    }
    "17_Platform_Engineering/17.01_Overview/What_Is_Platform_Engineering.md" = @{
        title = "What Is Platform Engineering"; section = "17.01"
        body = @'
# What Is Platform Engineering

## Definition
Platform engineering builds internal developer platforms with self-service golden paths and shared services.
'@
    }
    "18_FinOps_And_Cost_Optimization/18.01_Overview/What_Is_FinOps.md" = @{
        title = "What Is FinOps"; section = "18.01"
        body = @'
# What Is FinOps

## Definition
FinOps brings financial accountability to cloud spending through collaboration between engineering, finance, and business.

## Related
- [FinOps Hub](../../hubs/FinOps_Hub.md)
'@
    }
    "19_Enterprise_Automation/19.01_Overview/What_Is_Enterprise_Automation.md" = @{
        title = "What Is Enterprise Automation"; section = "19.01"
        body = @'
# What Is Enterprise Automation

## Definition
Enterprise automation orchestrates processes through RPA, workflows, AI, and agentic systems.
'@
    }
    "21_Architecture_Decision_Frameworks/21.01_Overview/What_Is_Architecture_Decision_Making.md" = @{
        title = "What Is Architecture Decision Making"; section = "21.01"
        body = @'
# What Is Architecture Decision Making

## Definition
Architecture decision making evaluates options, records ADRs, and governs technology choices at enterprise scale.
'@
    }
    "23_Transformation_Roadmaps/23.01_Overview/What_Is_Enterprise_Transformation.md" = @{
        title = "What Is Enterprise Transformation"; section = "23.01"
        body = @'
# What Is Enterprise Transformation

## Definition
Enterprise transformation is the coordinated evolution of capabilities, operating models, technology, and culture.
'@
    }
    "24_Vendor_Evaluation_Frameworks/24.01_Overview/What_Is_Vendor_Evaluation.md" = @{
        title = "What Is Vendor Evaluation"; section = "24.01"
        body = @'
# What Is Vendor Evaluation

## Definition
Vendor evaluation assesses technology suppliers against business, technical, commercial, and risk criteria.
'@
    }
    "01_Enterprise_Strategy_And_Operating_Model/01.06_Operating_Model/What_Is_Operating_Model.md" = @{
        title = "What Is Operating Model"; section = "01.06"
        body = @'
# What Is Operating Model

## Definition
An operating model defines how teams are structured, decisions made, work funded, and value delivered.
'@
    }
    "01_Enterprise_Strategy_And_Operating_Model/01.01_Overview/Purpose_Of_Enterprise_Strategy.md" = @{
        title = "Purpose Of Enterprise Strategy"; section = "01.01"
        body = @'
# Purpose of Enterprise Strategy

## Context
Enterprise strategy defines why the organization exists and how data and AI enable competitive advantage.

## Strategic pillars
1. Customer value  2. Operational excellence  3. Innovation  4. Trust

## Related
- [Data and AI Vision](Data_And_AI_Vision.md)
- [Transformation Roadmaps](../../23_Transformation_Roadmaps/README.md)
'@
    }
    "20_Industry_Specific_Patterns/20.01_Overview/Industry_Architecture_Overview.md" = @{
        title = "Industry Architecture Overview"; section = "20.01"
        body = @'
# Industry Architecture Overview

## Context
Industry patterns adapt enterprise architecture to vertical regulations, value chains, and use cases.

## Related
- [Industry Reference Framework](../20.02_Industry_Reference_Framework/Industry_Reference_Framework.md)
'@
    }
    "25_Future_Trends_And_Emerging_Architecture/25.01_Overview/Future_Architecture_Vision.md" = @{
        title = "Future Architecture Vision"; section = "25.01"
        body = @'
# Future Architecture Vision

## Context
Emerging technologies reshape enterprise architecture. This section tracks trends for long-range planning.

## Related
- [Technology Radar](../25.02_Technology_Radar/Technology_Radar.md)
- [Agentic AI Hub](../../hubs/Agentic_AI_Hub.md)
'@
    }
}

foreach ($rel in $files.Keys) {
    $info = $files[$rel]
    $meta = @"
---
title: $($info.title)
section: "$($info.section)"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: []
---
"@
    Write-Doc $rel $meta $info.body
}

Write-Host "Tier 1 complete."
