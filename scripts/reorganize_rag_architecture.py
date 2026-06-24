#!/usr/bin/env python3
"""Reorganize and expand docs/07_AI_Data_Architecture/03_RAG into numbered sections."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RAG = REPO / "docs/07_AI_Data_Architecture/03_RAG"
MODULE = "07.03"
REVIEWED = "2026-06-24"
OWNER = "architecture-team"

# folder -> list of (new_numbered_stem, old_flat_filename or None for new)
STRUCTURE: dict[str, list[tuple[str, str | None]]] = {
    "01_Fundamentals": [
        ("01_What_Is_RAG", None),
        ("02_RAG_Architecture_Overview", "RAG_Architecture_Overview.md"),
        ("03_Retrieval_Augmented_Generation_Pattern", "Retrieval_Augmented_Generation_Pattern.md"),
        ("04_RAG_vs_Fine_Tuning", None),
        ("05_Context_Engineering", "Context_Engineering.md"),
    ],
    "02_Ingestion_And_Parsing": [
        ("01_Document_Parsing", "Document_Parsing.md"),
        ("02_Data_Cleaning", "Data_Cleaning.md"),
        ("03_Metadata_Extraction", "Metadata_Extraction.md"),
    ],
    "03_Chunking_And_Embedding": [
        ("01_Chunking_Strategies", "Chunking_Strategies.md"),
        ("02_Embedding_Models", "Embedding_Models.md"),
    ],
    "04_Vector_Storage": [
        ("01_Vector_Database_Architecture", "Vector_Database_Architecture.md"),
        ("02_Vector_Database_Selection", "Vector_Database_Selection.md"),
    ],
    "05_Retrieval_And_Ranking": [
        ("01_Retrieval_Mechanisms", "Retrieval_Mechanisms.md"),
        ("02_Query_Transformation_And_Reranking", None),
    ],
    "06_Generation_And_Prompting": [
        ("01_Prompt_Engineering_Framework", "Prompt_Engineering_Framework.md"),
        ("02_LLM_Architecture", "LLM_Architecture.md"),
        ("03_Multi_LLM_Architecture", "Multi_LLM_Architecture.md"),
    ],
    "07_Orchestration_And_Pipelines": [
        ("01_Data_Pipelines", "Data_Pipelines.md"),
        ("02_Incremental_And_Streaming_Ingestion", None),
    ],
    "08_Enterprise_Platform": [
        ("01_RAG_Architecture", "RAG_Architecture.md"),
        ("02_GenAI_Framework", "GenAI_Framework.md"),
        ("03_GenAI_Governance", "GenAI_Governance.md"),
        ("04_Enterprise_GenAI_Platform", "Enterprise_GenAI_Platform.md"),
        ("05_Enterprise_Copilot_Architecture", "Enterprise_Copilot_Architecture.md"),
        ("06_Fine_Tuning_Architecture", "Fine_Tuning_Architecture.md"),
    ],
    "09_Evaluation_And_Quality": [
        ("01_RAG_Evaluation_Framework", None),
        ("02_Grounding_And_Faithfulness", None),
        ("03_Hallucination_Mitigation", None),
    ],
    "10_Reference_Architectures": [
        ("01_GCP_RAG_Reference", None),
        ("02_AWS_RAG_Reference", None),
        ("03_Azure_RAG_Reference", None),
        ("04_Agentic_RAG_Architecture", None),
        ("05_Graph_RAG_Architecture", None),
    ],
}

NEW_CONTENT: dict[str, str] = {
    "01_What_Is_RAG": """# What Is RAG

## Definition

**Retrieval-Augmented Generation (RAG)** is an architecture pattern that grounds large language model (LLM) responses in **retrieved enterprise knowledge** rather than model weights alone. At query time, the system searches a curated corpus (vector index, keyword index, or hybrid), injects the top-ranked passages into the prompt, and asks the LLM to answer using that evidence.

RAG reduces hallucinations, enables answers on private and fresh data, and provides **citable context** for governance and audit.

