#!/usr/bin/env python3
"""Scaffold 08.05 Feature Store Architecture under docs/08_MLOps_Architecture."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs/08_MLOps_Architecture/08.05_Feature_Store_Architecture"

MODULE = "08.05"
OWNER = "architecture-team"
REVIEWED = "2026-06-24"

STRUCTURE: dict[str, list[str]] = {
    "01_Fundamentals": [
        "What_Is_Feature_Store",
        "Why_Feature_Store",
        "Online_vs_Offline",
        "Training_Serving_Skew",
    ],
    "02_Core_Concepts": [
        "Entities",
        "Features",
        "Feature_Groups",
        "Feature_Sets",
        "Feature_Views",
        "Feature_Registry",
    ],
    "03_Architectural_Patterns": [
        "Batch_Feature_Store",
        "Realtime_Feature_Store",
        "Hybrid_Feature_Store",
        "Streaming_Feature_Store",
        "Data_Mesh_Feature_Store",
    ],
    "04_Storage_Architecture": [
        "BigQuery",
        "Redis",
        "Cassandra",
        "Bigtable",
        "PostgreSQL",
    ],
    "05_Feature_Engineering": [
        "Batch_Features",
        "Streaming_Features",
        "Aggregation_Patterns",
        "Time_Window_Features",
    ],
    "06_Feature_Governance": [
        "Metadata",
        "Lineage",
        "Quality",
        "Ownership",
        "Cataloging",
    ],
    "07_Cloud_Implementations": [
        "Vertex_AI_Feature_Store",
        "Feast",
        "Tecton",
        "Databricks_Feature_Store",
        "SageMaker_Feature_Store",
    ],
    "08_Enterprise_Patterns": [
        "Telecom_Use_Cases",
        "Recommendation_Engine",
        "Fraud_Detection",
        "Customer_360",
        "Churn_Prediction",
    ],
    "09_POCs_And_Benchmarking": [
        "Feast_on_GCP",
        "Feast_vs_Vertex",
        "Redis_Benchmark",
        "Bigtable_Benchmark",
    ],
    "10_Reference_Architectures": [
        "GCP_Reference",
        "AWS_Reference",
        "Azure_Reference",
        "Multi_Cloud",
    ],
}

FUNDAMENTALS_BODY: dict[str, str] = {
    "What_Is_Feature_Store": """# What Is a Feature Store

## Definition

A **feature store** is a governed platform layer that manages the **lifecycle of ML features** — from definition and engineering through offline training materialization and low-latency online serving. It provides a single contract for how features are named, versioned, computed, stored, discovered, and consumed by training and inference workloads.

The feature store sits between raw data platforms (lakehouse, warehouse, streams) and ML systems (training pipelines, model registries, serving endpoints). It ensures the **same feature logic** powers batch training and real-time prediction.

## Core responsibilities

| Responsibility | Description |
| --- | --- |
| **Feature definition** | Entities, feature groups, schemas, and transformation logic registered as reusable assets |
| **Offline store** | Historical feature values for training, backtesting, and batch scoring at scale |
| **Online store** | Low-latency key-value or wide-column lookups for inference and decisioning |
| **Point-in-time correctness** | Training datasets join features as they existed at event time, preventing leakage |
| **Discovery and reuse** | Catalog, search, and documentation so teams share features across models |
| **Governance** | Ownership, lineage, quality checks, and access control on feature assets |

## Architecture placement

```mermaid
flowchart LR
    subgraph Sources["Data Sources"]
        WH[(Warehouse / Lakehouse)]
        Stream[Event Streams]
        OLTP[(Operational DBs)]
    end

    subgraph FS["Feature Store"]
        Registry[Feature Registry]
        Transform[Feature Pipelines]
        Offline[(Offline Store)]
        Online[(Online Store)]
    end

    subgraph ML["ML Workloads"]
        Train[Training]
        Serve[Online Inference]
    end

    WH --> Transform
    Stream --> Transform
    OLTP --> Transform
    Transform --> Registry
    Transform --> Offline
    Transform --> Online
    Offline --> Train
    Online --> Serve
    Registry --> Train
    Registry --> Serve
```

