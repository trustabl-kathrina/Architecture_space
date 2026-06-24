---
title: RAG vs Fine Tuning
section: "07.03.01.04"
status: complete
template: overview
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, fundamentals]
canonical: true
---
# RAG vs Fine Tuning

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