## Core flow

```mermaid
flowchart LR
    Q[User query] --> QT[Query processing]
    QT --> R[Retrieve top-k chunks]
    R --> V[(Vector / keyword index)]
    V --> C[Assemble context]
    C --> P[Prompt + LLM]
    P --> A[Grounded answer]
```

## RAG vs alternatives

| Approach | Strengths | Weaknesses | Best when |
| --- | --- | --- | --- |
| **RAG** | Fresh data, citations, lower training cost | Retrieval quality bounds answers | Enterprise Q&A, copilots, support |
| **Fine-tuning** | Style, task format, domain tone | Expensive refresh; private data in weights | Stable task with fixed knowledge |
| **Prompt-only** | Fastest to prototype | No private corpus; stale knowledge | Generic tasks, public knowledge |
| **Tool / agent APIs** | Live systems, actions | Higher latency and orchestration cost | Transactional workflows |

## Enterprise capabilities

- **Ingestion pipeline**: Parse, clean, chunk, embed, and index documents with metadata and ACLs.
- **Retrieval stack**: Dense, sparse, hybrid search, reranking, and query transformation.
- **Generation controls**: Prompt templates, citation requirements, safety filters.
- **Evaluation**: Grounding, faithfulness, latency, and cost per query.
- **Governance**: Source lineage, PII handling, retention, and access policies.

## Related

- [RAG Architecture Overview](02_RAG_Architecture_Overview.md)
- [Retrieval Augmented Generation Pattern](03_Retrieval_Augmented_Generation_Pattern.md)
- [Data Pipelines](../07_Orchestration_And_Pipelines/01_Data_Pipelines.md)
""",
    "02_RAG_Architecture_Overview": """# RAG Architecture Overview

## Context

Enterprise RAG platforms connect **authoritative data sources** to **consumption surfaces** (chat copilots, APIs, agents) through a repeatable ingestion-to-inference pipeline. This overview defines the canonical layers and control points architects must design explicitly.

## Layered architecture

```mermaid
flowchart TB
    subgraph Sources["Knowledge Sources"]
        Docs[Documents and wikis]
        DB[(Operational DBs)]
        Tickets[Tickets and CRM]
    end

    subgraph Ingestion["Ingestion and indexing"]
        Parse[Parse and clean]
        Chunk[Chunk]
        Embed[Embed]
        Index[(Vector + metadata index)]
    end

    subgraph Serving["Query serving"]
        Query[Query transform]
        Retrieve[Retrieve + rerank]
        Generate[LLM generation]
    end

    subgraph Controls["Platform controls"]
        Gov[Governance and ACLs]
        Eval[Evaluation and monitoring]
    end

    Docs --> Parse
    DB --> Parse
    Tickets --> Parse
    Parse --> Chunk --> Embed --> Index
    Query --> Retrieve --> Index
    Retrieve --> Generate
    Gov --> Ingestion
    Gov --> Serving
    Eval --> Serving
```

## Layer responsibilities

| Layer | Responsibility | Key topics |
| --- | --- | --- |
| **Sources** | Authoritative content with ownership and freshness SLAs | SharePoint, Confluence, S3, APIs |
| **Ingestion** | Parse → clean → chunk → embed → index with lineage | [Document Parsing](../02_Ingestion_And_Parsing/01_Document_Parsing.md), [Chunking](../03_Chunking_And_Embedding/01_Chunking_Strategies.md) |
| **Storage** | Vector DB + metadata filters + optional keyword index | [Vector Database Architecture](../04_Vector_Storage/01_Vector_Database_Architecture.md) |
| **Retrieval** | Recall + precision via hybrid search and reranking | [Retrieval Mechanisms](../05_Retrieval_And_Ranking/01_Retrieval_Mechanisms.md) |
| **Generation** | Prompting, citations, multi-LLM routing | [Prompt Engineering](../06_Generation_And_Prompting/01_Prompt_Engineering_Framework.md) |
| **Orchestration** | Batch, incremental, and streaming refresh | [Data Pipelines](../07_Orchestration_And_Pipelines/01_Data_Pipelines.md) |
| **Governance** | Security, compliance, cost | [GenAI Governance](../08_Enterprise_Platform/03_GenAI_Governance.md) |