## Feature store vs adjacent capabilities

| Capability | Focus | Relationship |
| --- | --- | --- |
| **Data warehouse / lakehouse** | General-purpose analytics tables | Source of truth for batch feature computation |
| **Stream processor** | Continuous event transformation | Computes real-time features pushed to online store |
| **Model registry** | Model artifacts and versions | Consumes features; does not own feature logic |
| **Vector database** | Embedding storage and similarity search | Complementary for GenAI/RAG; not a substitute for tabular features |
| **MDM / golden record** | Master entity data | Entity keys often align; feature store adds ML-specific signals |

## When to adopt

Adopt a feature store when multiple models reuse overlapping signals, training-serving consistency is hard to maintain, or feature engineering is duplicated across teams. Start with a **hybrid offline/online** pattern and expand governance as feature reuse grows.

## Related

- [Why Feature Store](Why_Feature_Store.md)
- [Online vs Offline](Online_vs_Offline.md)
- [Feature Registry](../02_Core_Concepts/Feature_Registry.md)
- [Feature Store Overview](../../01_ML_Lifecycle/Feature_Store_Overview.md)
""",
    "Why_Feature_Store": """# Why Feature Store

## Problem

Without a feature store, ML teams repeatedly rebuild the same transformations in notebooks, ad hoc SQL, and serving microservices. Training pipelines read historical snapshots while serving code recomputes features at request time — divergent logic causes **training-serving skew**, silent model degradation, and slow time-to-production for new models.

## Business drivers

| Driver | Without feature store | With feature store |
| --- | --- | --- |
| **Time to market** | Weeks to wire features per model | Hours: bind registered feature views |
| **Model quality** | Skew and leakage from inconsistent joins | Point-in-time correct training data |
| **Reuse** | Siloed feature code per squad | Shared catalog across fraud, churn, recommenders |
| **Governance** | Unknown lineage and ownership | Registered owners, SLAs, and quality gates |
| **Cost** | Duplicate batch jobs and serving compute | Centralized materialization and caching |

## Technical drivers

- **Consistent semantics**: One transformation definition for offline and online paths.
- **Low-latency serving**: Pre-materialized online features instead of on-the-fly joins at inference.
- **Reproducibility**: Versioned feature definitions tied to model training runs.
- **Operational safety**: Schema evolution, backfill, and monitoring as first-class operations.

## Anti-patterns the feature store replaces

1. **Notebook-only features** — logic never promoted to production pipelines.
2. **Serving-time mega-joins** — 50 ms budgets blown by warehouse queries per request.
3. **Copy-paste SQL** — `SUM(amount_7d)` rewritten in five repos with subtle differences.
4. **Shadow datasets** — training exports that no longer match production feature timing.

## Adoption path

| Maturity | Characteristics |
| --- | --- |
| **L1 Central catalog** | Documented features; manual pipelines |
| **L2 Offline store** | Batch materialization + point-in-time training API |
| **L3 Online store** | Real-time serving with sync from streaming/batch |
| **L4 Governed mesh** | Domain-owned feature products with platform guardrails |

## Related

- [What Is Feature Store](What_Is_Feature_Store.md)
- [Training Serving Skew](Training_Serving_Skew.md)
- [Feature Governance](../06_Feature_Governance/Ownership.md)
""",
    "Online_vs_Offline": """# Online vs Offline Feature Store

## Overview

Feature stores split storage and access patterns into **offline** (throughput-optimized, historical) and **online** (latency-optimized, current-state) tiers. Both are fed from the same feature definitions but differ in storage engine, freshness, and consumer API.

## Comparison

| Dimension | Offline store | Online store |
| --- | --- | --- |
| **Primary use** | Training, backtesting, batch scoring | Real-time inference, decision APIs |
| **Latency** | Seconds to hours (batch scans) | Milliseconds to low seconds |
| **Data volume** | Full history, partitioned by time | Latest values per entity key |
| **Access pattern** | Columnar scans, point-in-time joins | Key-value / row lookup by entity ID |
| **Typical engines** | BigQuery, Snowflake, Parquet on lake | Redis, DynamoDB, Bigtable, Cassandra |
| **Freshness** | Hourly / daily snapshots acceptable | Seconds to minutes for operational models |

