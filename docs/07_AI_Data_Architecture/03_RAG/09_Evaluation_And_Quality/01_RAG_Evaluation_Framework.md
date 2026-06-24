---
title: RAG Evaluation Framework
section: "07.03.09.01"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, evaluation-and-quality]
canonical: true
---
# RAG Evaluation Framework

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
