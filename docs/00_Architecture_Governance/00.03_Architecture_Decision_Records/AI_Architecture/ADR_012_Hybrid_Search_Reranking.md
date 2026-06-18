---
title: ADR 012 Hybrid Search and Re-ranking for Enterprise RAG
section: "00.03"
status: complete
template: adr
last_reviewed: 2026-06-18
owner: architecture-team
tags: [adr]
canonical: true
---
# ADR-012: Hybrid Search and Re-ranking for Enterprise RAG

## Status

Accepted

## Date

2026-06-18

## Context

Pure vector search misses keyword matches (acronyms, SKUs). Enterprise Q&A requires higher precision than single-stage retrieval provides.

## Decision

Standardize on hybrid search (dense + BM25 sparse) with cross-encoder re-ranking for high-precision enterprise Q&A workloads.

## Consequences

### Positive
- Improved precision on enterprise corpora
- Configurable weighting per use case

### Negative
- Added latency from re-ranking stage

## Alternatives considered

| Alternative | Why not chosen |
| Dense only | Poor on exact-match queries |
| Sparse only | Weak semantic understanding |
