---
title: Grounding And Faithfulness
section: "07.03.09.02"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, evaluation-and-quality]
canonical: true
---
# Grounding and Faithfulness

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