## Non-functional requirements

| NFR | Design implication |
| --- | --- |
| **Freshness** | Incremental indexing, CDC, webhook triggers |
| **Latency** | Cached embeddings, reranker budget, smaller context windows |
| **Accuracy** | Chunking quality, hybrid retrieval, evaluation gates |
| **Security** | Document-level ACLs enforced at retrieval time |
| **Cost** | Embedding batching, index tiering, query caching |

## Related

- [What Is RAG](01_What_Is_RAG.md)
- [Enterprise GenAI Platform](../08_Enterprise_Platform/04_Enterprise_GenAI_Platform.md)
- [GCP RAG Reference](../10_Reference_Architectures/01_GCP_RAG_Reference.md)
""",
    "03_Retrieval_Augmented_Generation_Pattern": """# Retrieval Augmented Generation Pattern

## Pattern intent

The **RAG pattern** separates **knowledge storage** from **reasoning**. Knowledge lives in searchable indexes built from enterprise corpora; the LLM performs language understanding and synthesis over retrieved evidence at request time.

## Pattern structure

| Role | Component | Failure mode if weak |
| --- | --- | --- |
| **Knowledge plane** | Parsed chunks + embeddings + metadata | Irrelevant or stale context |
| **Retrieval plane** | Search, filter, rerank | Missed documents (low recall) or noise (low precision) |
| **Generation plane** | LLM + prompt + guardrails | Hallucination despite good retrieval |
| **Feedback plane** | Evals, thumbs, logging | Silent quality regression |

## Variants

| Variant | Description | When to use |
| --- | --- | --- |
| **Naive RAG** | Single embedding search → prompt | POCs, small corpora |
| **Advanced RAG** | Query rewrite, hybrid search, rerank, compression | Production enterprise search |
| **Modular RAG** | Swappable parsers, retrievers, generators | Multi-tenant platforms |
| **Agentic RAG** | Agent plans retrieval steps and tool calls | Multi-hop research, complex tasks |
| **Graph RAG** | Knowledge graph + vector retrieval | Entity-heavy domains |

```mermaid
flowchart TB
    subgraph Naive["Naive RAG"]
        n1[Query] --> n2[Vector search] --> n3[LLM]
    end
    subgraph Advanced["Advanced RAG"]
        a1[Query] --> a2[Rewrite]
        a2 --> a3[Hybrid search]
        a3 --> a4[Rerank]
        a4 --> a5[LLM + cite]
    end
```

## Design rules

1. **Retrieve before generate** — never rely on the model to recall private facts from weights.
2. **Enforce ACLs at retrieval** — filter by user identity and document permissions.
3. **Measure retrieval separately** from generation quality (hit rate, MRR, nDCG).
4. **Version indexes** with embedding model and chunking policy changes.
5. **Prefer citations** in user-facing answers for auditability.

## Related

- [Retrieval Mechanisms](../05_Retrieval_And_Ranking/01_Retrieval_Mechanisms.md)
- [Agentic RAG Architecture](../10_Reference_Architectures/04_Agentic_RAG_Architecture.md)
- [RAG vs Fine Tuning](04_RAG_vs_Fine_Tuning.md)
""",
    "04_RAG_vs_Fine_Tuning": """# RAG vs Fine Tuning

## Decision summary

| Criterion | Prefer RAG | Prefer fine-tuning |
| --- | --- | --- |
| Knowledge changes frequently | Yes | No |
| Need citations to source documents | Yes | Rarely |
| Strict data residency in weights | No | Requires controls |
| Specialized output format / tone | Partial (prompting) | Yes |
| Limited labeled examples | Yes | Needs quality dataset |
| Latency-sensitive Q&A on large corpus | Yes (with good index) | Model size dependent |