## Data flow

```mermaid
flowchart TB
    subgraph Compute["Feature Computation"]
        Batch[Batch pipelines]
        Stream[Stream jobs]
    end

    subgraph Stores["Feature Stores"]
        Offline[(Offline Store)]
        Online[(Online Store)]
    end

    Batch --> Offline
    Batch -->|sync latest| Online
    Stream --> Online
    Stream -->|archive| Offline

    Offline --> Training[Training & backtest]
    Online --> Inference[Online inference]
```

## Synchronization strategies

| Strategy | Mechanism | Best when |
| --- | --- | --- |
| **Batch sync** | Scheduled job writes latest partition to online store | Features update hourly/daily |
| **Stream dual-write** | Flink/Spark Streaming updates both tiers | Near-real-time fraud, recommendations |
| **Lambda architecture** | Speed layer (stream) + batch correction | Complex aggregates with periodic reconciliation |
| **On-demand hydrate** | Online miss triggers async backfill | Sparse entity access patterns |

## Design rules

1. **Never train on online store snapshots** without point-in-time alignment — use offline history.
2. **Never recompute heavy aggregates at inference** if they already exist in the online store.
3. **Version sync jobs** alongside feature definition changes to avoid skew.
4. **Monitor lag** between stream event time and online store update time.

## Related

- [Batch Feature Store](../03_Architectural_Patterns/Batch_Feature_Store.md)
- [Realtime Feature Store](../03_Architectural_Patterns/Realtime_Feature_Store.md)
- [Hybrid Feature Store](../03_Architectural_Patterns/Hybrid_Feature_Store.md)
- [Online Feature Store](../../01_ML_Lifecycle/Online_Feature_Store.md)
- [Offline Feature Store](../../01_ML_Lifecycle/Offline_Feature_Store.md)
""",
    "Training_Serving_Skew": """# Training Serving Skew

## Definition

**Training-serving skew** occurs when the feature values or distributions seen during model training differ from those encountered at inference time. Skew degrades model accuracy, breaks monitoring assumptions, and is a leading cause of production ML incidents.

Feature stores address skew by centralizing transformation logic and providing **point-in-time correct** historical retrieval for training alongside **identical definitions** for online materialization.

## Common skew sources

| Source | Training behavior | Serving behavior | Mitigation |
| --- | --- | --- | --- |
| **Different code paths** | SQL in training notebook | Python microservice at inference | Single registered transformation in feature store |
| **Temporal leakage** | Future data included in joins | Only past data available live | Point-in-time joins from offline store |
| **Aggregation window mismatch** | `7d` window computed on batch schedule | Window reset at midnight UTC vs local | Shared window definitions; explicit event time |
| **Missing defaults** | Null filled with training-set median | Null passed through | Centralized imputation policy in feature view |
| **Schema drift** | Old column name in historical export | Renamed column in serving API | Versioned feature groups + compatibility checks |
| **Sampling bias** | Training on labeled subset only | Scoring full population | Document population filters; monitor PSI |

## Point-in-time correctness

Point-in-time (PIT) joins retrieve feature values **as of each training label timestamp**, not as of export time.

```mermaid
sequenceDiagram
    participant L as Label event (t)
    participant FS as Offline Feature Store
    participant T as Training dataset

    T->>L: Sample entity + label_time = t
    T->>FS: Get features where feature_timestamp <= t
    FS-->>T: Feature vector at t
    Note over T: No future information after t
```

## Detection and monitoring

- **Population Stability Index (PSI)** on key features between training and production.
- **Feature distribution dashboards** per model version and segment.
- **Shadow scoring** — run new feature pipeline in parallel before cutover.
- **Canary deployments** with skew alarms on top features.

## Architectural guardrails

1. Register features once; generate both offline and online materialization from the same spec.
2. Block promotion of feature versions failing schema/quality checks.
3. Tie model registry entries to **feature view versions** used in training.
4. Run periodic **backtest replay** with production serving payloads.

