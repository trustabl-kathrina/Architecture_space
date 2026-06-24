---
title: Query Transformation And Reranking
section: "07.03.05.02"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, retrieval-and-ranking]
canonical: true
---
# Query Transformation and Reranking

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