## Combined pattern

Most enterprises use **RAG for knowledge** and **light fine-tuning or adapters** for task format, tool-use style, or brand voice — not for storing the entire policy library in weights.

```mermaid
flowchart LR
    Corpus[Enterprise corpus] --> RAG[RAG index]
    RAG --> LLM[Fine-tuned or base LLM]
    LLM --> Answer[Task-specific answer]
```

## Governance implications

- **RAG**: Access control follows document ACLs; deletion propagates via re-indexing.
- **Fine-tuning**: Training data mix must be audited; model artifacts versioned and approved.

## Related

- [What Is RAG](01_What_Is_RAG.md)
- [Fine Tuning Architecture](../08_Enterprise_Platform/06_Fine_Tuning_Architecture.md)
- [RAG Evaluation Framework](../09_Evaluation_And_Quality/01_RAG_Evaluation_Framework.md)
""",
    "05_Context_Engineering": """# Context Engineering

## Definition

**Context engineering** is the discipline of designing **what information** enters the LLM prompt — retrieved chunks, system instructions, tool outputs, conversation history, and metadata — within fixed context window limits while maximizing answer quality.

In RAG systems, context engineering spans **retrieval selection**, **ordering**, **compression**, and **prompt structure**.

## Context budget

| Segment | Typical share | Notes |
| --- | --- | --- |
| System instructions | 5–15% | Policies, tone, citation rules |
| Retrieved evidence | 50–70% | Top-k chunks after rerank |
| Conversation history | 10–25% | Truncate or summarize older turns |
| User query | 5–10% | May include rewritten sub-queries |

## Techniques

| Technique | Purpose |
| --- | --- |
| **Reranking** | Put best chunks first (lost-in-the-middle mitigation) |
| **Contextual compression** | Summarize chunks before injection |
| **Parent-document retrieval** | Small chunk search, large parent for generation |
| **Metadata filtering** | Restrict by product, region, date, classification |
| **Citation scaffolding** | Force chunk IDs in prompt for traceable answers |

## Anti-patterns

- Stuffing maximum tokens with low-scoring retrieval results.
- Mixing conflicting chunks without ranking or deduplication.
- Omitting retrieval metadata the model needs for disambiguation.

## Related

- [Chunking Strategies](../03_Chunking_And_Embedding/01_Chunking_Strategies.md)
- [Query Transformation and Reranking](../05_Retrieval_And_Ranking/02_Query_Transformation_And_Reranking.md)
- [Prompt Engineering Framework](../06_Generation_And_Prompting/01_Prompt_Engineering_Framework.md)
""",
    "01_Vector_Database_Architecture": """# Vector Database Architecture

## Role in RAG

The **vector database** (or vector-capable index) stores embedding vectors and metadata for each chunk. It supports approximate nearest neighbor (ANN) search to retrieve semantically similar content at query time, usually combined with metadata filters for security and domain scoping.

## Logical components

```mermaid
flowchart TB
    subgraph Index["Vector index"]
        Vectors[(Embedding vectors)]
        Meta[(Metadata store)]
        ANN[ANN index HNSW/IVF]
    end

  Ingest[Ingestion pipeline] --> Vectors
    Ingest --> Meta
    Vectors --> ANN
    Query[Query embedding] --> ANN
    ANN --> Results[Top-k chunk IDs]
    Meta --> Results
```

## Architecture decisions

| Decision | Options | Trade-off |
| --- | --- | --- |
| **Deployment** | Managed SaaS, self-hosted, DB extension | Ops vs control |
| **Index type** | HNSW, IVF, disk-based | Recall vs memory vs cost |
| **Hybrid search** | Native hybrid vs dual indexes | Keyword + semantic quality |
| **Multi-tenancy** | Namespace per tenant vs shared index + ACL filter | Isolation vs cost |
| **Sharding** | By collection, by tenant, by time | Scale-out strategy |

