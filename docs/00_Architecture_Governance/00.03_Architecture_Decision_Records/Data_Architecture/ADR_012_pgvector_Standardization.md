---
title: ADR 012 PostgreSQL pgvector for Low-Volume Embeddings
section: "00"
status: complete
template: adr
last_reviewed: 2026-06-18
owner: architecture-team
tags: [adr]
canonical: true
---

# ADR-012: PostgreSQL pgvector for Low-Volume Embeddings

## Status

Accepted

## Date

2026-06-18

## Context

Many use cases embed fewer than 1M vectors and already run PostgreSQL. A separate vector database adds unnecessary cost.

## Decision

Standardize on PostgreSQL with pgvector extension for embeddings under 1M vectors co-located with operational or analytical relational data.

## Consequences

### Positive
- Reduced platform sprawl
- Familiar ops model

### Negative
- Scale ceiling vs purpose-built vector DBs

## Alternatives considered

| Alternative | Why not chosen |
| Dedicated vector DB | Over-engineered for low volume |
