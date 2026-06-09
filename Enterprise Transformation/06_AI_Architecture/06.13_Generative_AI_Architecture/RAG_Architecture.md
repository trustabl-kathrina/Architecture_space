# RAG (Retrieval-Augmented Generation) Architecture

## Overview
RAG is the enterprise standard for grounding Large Language Models (LLMs) in proprietary business data, reducing hallucinations, and ensuring data privacy.

## Architectural Components

### 1. Data Ingestion & Chunking
- Documents (PDFs, Confluence, DB records) are ingested.
- Text is split into semantic chunks to optimize context window limits.

### 2. Embedding Model
- Transforms chunks into high-dimensional vector representations.
- e.g., OpenAI `text-embedding-3-small`, Cohere Embed.

### 3. Vector Database
- Stores embeddings and metadata for fast similarity search.
- e.g., Pinecone, Milvus, Qdrant.

### 4. Retrieval & Ranking
- User query is embedded.
- Vector DB returns Top-K most similar chunks.
- Optional: Cross-encoder re-ranking for higher precision.

### 5. Generation (LLM)
- The retrieved context is injected into the prompt alongside the user query.
- The LLM generates a grounded response, citing the source chunks.
