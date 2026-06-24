---
title: Context Engineering
section: "07.03.01.05"
status: complete
template: overview
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, fundamentals]
canonical: true
---
# Context Engineering

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
