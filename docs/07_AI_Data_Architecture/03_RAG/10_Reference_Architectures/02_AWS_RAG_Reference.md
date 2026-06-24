---
title: AWS RAG Reference
section: "07.03.10.02"
status: complete
template: concept
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, reference-architectures]
canonical: true
---
# AWS RAG Reference Architecture

## Overview

AWS RAG reference: **S3** sources, **Bedrock Knowledge Bases** (managed) or custom pipelines with **OpenSearch Serverless vector engine**, **Bedrock** embeddings and Claude/Titan models, **Step Functions** orchestration.

| Capability | AWS service |
| --- | --- |
| Managed RAG | Amazon Bedrock Knowledge Bases |
| Custom index | OpenSearch Serverless, Aurora pgvector |
| Embeddings / LLM | Amazon Bedrock |
| Orchestration | Step Functions, MWAA |
| Streaming ingest | Kinesis → Lambda |

## Related

- [Enterprise GenAI Platform](../08_Enterprise_Platform/04_Enterprise_GenAI_Platform.md)