## Data model

Each indexed item typically includes:

- `chunk_id`, `document_id`, `source_uri`
- `embedding` (fixed dimension per model)
- `text` or pointer to object storage
- `metadata` — ACL, product, language, `effective_date`, `chunk_index`

## Related

- [Vector Database Selection](02_Vector_Database_Selection.md)
- [Embedding Models](../03_Chunking_And_Embedding/02_Embedding_Models.md)
- [Metadata Extraction](../02_Ingestion_And_Parsing/03_Metadata_Extraction.md)
""",
    "02_Query_Transformation_And_Reranking": """# Query Transformation and Reranking

## Context

First-stage vector retrieval optimizes for **recall** (broad candidate set). **Query transformation** and **reranking** improve **precision** so the LLM receives the most relevant evidence within a small context window.

## Pipeline stages

```mermaid
flowchart LR
    Q[User query] --> RQ[Rewrite / decompose]
    RQ --> H[Hybrid retrieval top-100]
    H --> RR[Cross-encoder rerank]
    RR --> TopK[Top 5–10 chunks]
    TopK --> LLM[Generation]
```

## Query transformation patterns

| Pattern | Description |
| --- | --- |
| **HyDE** | Generate hypothetical answer, embed it, retrieve |
| **Multi-query** | LLM produces sub-queries; union results |
| **Step-back** | Broader query + specific query combined |
| **Conversation condense** | Rewrite follow-up into standalone query |

## Reranking

Cross-encoder models score `(query, passage)` pairs with higher accuracy than bi-encoder similarity alone. Trade-off: latency and cost vs first-stage retrieval.

| Stage | Typical count | Latency budget |
| --- | --- | --- |
| First retrieval | 50–200 candidates | 20–80 ms |
| Rerank | 5–15 to LLM | 50–300 ms |

## Related

- [Retrieval Mechanisms](01_Retrieval_Mechanisms.md)
- [Context Engineering](../01_Fundamentals/05_Context_Engineering.md)
""",
    "02_Incremental_And_Streaming_Ingestion": """# Incremental and Streaming Ingestion

## Problem

Enterprise corpora change continuously. Full re-indexing is costly and causes retrieval inconsistency. RAG platforms need **incremental**, **CDC-driven**, or **event-stream** ingestion to keep indexes aligned with source systems.

## Patterns

| Pattern | Trigger | Consistency |
| --- | --- | --- |
| **Scheduled delta** | Cron compares `updated_at` | Minutes to hours lag |
| **CDC** | DB binlog / Debezium | Near-real-time |
| **Object events** | S3/GCS Pub/Sub notifications | Seconds |
| **Webhook** | CMS publish event | Seconds |
| **Tombstone deletes** | Delete events remove vectors | Required for GDPR |

```mermaid
flowchart LR
    Source[Source system] --> CDC[CDC / events]
    CDC --> Transform[Parse chunk embed]
    Transform --> Upsert[Upsert / delete vectors]
```

## Design rules

1. Propagate **document deletes** and permission revocations to the index.
2. Use **idempotent** chunk IDs (`doc_id + version + chunk_index`).
3. Run **embedding version gates** — re-embed when model changes.
4. Monitor **index lag** and **staleness SLAs** per collection.

## Related

- [Data Pipelines](01_Data_Pipelines.md)
- [Metadata Extraction](../02_Ingestion_And_Parsing/03_Metadata_Extraction.md)
""",
    "01_RAG_Evaluation_Framework": """# RAG Evaluation Framework

## Purpose

RAG quality cannot be measured by LLM loss alone. Enterprises need **retrieval metrics**, **generation metrics**, and **end-to-end** benchmarks tied to production traffic and golden question sets.

## Metric layers

| Layer | Examples | Tools |
| --- | --- | --- |
| **Retrieval** | Hit@k, MRR, nDCG, context precision | RAGAS, custom judges |
| **Generation** | Faithfulness, answer relevance, citation accuracy | LLM-as-judge, human eval |
| **System** | p95 latency, cost/query, error rate | APM, FinOps |
| **Safety** | PII leakage, policy violations | Red-team suites |

