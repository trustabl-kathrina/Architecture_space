---
title: Agentic RAG Architecture
section: "07.03.10.04"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, reference-architectures]
canonical: true
---
# Agentic RAG Architecture

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