## Related

- [Why Feature Store](Why_Feature_Store.md)
- [Feature Views](../02_Core_Concepts/Feature_Views.md)
- [Quality](../06_Feature_Governance/Quality.md)
- [Feature Quality Framework](../../01_ML_Lifecycle/Feature_Quality_Framework.md)
""",
}

TOPIC_SUMMARIES: dict[str, tuple[str, str, list[str]]] = {
    # folder/file stem -> (title, one-line definition, related stems in same module)
    "Entities": (
        "Entities",
        "Primary keys (customer, device, account) that anchor feature values in training and serving.",
        ["Features", "Feature_Groups"],
    ),
    "Features": (
        "Features",
        "Measurable attributes derived from raw data, versioned and typed for ML consumption.",
        ["Entities", "Feature_Views"],
    ),
    "Feature_Groups": (
        "Feature Groups",
        "Logical bundles of related features sharing entity, freshness, and ownership boundaries.",
        ["Feature_Sets", "Feature_Registry"],
    ),
    "Feature_Sets": (
        "Feature Sets",
        "Curated collections of features selected for a model family or use case.",
        ["Feature_Views", "Feature_Groups"],
    ),
    "Feature_Views": (
        "Feature Views",
        "Named, versioned bindings between entities, transformations, and offline/online stores.",
        ["Training_Serving_Skew", "Feature_Registry"],
    ),
    "Feature_Registry": (
        "Feature Registry",
        "Metadata catalog of definitions, schemas, owners, and deployment status for all features.",
        ["Cataloging", "Metadata"],
    ),
    "Batch_Feature_Store": (
        "Batch Feature Store",
        "Architecture where features are computed on schedule into offline storage with optional sync to online.",
        ["Batch_Features", "BigQuery"],
    ),
    "Realtime_Feature_Store": (
        "Realtime Feature Store",
        "Architecture emphasizing stream-computed features with millisecond online lookups.",
        ["Streaming_Features", "Redis"],
    ),
    "Hybrid_Feature_Store": (
        "Hybrid Feature Store",
        "Combined batch historical and real-time speed layers with reconciliation policies.",
        ["Online_vs_Offline", "Streaming_Feature_Store"],
    ),
    "Streaming_Feature_Store": (
        "Streaming Feature Store",
        "Continuous feature computation from event streams into online and archival offline stores.",
        ["Streaming_Features", "Aggregation_Patterns"],
    ),
    "Data_Mesh_Feature_Store": (
        "Data Mesh Feature Store",
        "Domain-owned feature products published via federated governance on a shared platform.",
        ["Ownership", "Cataloging"],
    ),
    "BigQuery": (
        "BigQuery (Offline Store)",
        "Columnar warehouse patterns for large-scale historical feature materialization on GCP.",
        ["GCP_Reference", "Vertex_AI_Feature_Store"],
    ),
    "Redis": (
        "Redis (Online Store)",
        "In-memory key-value patterns for sub-millisecond feature lookups at inference.",
        ["Redis_Benchmark", "Realtime_Feature_Store"],
    ),
    "Cassandra": (
        "Cassandra (Online Store)",
        "Wide-column store for high-write, geo-distributed online feature serving.",
        ["Realtime_Feature_Store"],
    ),
    "Bigtable": (
        "Bigtable (Online Store)",
        "GCP wide-column store for high-throughput, low-latency feature serving.",
        ["Bigtable_Benchmark", "GCP_Reference"],
    ),
    "PostgreSQL": (
        "PostgreSQL (Feature Metadata)",
        "Relational patterns for registry metadata, small-scale online features, and POC deployments.",
        ["Feature_Registry", "Feast"],
    ),
    "Batch_Features": (
        "Batch Features",
        "Features computed from scheduled SQL, Spark, or dbt jobs over warehouse/lake tables.",
        ["Batch_Feature_Store", "Time_Window_Features"],
    ),
    "Streaming_Features": (
        "Streaming Features",
        "Features updated continuously from Kafka, Pub/Sub, or Kinesis event streams.",
        ["Streaming_Feature_Store", "Aggregation_Patterns"],
    ),
    "Aggregation_Patterns": (
        "Aggregation Patterns",
        "Count, sum, rate, and sessionized aggregates over tumbling, sliding, and session windows.",
        ["Time_Window_Features", "Streaming_Features"],
    ),
    "Time_Window_Features": (
        "Time Window Features",
        "Rolling 1h/7d/30d metrics anchored to event time with late-data handling.",
        ["Training_Serving_Skew", "Aggregation_Patterns"],
    ),
    "Metadata": (
        "Feature Metadata",
        "Schemas, descriptions, tags, SLAs, and semantic types attached to feature assets.",
        ["Feature_Registry", "Cataloging"],
    ),
    "Lineage": (
        "Feature Lineage",
        "End-to-end traceability from source tables and streams to served feature values.",
        ["Feature_Lineage", "Quality"],
    ),
    "Quality": (
        "Feature Quality",
        "Freshness, completeness, drift, and anomaly checks on materialized features.",
        ["Feature_Quality_Framework", "Training_Serving_Skew"],
    ),
    "Ownership": (
        "Feature Ownership",
        "Domain teams accountable for definitions, SLAs, and breaking-change communication.",
        ["Data_Mesh_Feature_Store", "Cataloging"],
    ),
    "Cataloging": (
        "Feature Cataloging",
        "Discoverability, search, documentation, and consumption APIs for feature consumers.",
        ["Feature_Catalog", "Feature_Registry"],
    ),
    "Vertex_AI_Feature_Store": (
        "Vertex AI Feature Store",
        "GCP managed offline/online feature store integrated with Vertex training and prediction.",
        ["GCP_Reference", "Feast_vs_Vertex"],
    ),
    "Feast": (
        "Feast",
        "Open-source feature store with pluggable offline/online backends and registry.",
        ["Feast_on_GCP", "Feast_vs_Vertex"],
    ),
    "Tecton": (
        "Tecton",
        "Enterprise managed feature platform with declarative feature definitions and Rift compute.",
        ["Realtime_Feature_Store", "Hybrid_Feature_Store"],
    ),
    "Databricks_Feature_Store": (
        "Databricks Feature Store",
        "Unity Catalog–integrated feature store for lakehouse training and serving.",
        ["Batch_Features", "Multi_Cloud"],
    ),
    "SageMaker_Feature_Store": (
        "SageMaker Feature Store",
        "AWS managed online/offline feature store for SageMaker training and endpoints.",
        ["AWS_Reference", "Redis"],
    ),
    "Telecom_Use_Cases": (
        "Telecom Feature Store Use Cases",
        "Network quality, usage, billing, and churn features for telecom ML products.",
        ["Churn_Prediction", "Customer_360"],
    ),
    "Recommendation_Engine": (
        "Recommendation Engine Features",
        "User-item interaction, embedding, and context features for ranking models.",
        ["Streaming_Features", "Redis"],
    ),
    "Fraud_Detection": (
        "Fraud Detection Features",
        "Velocity, device fingerprint, and graph features with sub-second freshness requirements.",
        ["Realtime_Feature_Store", "Streaming_Features"],
    ),
    "Customer_360": (
        "Customer 360 Features",
        "Unified entity features across product, support, and marketing touchpoints.",
        ["Entities", "Data_Mesh_Feature_Store"],
    ),
    "Churn_Prediction": (
        "Churn Prediction Features",
        "Engagement decay, billing risk, and support sentiment signals for retention models.",
        ["Time_Window_Features", "Telecom_Use_Cases"],
    ),
    "Feast_on_GCP": (
        "Feast on GCP POC",
        "Proof-of-concept patterns for Feast with BigQuery offline and Redis/Bigtable online.",
        ["Feast", "GCP_Reference"],
    ),
    "Feast_vs_Vertex": (
        "Feast vs Vertex AI Feature Store",
        "Comparison of open-source flexibility versus managed GCP integration and operations.",
        ["Feast", "Vertex_AI_Feature_Store"],
    ),
    "Redis_Benchmark": (
        "Redis Online Store Benchmark",
        "Latency, memory, and throughput benchmarks for Redis feature serving tiers.",
        ["Redis", "Realtime_Feature_Store"],
    ),
    "Bigtable_Benchmark": (
        "Bigtable Online Store Benchmark",
        "Read/write scalability benchmarks for Bigtable-backed online features.",
        ["Bigtable", "GCP_Reference"],
    ),
    "GCP_Reference": (
        "GCP Feature Store Reference Architecture",
        "End-to-end GCP reference: BigQuery, Dataflow, Vertex Feature Store, and monitoring.",
        ["Vertex_AI_Feature_Store", "Feast_on_GCP"],
    ),
    "AWS_Reference": (
        "AWS Feature Store Reference Architecture",
        "End-to-end AWS reference: Glue, SageMaker Feature Store, DynamoDB/ElastiCache online tier.",
        ["SageMaker_Feature_Store"],
    ),
    "Azure_Reference": (
        "Azure Feature Store Reference Architecture",
        "Azure patterns with Synapse/Fabric offline and Cosmos/Redis online options.",
        ["Batch_Feature_Store"],
    ),
    "Multi_Cloud": (
        "Multi-Cloud Feature Store",
        "Federated feature platforms spanning clouds with consistent registry and mesh governance.",
        ["Data_Mesh_Feature_Store", "Ownership"],
    ),
}


def title_from_stem(stem: str) -> str:
    return stem.replace("_", " ")


def section_id(folder: str, index: int) -> str:
    folder_num = folder.split("_")[0]
    return f"{MODULE}.{folder_num}.{index:02d}"


def front_matter(title: str, section: str, tags: list[str], template: str = "concept") -> str:
    tag_line = ", ".join(tags)
    return f"""---