## Evaluation workflow

1. Build **golden dataset** — question, expected sources, ideal answer.
2. Run **offline eval** on each pipeline change (chunking, embed model, reranker).
3. Gate releases with minimum thresholds on faithfulness and hit rate.
4. Sample **online feedback** (thumbs, edits) into regression sets.

## Related

- [Grounding and Faithfulness](02_Grounding_And_Faithfulness.md)
- [Hallucination Mitigation](03_Hallucination_Mitigation.md)
""",
    "02_Grounding_And_Faithfulness": """# Grounding and Faithfulness

## Definitions

- **Grounding**: The answer is supported by retrieved passages.
- **Faithfulness**: The answer does not contradict or invent beyond the provided context.

## Measurement approaches

| Approach | Description |
| --- | --- |
| **Citation check** | Every claim maps to chunk ID |
| **NLI entailment** | NLI model scores answer ⊆ context |
| **LLM judge** | Rubric-scored faithfulness 1–5 |
| **Human review** | Sampled expert grading |

## Architectural controls

- Require **inline citations** in copilot UIs.
- Reject answers below faithfulness threshold; fall back to "insufficient evidence."
- Log retrieved chunk hashes with each response for audit.

## Related

- [RAG Evaluation Framework](01_RAG_Evaluation_Framework.md)
- [Context Engineering](../01_Fundamentals/05_Context_Engineering.md)
""",
    "03_Hallucination_Mitigation": """# Hallucination Mitigation

## Sources of hallucination in RAG

| Cause | Mitigation |
| --- | --- |
| Poor retrieval (empty or wrong chunks) | Hybrid search, rerank, query rewrite |
| Context overflow / lost-in-the-middle | Rerank, compress, fewer chunks |
| Model tendency to invent | Low temperature, citation-required prompts |
| Stale index | Incremental ingestion, freshness metadata |
| Ambiguous query | Clarifying questions, disambiguation metadata |

## Defense in depth

```mermaid
flowchart TB
    R[Better retrieval] --> G[Grounded generation]
    G --> V[Verification layer]
    V --> H[Human escalation]
```

## Related

- [Grounding and Faithfulness](02_Grounding_And_Faithfulness.md)
- [GenAI Governance](../08_Enterprise_Platform/03_GenAI_Governance.md)
""",
    "01_GCP_RAG_Reference": """# GCP RAG Reference Architecture

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
""",
    "02_AWS_RAG_Reference": """# AWS RAG Reference Architecture

## Overview

AWS RAG reference: **S3** sources, **Bedrock Knowledge Bases** (managed) or custom pipelines with **OpenSearch Serverless vector engine**, **Bedrock** embeddings and Claude/Titan models, **Step Functions** orchestration.

| Capability | AWS service |
| --- | --- |
| Managed RAG | Amazon Bedrock Knowledge Bases |
| Custom index | OpenSearch Serverless, Aurora pgvector |
| Embeddings / LLM | Amazon Bedrock |
| Orchestration | Step Functions, MWAA |
| Streaming ingest | Kinesis → Lambda |

## Related

- [Enterprise GenAI Platform](../08_Enterprise_Platform/04_Enterprise_GenAI_Platform.md)
""",
    "03_Azure_RAG_Reference": """# Azure RAG Reference Architecture

## Overview

Azure RAG reference: **Azure AI Search** (hybrid vector + keyword), **Azure OpenAI** embeddings and chat, **Document Intelligence** parsing, **Prompt Flow** for pipeline authoring, **Purview** for lineage.

| Capability | Azure service |
| --- | --- |
| Retrieval | Azure AI Search (vector + semantic ranker) |
| Models | Azure OpenAI |
| Parsing | Document Intelligence |
| Orchestration | Prompt Flow, Data Factory |
| Governance | Microsoft Purview |

