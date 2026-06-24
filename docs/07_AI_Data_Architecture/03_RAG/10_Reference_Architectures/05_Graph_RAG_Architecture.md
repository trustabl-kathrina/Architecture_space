---
title: Graph RAG Architecture
section: "07.03.10.05"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, reference-architectures]
canonical: true
---
# Graph RAG Architecture

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