title: {title}
section: "{section}"
status: stub
template: {template}
last_reviewed: {REVIEWED}
owner: {OWNER}
tags: [{tag_line}]
canonical: true
---
"""


def numbered_filename(folder: str, stem: str) -> str:
    idx = STRUCTURE[folder].index(stem) + 1
    return f"{idx:02d}_{stem}.md"


def link_path(folder: str, target_folder: str, stem: str) -> str:
    name = numbered_filename(target_folder, stem)
    if folder == target_folder:
        return name
    return f"../{target_folder}/{name}"


def concept_body(stem: str, folder: str) -> str:
    if stem in FUNDAMENTALS_BODY:
        return FUNDAMENTALS_BODY[stem]

    title, definition, related_stems = TOPIC_SUMMARIES.get(
        stem,
        (title_from_stem(stem), f"Architecture guidance for {title_from_stem(stem).lower()}.", []),
    )

    related_links = []
    for rel in related_stems:
        for f, files in STRUCTURE.items():
            if rel in files:
                rel_path = link_path(folder, f, rel)
                related_links.append(f"- [{title_from_stem(rel)}]({rel_path})")
                break
        else:
            legacy = {
                "Feature_Lineage": "../../01_ML_Lifecycle/Feature_Lineage.md",
                "Feature_Catalog": "../../01_ML_Lifecycle/Feature_Catalog.md",
                "Feature_Quality_Framework": "../../01_ML_Lifecycle/Feature_Quality_Framework.md",
            }
            if rel in legacy:
                related_links.append(f"- [{title_from_stem(rel)}]({legacy[rel]})")

    related_block = "\n".join(related_links) if related_links else "- [What Is Feature Store](../01_Fundamentals/01_What_Is_Feature_Store.md)"

    return f"""# {title}