## Related

- [Enterprise Copilot Architecture](../08_Enterprise_Platform/05_Enterprise_Copilot_Architecture.md)
""",
    "04_Agentic_RAG_Architecture": """# Agentic RAG Architecture

## Definition

**Agentic RAG** uses an LLM **agent** to plan retrieval: reformulating queries, choosing indexes, calling search tools iteratively, and synthesizing multi-hop answers. It extends naive single-shot RAG for complex research tasks.

```mermaid
flowchart TB
    Q[User goal] --> Agent[Planning agent]
    Agent --> T1[Search tool]
    Agent --> T2[SQL / API tool]
    T1 --> Index[(Indexes)]
    T2 --> Systems[Enterprise systems]
    Index --> Agent
    Systems --> Agent
    Agent --> Answer[Final answer]
```

## When to adopt

| Signal | Action |
| --- | --- |
| Single retrieval pass insufficient | Add agent loop with max steps |
| Multiple corpora / tools | Agent routing |
| Strict latency SLA | Prefer advanced RAG over agent |

## Related

- [Agentic AI Architecture](../../12_Agentic_AI_Architecture/README.md)
- [Retrieval Augmented Generation Pattern](../01_Fundamentals/03_Retrieval_Augmented_Generation_Pattern.md)
""",
    "05_Graph_RAG_Architecture": """# Graph RAG Architecture

## Definition

**Graph RAG** combines **knowledge graphs** (entities, relationships) with **vector retrieval** to answer questions requiring multi-hop reasoning over connected enterprise knowledge.

## Pattern

1. Extract entities and relations during ingestion.
2. Store graph in Neo4j, Neptune, or Spanner graph.
3. Retrieve seed nodes via vector search or keyword.
4. Expand neighborhood (k-hop) for context.
5. Inject subgraph summary + text chunks into LLM.

## Best for

- Org hierarchies, product catalogs, supply chain, telecom network inventory
- Questions like "which services depend on X affected by outage Y?"

## Related

- [Metadata Extraction](../02_Ingestion_And_Parsing/03_Metadata_Extraction.md)
- [Retrieval Mechanisms](../05_Retrieval_And_Ranking/01_Retrieval_Mechanisms.md)
""",
}


def strip_front_matter(text: str) -> str:
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            return text[end + 3 :].lstrip("\n")
    return text


def front_matter(title: str, section: str, status: str, tags: list[str], template: str = "concept") -> str:
    tag_line = ", ".join(tags)
    return f"""---
title: {title}
section: "{section}"
status: {status}
template: {template}
last_reviewed: {REVIEWED}
owner: {OWNER}
tags: [{tag_line}]
canonical: true
---
"""


def title_from_stem(stem: str) -> str:
    name = stem.split("_", 1)[-1] if stem[:2].isdigit() else stem
    return name.replace("_", " ")


def section_id(folder: str, index: int) -> str:
    folder_num = folder.split("_")[0]
    return f"{MODULE}.{folder_num}.{index:02d}"


def concept_stub(stem: str, folder: str) -> str:
    title = title_from_stem(stem)
    return f"""# {title}

## Context

Architecture guidance for **{title.lower()}** within the enterprise RAG platform (`{folder}`).

## Scope

| In scope | Out of scope |
| --- | --- |
| Design patterns and integration with the RAG pipeline | Vendor pricing negotiations |
| Governance, security, and operational considerations | Notebook-only experiments |

## Key design considerations

- Align with ingestion, retrieval, and generation SLAs.
- Enforce document-level ACLs and lineage.
- Version embedding and chunking policies with indexes.
- Measure retrieval and faithfulness before production promotion.

## Related

- [RAG Architecture Overview](../01_Fundamentals/02_RAG_Architecture_Overview.md)
- [What Is RAG](../01_Fundamentals/01_What_Is_RAG.md)
"""


def write_readme() -> None:
    rows = []
    total = 0
    for folder, items in STRUCTURE.items():
        num = folder.split("_")[0]
        key = items[0][0]
        total += len(items)
        rows.append(
            f"| {MODULE}.{num} | {folder.replace('_', ' ')} | {len(items)} | "
            f"[{title_from_stem(key)}]({folder}/{key}.md) | — |"
        )
    content = f"""---
