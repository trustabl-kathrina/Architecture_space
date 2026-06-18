# Author Tier 2: strategy, ADRs, roadmaps, and top vendor evaluations
$ErrorActionPreference = "Stop"
$DocsRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "docs"

function Write-Doc($RelativePath, $Meta, $Body) {
    $path = Join-Path $DocsRoot ($RelativePath -replace '/','\')
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($path, ($Meta.TrimEnd() + "`n---`n`n" + $Body.Trim() + "`n"), [Text.UTF8Encoding]::new($false))
    Write-Host "Authored: $RelativePath"
}

function Adr-Doc($Path, $Num, $Title, $Section, $Status, $Context, $Decision, $Consequences, $Alternatives) {
    $meta = @"
---
title: ADR $Num $Title
section: "$Section"
status: complete
template: adr
last_reviewed: 2026-06-18
owner: architecture-team
tags: [adr]
---
"@
    $body = @"
# ADR-$Num`: $Title

## Status

$Status

## Date

2026-06-18

## Context

$Context

## Decision

$Decision

## Consequences

$Consequences

## Alternatives considered

$Alternatives
"@
    Write-Doc $Path $meta $body
}

function Vendor-Eval($Path, $Vendor, $Section, $Category, $Summary, $Strengths, $Weaknesses, $Recommendation) {
    $meta = @"
---
title: $Vendor Evaluation
section: "$Section"
status: complete
template: evaluation
last_reviewed: 2026-06-18
owner: architecture-team
tags: [vendor-evaluation]
---
"@
    $body = @"
# $Vendor Evaluation

## 1. Problem Statement

Enterprises evaluating $Category platforms need an objective assessment of $Vendor against architectural, operational, and commercial criteria.

## 2. Business Use Cases

- Enterprise analytics and reporting at scale
- Self-service data access with governance controls
- Integration with existing cloud and identity infrastructure

## 3. Architecture Pattern

$Summary

## 4. Technology Options

$Vendor is assessed as a primary option alongside comparable market alternatives.

## 5. Cloud Native Options

|$Vendor integrates with major cloud provider identity, networking, and storage services.

## 6. Top 10 Vendor Options

$Vendor is included in the enterprise shortlist for this category.

## 7. Comparison Matrix

| Criteria | $Vendor | Market average |
| --- | --- | --- |
| Scalability | $Strengths | Varies |
| Ecosystem | Strong | Moderate |
| TCO | See cost section | Varies |
| Enterprise readiness | High | Moderate |

## 8. Benchmark Results

Internal POC benchmarks should be recorded in [22 POCs](../../22_POCs_And_Benchmarking/README.md) and linked here.

## 9. POC Results

Reference section 22 for completed benchmark evaluations where available.

## 10. Cost Comparison

Evaluate subscription, consumption, and support costs against 3-year TCO model. Include FinOps tagging for ongoing attribution.

## 11. Security Comparison

Assess SOC 2, ISO 27001, encryption, IAM integration, and data residency options.

## 12. Scalability Comparison

$Strengths

## 13. Operational Complexity

$Weaknesses

## 14. Enterprise Readiness

Evaluate SLAs, support tiers, disaster recovery, and enterprise agreement terms.

## 15. Recommendation

$Recommendation

## 16. ADR Reference

Link to formal ADR once architecture review board approves selection.
"@
    Write-Doc $Path $meta $body
}

# === Strategy documents ===
$strategyDocs = @{
    "01_Enterprise_Strategy_And_Operating_Model/01.02_Enterprise_Strategy/Enterprise_Vision_And_Mission.md" = @"
# Enterprise Vision and Mission

## Context

The enterprise vision articulates the aspirational future state; the mission defines how the organization creates value today while progressing toward that vision.

## Vision

To be a data- and AI-driven organization that delivers trusted insights, intelligent automation, and differentiated customer experiences at global scale.

## Mission

Empower every business domain with self-service access to governed data products, analytics, and AI capabilities through a federated operating model and modern platform architecture.

## Strategic enablers

- Federated data mesh with domain ownership
- Cloud-native platforms with FinOps discipline
- Responsible AI and agentic automation
- Architecture governance and decision transparency

## Related

- [Enterprise OKRs](Enterprise_OKRs.md)
- [Data and AI Vision](../01.01_Overview/Data_And_AI_Vision.md)
"@
    "01_Enterprise_Strategy_And_Operating_Model/01.02_Enterprise_Strategy/Enterprise_OKRs.md" = @"
# Enterprise OKRs

## Context

Objectives and Key Results (OKRs) align enterprise architecture investments to measurable business outcomes.

## Sample enterprise OKRs

### Objective 1: Accelerate data-driven decisions
- KR1: 80% of priority domains publish certified data products
- KR2: Reduce time-to-insight from 14 days to 48 hours
- KR3: 90% of KPIs sourced from governed semantic layer

### Objective 2: Scale responsible AI
- KR1: Deploy 10 production AI use cases with full governance
- KR2: 100% of GenAI apps use RAG with approved vector store
- KR3: Zero critical AI security incidents

### Objective 3: Optimize platform economics
- KR1: 20% reduction in cloud waste via FinOps
- KR2: Showback reports for 100% of consuming teams
- KR3: Standardize on 3 core data platform vendors

## Related

- [Value Realization](../01.10_Value_Realization/Value_Realization.md)
- [Transformation Roadmap](../01.13_Transformation_Roadmap/Transformation_Roadmap.md)
"@
    "01_Enterprise_Strategy_And_Operating_Model/01.03_Data_Strategy/Data_Vision.md" = @"
# Data Vision

## Context

The data vision describes how the enterprise treats data as a strategic asset — shared, governed, and productized across domains.

## Vision statement

Every domain owns and shares trusted data products that power analytics, AI, and operational excellence through a federated mesh architecture.

## Strategic themes

1. **Data as a product** — Domain teams publish consumable data products
2. **Federated governance** — Global standards, local execution
3. **AI-ready data** — Quality, lineage, and semantics by design
4. **Open platform** — Lakehouse with interoperable formats

## Related

- [Data Mesh Hub](../../hubs/Data_Mesh_Hub.md)
- [Data Strategy Framework](Data_Strategy_Framework.md)
"@
    "01_Enterprise_Strategy_And_Operating_Model/01.04_AI_Strategy/AI_Vision.md" = @"
# AI Vision

## Context

The AI vision defines how the enterprise adopts machine learning, generative AI, and agentic systems responsibly and at scale.

## Vision statement

Embed AI into every value stream through a governed platform that accelerates experimentation, ensures responsible deployment, and compounds organizational intelligence.

## Strategic themes

1. **Platform-first** — Shared MLOps and GenAI infrastructure
2. **Use-case driven** — Prioritize high-value, governed use cases
3. **Responsible by design** — Ethics, security, and observability built in
4. **Agentic future** — Human-in-the-loop multi-agent workflows

## Related

- [Agentic AI Hub](../../hubs/Agentic_AI_Hub.md)
- [AI Transformation Strategy](AI_Transformation_Strategy.md)
"@
    "23_Transformation_Roadmaps/23.01_Overview/Enterprise_Transformation_Playbook.md" = @"
# Enterprise Transformation Playbook

## Context

This playbook guides leaders through assessing current state, defining target architecture, prioritizing initiatives, and realizing value across multi-year transformation programs.

## Phases

| Phase | Activities | Outputs |
| --- | --- | --- |
| 1. Assess | Capability and maturity assessment | Current state baseline |
| 2. Define | Target state and gap analysis | Transformation roadmap |
| 3. Execute | Wave-based delivery | Platforms, products, practices |
| 4. Realize | Value tracking and optimization | OKR progress, ROI |

## Governance

- Transformation control tower for portfolio oversight
- Architecture review board for technology decisions
- Domain product councils for data mesh execution

## Related

- [Transformation Framework](../23.03_Transformation_Framework/Transformation_Framework.md)
- [Gap Assessment](../23.06_Gap_Assessment/Gap_Assessment.md)
"@
    "23_Transformation_Roadmaps/23.12_Data_Mesh_Transformation/Data_Mesh_Transformation.md" = @"
# Data Mesh Transformation

## Context

Data mesh transformation shifts from centralized data ownership to domain-oriented data products with federated governance.

## Transformation waves

1. **Foundation** — Identify domains, define standards, launch platform
2. **Pilot domains** — 2–3 domains publish first data products
3. **Scale** — Marketplace, certification, federated governance
4. **Optimize** — Metrics, FinOps, AI-ready products

## Success criteria

- Domain teams own data product SLAs
- Federated governance council operational
- Self-serve platform adoption > 70%

## Related

- [Data Mesh Hub](../../hubs/Data_Mesh_Hub.md)
- [Mesh Implementation Roadmap](../../09_Data_Mesh_And_Domain_Architecture/09.23_Mesh_Implementation_Roadmap/Mesh_Implementation_Roadmap.md)
"@
    "23_Transformation_Roadmaps/23.10_AI_Transformation_Roadmaps/Enterprise_AI_Transformation.md" = @"
# Enterprise AI Transformation

## Context

AI transformation progresses from isolated experiments to governed platform-scale deployment of ML, GenAI, and agentic capabilities.

## Roadmap stages

| Stage | Focus | Duration |
| --- | --- | --- |
| Experiment | Use-case discovery, POCs | 0–6 months |
| Platform | MLOps, feature store, RAG | 6–18 months |
| Scale | Production use cases, FinOps | 18–36 months |
| Agentic | Multi-agent workflows, AgentOps | 36+ months |

## Related

- [AI Platform Roadmap](AI_Platform_Roadmap.md)
- [Vector Database Selection](../../06_AI_Architecture/06.13_Generative_AI_Architecture/Vector_Database_Selection.md)
"@
}

foreach ($rel in $strategyDocs.Keys) {
    $section = ($rel -split '/')[1] -replace '^(\d{2}\.\d{2})_.*','$1'
    $title = ($rel.Split('/')[-1] -replace '\.md$','' -replace '_',' ')
    $meta = @"
---
title: $title
section: "$section"
status: complete
template: overview
last_reviewed: 2026-06-18
owner: architecture-team
tags: []
---
"@
    Write-Doc $rel $meta $strategyDocs[$rel]
}

# === ADRs ===
Adr-Doc "06_AI_Architecture/06.27_ADR/ADR_006_Vector_Database_Selection.md" "006" "Vector Database Selection for Enterprise RAG" "06.27" "Accepted" `
    "Enterprise RAG workloads require scalable vector storage with hybrid search, metadata filtering, and cloud alignment. POC evaluation compared Pinecone, Qdrant, pgvector, and cloud-native options." `
    "Adopt a tiered strategy: Pinecone or cloud-native vector search for high-scale RAG; PostgreSQL pgvector for low-volume and co-located embeddings; Weaviate where graph-like relationships matter." `
    "### Positive`n- Flexible tiering optimizes cost and latency`n- POC-validated vendor matrix`n`n### Negative`n- Multiple stores increase operational complexity`n`n### Risks`n- Skill gaps across vector technologies" `
    "| Alternative | Why not chosen |`n| --- | --- |`n| Single vendor for all | Suboptimal cost at low volumes |`n| Relational only | Latency limits at scale |"

Adr-Doc "06_AI_Architecture/06.27_ADR/ADR_012_Hybrid_Search_Reranking.md" "012" "Hybrid Search and Re-ranking for Enterprise RAG" "06.27" "Accepted" `
    "Pure vector search misses keyword matches (acronyms, SKUs). Enterprise Q&A requires higher precision than single-stage retrieval provides." `
    "Standardize on hybrid search (dense + BM25 sparse) with cross-encoder re-ranking for high-precision enterprise Q&A workloads." `
    "### Positive`n- Improved precision on enterprise corpora`n- Configurable weighting per use case`n`n### Negative`n- Added latency from re-ranking stage" `
    "| Alternative | Why not chosen |`n| Dense only | Poor on exact-match queries |`n| Sparse only | Weak semantic understanding |"

Adr-Doc "06_AI_Architecture/06.27_ADR/ADR_013_Azure_AI_Search_Retrieval.md" "013" "Azure AI Search as Default Enterprise Retrieval Engine" "06.27" "Proposed" `
    "Azure-primary enterprises need a managed retrieval service integrated with Azure OpenAI and Entra ID." `
    "Propose Azure AI Search as the default retrieval engine for Azure-aligned GenAI applications, with hybrid search and semantic ranker enabled." `
    "### Positive`n- Deep Azure ecosystem integration`n- Managed hybrid search`n`n### Negative`n- Vendor alignment risk for multi-cloud" `
    "| Alternative | Why not chosen |`n| Pinecone | Less Azure-native integration |`n| Self-hosted OpenSearch | Higher ops burden |"

Adr-Doc "03_Data_Architecture/03.24_ADR/ADR_012_pgvector_Standardization.md" "012" "PostgreSQL pgvector for Low-Volume Embeddings" "03.24" "Accepted" `
    "Many use cases embed fewer than 1M vectors and already run PostgreSQL. A separate vector database adds unnecessary cost." `
    "Standardize on PostgreSQL with pgvector extension for embeddings under 1M vectors co-located with operational or analytical relational data." `
    "### Positive`n- Reduced platform sprawl`n- Familiar ops model`n`n### Negative`n- Scale ceiling vs purpose-built vector DBs" `
    "| Alternative | Why not chosen |`n| Dedicated vector DB | Over-engineered for low volume |"

Adr-Doc "01_Enterprise_Strategy_And_Operating_Model/01.17_ADR/ADR_002_Data_Strategy.md" "002" "Enterprise Data Strategy Approach" "01.17" "Accepted" `
    "The enterprise requires a unified data strategy balancing central standards with domain autonomy." `
    "Adopt a federated data mesh strategy with enterprise-wide governance standards and domain-owned data products." `
    "### Positive`n- Aligns business and technology ownership`n- Enables self-service at scale" `
    "| Alternative | Why not chosen |`n| Centralized data lake only | Bottleneck for domain agility |"

Adr-Doc "21_Architecture_Decision_Frameworks/21.26_ADR/ADR_001_Enterprise_Decision_Framework.md" "001" "Enterprise Architecture Decision Framework" "21.26" "Accepted" `
    "Technology decisions are made inconsistently across domains without a shared framework or ADR practice." `
    "Mandate ADRs for all significant technology selections; use weighted scorecards from section 24 for vendor decisions." `
    "### Positive`n- Transparent, auditable decisions`n- Reusable evaluation patterns" `
    "| Alternative | Why not chosen |`n| Informal decisions | No institutional memory |"

# === Vendor evaluations (top 20) ===
$vendors = @(
    @("24.10_Data_Platform_Vendor_Evaluation/Snowflake_Evaluation.md", "Snowflake", "24.10", "cloud data platform",
      "Cloud-native analytics warehouse with separated storage/compute, strong SQL ecosystem, and data sharing.",
      "Elastic scale, marketplace, mature ecosystem", "Consumption cost at scale requires FinOps", "Recommended for SQL-centric analytics and governed data sharing."),
    @("24.10_Data_Platform_Vendor_Evaluation/Databricks_Evaluation.md", "Databricks", "24.10", "lakehouse platform",
      "Unified lakehouse for batch, streaming, ML, and GenAI on open table formats.",
      "Strong ML/AI integration, Delta Lake, notebooks", "Premium pricing, skill requirements", "Recommended for lakehouse-first and ML-heavy workloads."),
    @("24.14_Cloud_Vendor_Evaluation/Azure_Evaluation.md", "Microsoft Azure", "24.14", "cloud provider",
      "Hyperscale cloud with integrated data, AI, and enterprise identity services.",
      "Entra ID, Azure OpenAI, Fabric integration", "Multi-cloud complexity if Azure-primary", "Recommended for Microsoft-aligned enterprises."),
    @("24.14_Cloud_Vendor_Evaluation/AWS_Evaluation.md", "Amazon Web Services", "24.14", "cloud provider",
      "Broadest cloud service portfolio with mature data and ML services.",
      "Service breadth, market maturity", " Complexity of service selection", "Recommended as primary or secondary cloud for most enterprises."),
    @("24.14_Cloud_Vendor_Evaluation/GCP_Evaluation.md", "Google Cloud Platform", "24.14", "cloud provider",
      "Strong data analytics, BigQuery, and Vertex AI capabilities.",
      "Analytics leadership, Vertex AI", "Enterprise sales footprint varies by region", "Recommended for analytics/AI-led transformations."),
    @("24.15_AI_And_GenAI_Vendor_Evaluation/Anthropic_Evaluation.md", "Anthropic", "24.15", "GenAI LLM",
      "Claude family models for enterprise reasoning, coding, and agentic use cases.",
      "Safety focus, long context", "Ecosystem vs OpenAI", "Recommended for governed enterprise GenAI assistants."),
    @("24.15_AI_And_GenAI_Vendor_Evaluation/OpenAI_Evaluation.md", "OpenAI", "24.15", "GenAI LLM",
      "GPT models and APIs for broad GenAI applications.",
      "Largest ecosystem, tool integrations", "Data residency and policy considerations", "Recommended for rapid GenAI innovation with governance guardrails."),
    @("24.11_Data_Governance_Vendor_Evaluation/Collibra_Evaluation.md", "Collibra", "24.11", "data governance",
      "Enterprise data governance and catalog platform.",
      "Mature governance workflows", "Implementation effort", "Recommended for enterprise-wide governance programs."),
    @("24.11_Data_Governance_Vendor_Evaluation/Atlan_Evaluation.md", "Atlan", "24.11", "data catalog",
      "Active metadata and collaborative data catalog.",
      "Modern UX, active metadata", "Enterprise feature depth varies", "Recommended for data mesh and self-service catalog."),
    @("24.10_Data_Platform_Vendor_Evaluation/Confluent_Evaluation.md", "Confluent", "24.10", "streaming platform",
      "Managed Kafka and stream processing ecosystem.",
      "Kafka expertise, Flink integration", "Cost at high throughput", "Recommended for mission-critical event streaming."),
    @("24.10_Data_Platform_Vendor_Evaluation/dbt_Evaluation.md", "dbt", "24.10", "data transformation",
      "Analytics engineering transformation framework.",
      "Developer experience, testing", "Not a full pipeline orchestrator", "Recommended for warehouse-centric transformations."),
    @("24.12_Analytics_Vendor_Evaluation/Looker_Evaluation.md", "Looker", "24.12", "BI platform",
      "Semantic modeling and embedded analytics.",
      "LookML, embedded analytics", "Google ecosystem alignment", "Recommended for semantic-layer-driven BI."),
    @("24.12_Analytics_Vendor_Evaluation/Power_BI_Evaluation.md", "Power BI", "24.12", "BI platform",
      "Microsoft-integrated self-service BI.",
      "Office integration, cost", "Complex enterprise deployment", "Recommended for Microsoft-aligned analytics."),
    @("24.16_Agentic_AI_Vendor_Evaluation/LangGraph_Evaluation.md", "LangGraph", "24.16", "agent orchestration",
      "Graph-based agent workflow orchestration framework.",
      "Flexible agent graphs, LangChain ecosystem", "Operational maturity requires AgentOps", "Recommended for custom agent orchestration."),
    @("24.15_AI_And_GenAI_Vendor_Evaluation/Pinecone_Evaluation.md", "Pinecone", "24.15", "vector database",
      "Managed vector database for RAG and semantic search.",
      "Serverless, low ops", "Cost at billion-vector scale", "Recommended for fast RAG time-to-market."),
    @("24.10_Data_Platform_Vendor_Evaluation/MongoDB_Evaluation.md", "MongoDB", "24.10", "document database",
      "Document database with Atlas vector search.",
      "Flexible schema, vector search", "Not primary analytics warehouse", "Recommended for operational apps with vector needs."),
    @("24.10_Data_Platform_Vendor_Evaluation/Redis_Evaluation.md", "Redis", "24.10", "in-memory data store",
      "Low-latency cache and vector search with Redis Stack.",
      "Sub-millisecond latency", "Memory cost", "Recommended for real-time caching and low-latency vector retrieval."),
    @("24.10_Data_Platform_Vendor_Evaluation/Fivetran_Evaluation.md", "Fivetran", "24.10", "data integration",
      "Managed ELT connectors for SaaS and databases.",
      "Connector breadth, reliability", "Consumption pricing", "Recommended for SaaS ingestion standardization."),
    @("24.11_Data_Governance_Vendor_Evaluation/Informatica_Evaluation.md", "Informatica", "24.11", "data management",
      "Enterprise data integration, quality, and governance suite.",
      "Breadth, enterprise maturity", "Legacy perception, cost", "Recommended for large-scale MDM and integration programs."),
    @("24.15_AI_And_GenAI_Vendor_Evaluation/Google_AI_Evaluation.md", "Google Vertex AI", "24.15", "AI platform",
      "GCP unified ML and GenAI platform including vector search.",
      "ScaNN vector search, Gemini models", "GCP commitment required", "Recommended for GCP-aligned AI workloads.")
)

foreach ($v in $vendors) {
    $path = "24_Vendor_Evaluation_Frameworks/$($v[0])"
    Vendor-Eval $path $v[1] $v[2] $v[3] $v[4] $v[5] $v[6] $v[7]
}

Write-Host "Tier 2 authoring complete."