## Context

{definition} This topic is part of **{MODULE} Feature Store Architecture** under `{folder}`.

## Scope

| In scope | Out of scope |
| --- | --- |
| Architectural patterns, integration points, and enterprise design choices | Vendor pricing, license negotiations, and hands-on CLI tutorials |
| How this capability fits offline/online feature lifecycles | Individual model hyperparameter tuning |
| Governance, security, and operational considerations | One-off notebook experiments without platform promotion |

## Key design considerations

- Align **entity keys** and **event time** semantics with upstream data products.
- Define **freshness SLAs** and monitoring for materialization jobs affecting this area.
- Plan **schema evolution** and backward-compatible feature view versions.
- Document **ownership** and escalation paths for production incidents.
- Validate **training-serving consistency** when promoting feature changes.

## Architecture notes

```mermaid
flowchart LR
    Sources[Data Sources] --> Transform[Feature Pipelines]
    Transform --> Offline[(Offline Store)]
    Transform --> Online[(Online Store)]
    Registry[Feature Registry] --> Transform
    Offline --> Training[Training]
    Online --> Serving[Inference]
```

Extend this diagram for `{title}`-specific components, storage engines, and control-plane integrations as the topic is elaborated.

## Related

{related_block}
"""


def write_readme() -> None:
    rows = []
    for folder, files in STRUCTURE.items():
        num = folder.split("_")[0]
        key_doc = numbered_filename(folder, files[0])
        rows.append(
            f"| {MODULE}.{num} | {folder.replace('_', ' ')} | {len(files)} | "
            f"[{title_from_stem(files[0])}]({folder}/{key_doc}) | stub |"
        )

    content = f"""---
