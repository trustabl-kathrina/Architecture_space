---
title: Azure RAG Reference
section: "07.03.10.03"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, reference-architectures]
canonical: true
---
# Azure RAG Reference Architecture

## Overview

Azure RAG reference: **Azure AI Search** (hybrid vector + keyword), **Azure OpenAI** embeddings and chat, **Document Intelligence** parsing, **Prompt Flow** for pipeline authoring, **Purview** for lineage.

| Capability | Azure service |
| --- | --- |
| Retrieval | Azure AI Search (vector + semantic ranker) |
| Models | Azure OpenAI |
| Parsing | Document Intelligence |
| Orchestration | Prompt Flow, Data Factory |
| Governance | Microsoft Purview |

## Related

- [Enterprise Copilot Architecture](../08_Enterprise_Platform/05_Enterprise_Copilot_Architecture.md)
