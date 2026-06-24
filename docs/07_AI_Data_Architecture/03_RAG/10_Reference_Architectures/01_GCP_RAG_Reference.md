---
title: GCP RAG Reference
section: "07.03.10.01"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, reference-architectures]
canonical: true
---
# GCP RAG Reference Architecture

## Overview

Canonical GCP stack for enterprise RAG: **Document AI** and **Cloud Storage** for ingestion, **Vertex AI** embeddings and models, **Vertex AI Vector Search** (or AlloyDB pgvector) for retrieval, **Cloud Run / GKE** for orchestration.

```mermaid
flowchart TB
    GCS[Cloud Storage / Drive] --> DocAI[Document AI]
    DocAI --> Pipeline[Dataflow / Composer DAG]
    Pipeline --> Embed[Vertex embeddings]
    Embed --> VS[Vertex Vector Search]
    User[User / App] --> CR[Cloud Run RAG API]
    CR --> VS
    CR --> Gemini[Gemini on Vertex]
```

## Component map

| Capability | GCP service |
| --- | --- |
| Parsing | Document AI, Unstructured on GCE |
| Orchestration | Cloud Composer, Workflows |
| Embeddings | `text-embedding` models on Vertex |
| Vector index | Vertex AI Vector Search |
| Generation | Gemini 1.5+ on Vertex |
| Governance | VPC-SC, CMEK, IAM, Model Garden policies |

## Related

- [RAG Architecture Overview](../01_Fundamentals/02_RAG_Architecture_Overview.md)
- [Data Pipelines](../07_Orchestration_And_Pipelines/01_Data_Pipelines.md)