title: README
section: "{MODULE}"
status: stub
template: overview
last_reviewed: {REVIEWED}
owner: {OWNER}
tags: [rag, genai, retrieval]
canonical: true
---

# {MODULE} Retrieval-Augmented Generation (RAG)

> Status: see per-topic front matter ({total} topics across {len(STRUCTURE)} sections)

## Purpose

Enterprise architecture for **Retrieval-Augmented Generation**: ingestion, chunking, embeddings, vector storage, retrieval, generation, orchestration, evaluation, and reference designs on AWS, Azure, and GCP.

## Start here

- [What Is RAG](01_Fundamentals/01_What_Is_RAG.md)
- [RAG Architecture Overview](01_Fundamentals/02_RAG_Architecture_Overview.md)
- [Retrieval Augmented Generation Pattern](01_Fundamentals/03_Retrieval_Augmented_Generation_Pattern.md)
- [Document Parsing](02_Ingestion_And_Parsing/01_Document_Parsing.md)
- [Chunking Strategies](03_Chunking_And_Embedding/01_Chunking_Strategies.md)
- [Retrieval Mechanisms](05_Retrieval_And_Ranking/01_Retrieval_Mechanisms.md)
- [Data Pipelines](07_Orchestration_And_Pipelines/01_Data_Pipelines.md)
- [GCP RAG Reference](10_Reference_Architectures/01_GCP_RAG_Reference.md)

## Subsections

| # | Topic | Topics | Key doc | Status |
| --- | --- | ---: | --- | --- |
{chr(10).join(rows)}

## Related

- [07 AI Data Architecture](../README.md)
- [Agentic AI Architecture](../12_Agentic_AI_Architecture/README.md)
- [GenAI Evaluation And Observability](../10_AI_Observability/GenAI_Evaluation_And_Observability.md)
"""
    (RAG / "README.md").write_text(content, encoding="utf-8")


def main() -> None:
    staging = RAG / "_staging"
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir(parents=True)

    old_files = {p.name: p for p in RAG.glob("*.md") if p.name != "README.md"}

    for folder, items in STRUCTURE.items():
        folder_path = staging / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        for idx, (stem, old_name) in enumerate(items, start=1):
            title = title_from_stem(stem)
            sec = section_id(folder, idx)
            tags = ["rag", folder.split("_", 1)[-1].lower().replace("_", "-")]

            if stem in NEW_CONTENT:
                body = NEW_CONTENT[stem]
                status = "complete"
                template = "overview" if folder == "01_Fundamentals" else "concept"
            elif old_name and old_name in old_files:
                raw = old_files[old_name].read_text(encoding="utf-8")
                body = strip_front_matter(raw)
                status_match = re.search(r"^status: (\w+)", raw, re.MULTILINE)
                status = status_match.group(1) if status_match else "stub"
                template_match = re.search(r"^template: (\w+)", raw, re.MULTILINE)
                template = template_match.group(1) if template_match else "evaluation"
            else:
                body = concept_stub(stem, folder)
                status = "stub"
                template = "concept"

            out = folder_path / f"{stem}.md"
            out.write_text(front_matter(title, sec, status, tags, template) + body, encoding="utf-8")

    write_readme()
    # write_readme already writes to RAG/README.md

    for folder in STRUCTURE:
        dest = RAG / folder
        if dest.exists():
            shutil.rmtree(dest)
        shutil.move(str(staging / folder), str(dest))

    shutil.rmtree(staging)

    for name, path in old_files.items():
        path.unlink()

    print(f"Reorganized {RAG.relative_to(REPO)} into {len(STRUCTURE)} sections.")


if __name__ == "__main__":
    main()