title: README
section: "{MODULE}"
status: stub
template: overview
last_reviewed: {REVIEWED}
owner: {OWNER}
tags: [mlops, feature-store, ml]
canonical: true
---

# {MODULE} Feature Store Architecture

> Status: 0 complete / 0 draft / 0 review / {sum(len(v) for v in STRUCTURE.values())} stub ({sum(len(v) for v in STRUCTURE.values())} topics)

## Purpose

Centralized architecture for ML **feature stores**: definitions, offline/online storage, engineering patterns, governance, cloud implementations, enterprise use cases, POCs, and reference designs.

## Start here

- [What Is Feature Store](01_Fundamentals/01_What_Is_Feature_Store.md)
- [Why Feature Store](01_Fundamentals/02_Why_Feature_Store.md)
- [Online vs Offline](01_Fundamentals/03_Online_vs_Offline.md)
- [Training Serving Skew](01_Fundamentals/04_Training_Serving_Skew.md)
- [Feature Registry](02_Core_Concepts/06_Feature_Registry.md)
- [Hybrid Feature Store](03_Architectural_Patterns/03_Hybrid_Feature_Store.md)
- [GCP Reference Architecture](10_Reference_Architectures/01_GCP_Reference.md)

## Subsections

| # | Topic | Topics | Key doc | Status |
| --- | --- | ---: | --- | --- |
{chr(10).join(rows)}

## Related

- [08 MLOps Architecture](../README.md)
- [Feature Store Overview](../01_ML_Lifecycle/Feature_Store_Overview.md)
- [Online Feature Store](../01_ML_Lifecycle/Online_Feature_Store.md)
- [Offline Feature Store](../01_ML_Lifecycle/Offline_Feature_Store.md)
- [Feature Engineering Framework](../01_ML_Lifecycle/Feature_Engineering_Framework.md)
"""
    (ROOT / "README.md").write_text(content, encoding="utf-8")


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    write_readme()

    for folder, files in STRUCTURE.items():
        folder_path = ROOT / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        for idx, stem in enumerate(files, start=1):
            title = title_from_stem(stem)
            tags = ["feature-store", "mlops", folder.split("_", 1)[-1].lower().replace("_", "-")]
            template = "overview" if folder == "01_Fundamentals" else "concept"
            status_content = "complete" if folder == "01_Fundamentals" else "stub"
            body = concept_body(stem, folder)
            fm = front_matter(title, section_id(folder, idx), tags, template)
            fm = fm.replace("status: stub", f"status: {status_content}")
            path = folder_path / numbered_filename(folder, stem)
            path.write_text(fm + body, encoding="utf-8")
            print(f"Wrote {path.relative_to(ROOT.parents[1])}")

    print(f"\nDone: {sum(len(v) for v in STRUCTURE.values())} topics + README")


if __name__ == "__main__":
    main()
