---
title: ADR 006 Vector Database Selection for Enterprise RAG
section: "00.03"
status: complete
template: adr
last_reviewed: 2026-06-18
owner: architecture-team
tags: [adr]
canonical: true
---
# ADR-006: Vector Database Selection for Enterprise RAG

## Status

Accepted

## Date

2026-06-18

## Context

Enterprise RAG workloads require scalable vector storage with hybrid search, metadata filtering, and cloud alignment. POC evaluation compared Pinecone, Qdrant, pgvector, and cloud-native options.

## Decision

Adopt a tiered strategy: Pinecone or cloud-native vector search for high-scale RAG; PostgreSQL pgvector for low-volume and co-located embeddings; Weaviate where graph-like relationships matter.

## Consequences

### Positive
- Flexible tiering optimizes cost and latency
- POC-validated vendor matrix

### Negative
- Multiple stores increase operational complexity

### Risks
- Skill gaps across vector technologies

## Alternatives considered

| Alternative | Why not chosen |
| --- | --- |
| Single vendor for all | Suboptimal cost at low volumes |
| Relational only | Latency limits at scale |
