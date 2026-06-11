# 3. Chunking Strategies

## 1. Problem Statement
In Retrieval-Augmented Generation (RAG), embedding entire documents into a single vector dilutes the semantic meaning, making retrieval highly imprecise. Conversely, splitting text too aggressively destroys the context required for an LLM to generate a coherent answer. Furthermore, LLMs have strict context window limits; you cannot pass a 500-page manual into a prompt. The challenge is to implement a chunking strategy that breaks documents into optimal, semantically complete segments, balancing the precision of the vector search with the context retention needed for accurate generation. Bad chunking is the leading cause of RAG failure, resulting in "lost in the middle" phenomena and hallucinated responses.

## 2. Business Use Cases
*   **Customer Support Q&A:** Utilizing semantic chunking on FAQ documents so that an entire Q&A pair remains together in one chunk, ensuring the bot retrieves the complete answer rather than cutting off mid-sentence.
*   **Financial Report Analysis:** Employing hierarchical chunking on 10-K reports. The system retrieves specific tabular data chunks but provides the LLM with the parent section (the surrounding paragraphs) to accurately summarize financial context.
*   **Legal Contract Review:** Using structural/layout-aware chunking to ensure that specific clauses and their immediate sub-clauses are embedded together, maintaining legal context.

## 3. Architecture Pattern
Chunking sits squarely between the Parsing and Embedding phases. The standard pattern is:
1.  **Ingest & Parse:** Raw document is converted to clean text or Markdown.
2.  **Strategy Selection:** The text is routed to a specific `TextSplitter` or `NodeParser`.
3.  **Boundary Detection:** The algorithm identifies split points (e.g., characters, tokens, semantic shifts, or Markdown headers).
4.  **Overlap Application:** A sliding window (overlap) is applied to ensure context isn't lost at the hard boundaries between chunks.
5.  **Metadata Appending:** Chunks are enriched with their parent document ID, chunk index, and structural metadata before embedding.

## 4. Technology Options
*   **Fixed-Size (Character/Token) Chunking:** Splitting text by a specific number of characters or tokens, often with overlap. Simple but prone to breaking context.
*   **Sentence/Paragraph/Regex Chunking:** Splitting by natural language boundaries (periods, newlines). Preserves better local context.
*   **Structural/Markdown Chunking:** Splitting based on document hierarchy (e.g., creating a new chunk for every H2 or H3 tag).
*   **Semantic Chunking:** Advanced methods that use embedding models to calculate the distance between sentences, splitting the text only when a significant shift in topic/meaning occurs.
*   **Hierarchical/Parent-Child (Small-to-Big) Chunking:** Creating small chunks for highly precise retrieval, but returning a larger "parent" chunk (the surrounding context) to the LLM for generation.

### Table: Chunking Strategy Comparison

| Strategy | Core Concept | Semantic Preservation | Compute/Time Cost | Retrieval Precision | Context Window Efficiency | Best Use Cases |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Fixed-Size (Character/Token)** | Splits text by an exact character or token count, typically utilizing a sliding window for overlap. | Low | Low | Low to Medium | Medium (Highly predictable chunk sizes, but may include irrelevant surrounding text) | Fast baselines, simple text, budget-constrained ingestion pipelines. |
| **Sentence/Paragraph/Regex** | Splits text using natural language boundaries such as periods, newlines, or specific regex patterns. | Medium | Low | Medium | Medium to High | General text, simple articles, straightforward Q&A where local context matters. |
| **Structural/Markdown** | Splits based on the document's physical layout and logical hierarchy (e.g., H1/H2 tags, HTML structures). | High | Medium | High | High (Feeds whole logical sections to the LLM) | Well-formatted wikis, reports, legal contracts, parsed PDFs. |
| **Semantic Chunking** | Uses embedding models to calculate distance between sentences, splitting only when a significant topic shift occurs. | Best-in-class | High | High | High (Variable chunk sizes that perfectly encapsulate a single concept) | Dense manuals, complex reasoning tasks, unstructured text lacking clear formatting. |
| **Hierarchical (Small-to-Big)** | Creates small child chunks for precise vector search, but retrieves their larger parent chunk (surrounding context) for the LLM. | Best-in-class | Medium to High | Best-in-class | Best-in-class (Provides massive, highly relevant context to prevent hallucinations) | Complex enterprise Q&A, long financial/technical documents, preventing "lost in the middle". |

## 5. Cloud Native Options
*   **AWS:** **Amazon Bedrock Knowledge Bases** offers managed, automated chunking (fixed-size, default 300 tokens) natively integrated into its ingestion pipelines.
*   **Azure:** **Azure AI Search** provides native "Text Split" cognitive skills during index building, allowing for configurable token-based overlapping chunks.
*   **GCP:** **Vertex AI Vector Search** integrates with Document AI to provide out-of-the-box chunking based on document layout and paragraphs during ingestion.

## 6. Top 10 Vendor Options
1.  **LangChain RecursiveCharacterTextSplitter** (The industry standard baseline for overlapping character chunking).
2.  **LlamaIndex SentenceSplitter** (Highly reliable token-aware sentence splitting).
3.  **LlamaIndex SemanticSplitterNodeParser** (Advanced semantic boundary detection).
4.  **LlamaIndex HierarchicalNodeParser** (Native implementation of Small-to-Big retrieval).
5.  **Unstructured.io Chunking** (Structural chunking based directly on document parsing elements like `Title` and `NarrativeText`).
6.  **AI21 Studio Semantic Text Splitter** (Commercial API specialized in deeply semantic document splitting).
7.  **NLTK / spaCy Sentence Tokenizers** (Classical NLP libraries used as the underlying engine for custom chunkers).
8.  **HuggingFace Tokenizers** (Crucial for ensuring chunks perfectly match the token limits of the specific embedding model being used).
9.  **Cohere Document API** (Managed API that handles parsing and chunking optimized for their specific embedding/reranking models).
10. **ChromaDB / Pinecone Native Chunking** (Some Vector DBs are beginning to offer basic chunking functions upon data upload).

## 7. Comparison Matrix

### Table 1: Cloud Provider Evaluation Matrix

| Criteria | Amazon Bedrock Knowledge Bases | Azure AI Search (Text Split Skill) | GCP Vertex AI Search |
| :--- | :--- | :--- | :--- |
| **Strategy Support** | Fixed-size (Token based) | Fixed-size (Character/Token based) | Structural (Paragraph/Layout based via DocAI) |
| **Customization** | Low (Basic token limit and overlap settings) | Medium (Configurable limits, language specific) | Medium (Tied to Document AI extraction logic) |
| **Semantic Awareness**| Low (Rigid boundaries) | Low (Rigid boundaries) | Medium (Respects visual paragraphs) |
| **Automation** | High (Fully managed within Bedrock) | High (Runs automatically during indexer execution) | High (Managed ingestion) |
| **Latency** | Low | Low | Low |
| **Cost** | Included in Bedrock ingestion fees | Negligible (Part of AI Search indexing cost) | Included in Vertex Search/DocAI fees |

**Executive Summary: Cloud Providers**
Cloud providers currently offer highly automated but relatively basic chunking strategies. **Azure AI Search** provides the most configurable "traditional" token splitting within its indexing skills. **GCP** has a slight edge in structural awareness because it leverages Document AI to chunk by visual paragraphs. **AWS Bedrock** offers the easiest "click-and-deploy" experience but lacks advanced customization. For production enterprise RAG requiring semantic or hierarchical chunking, organizations must process data *before* it hits these native cloud ingestion endpoints using external frameworks.

### Table 2: Top Market Options Evaluation Matrix

| Criteria | LangChain Recursive Splitter | LlamaIndex Sentence Splitter | LlamaIndex Semantic Splitter | LlamaIndex Hierarchical | Unstructured.io Structural | AI21 Semantic Splitter |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Strategy Type** | Character / Recursive | Token / Sentence | Semantic / Embedding Distance | Parent-Child / Structural | Layout Element based | Semantic / ML Model |
| **Semantic Awareness**| Low (Relies on punctuation) | Low (Relies on punctuation/tokens) | Best-in-class (Uses embeddings to find topic shifts) | High (Preserves document hierarchy) | High (Understands titles vs paragraphs) | Best-in-class (Proprietary LLM routing) |
| **Speed/Latency** | Fastest (Instant) | Fast | Slow (Requires API calls to embed every sentence) | Fast | Medium (Tied to parsing speed) | Slow (API call) |
| **Accuracy / Context**| Medium (Often cuts off concepts) | Medium (Safer than character splitting) | High (Keeps topics together) | Best-in-class (Precise retrieval, massive context for LLM) | High (Keeps visual sections intact) | High |
| **Framework Integration**| Best-in-class (LangChain) | Best-in-class (LlamaIndex) | Best-in-class (LlamaIndex) | Best-in-class (LlamaIndex) | High (Supported everywhere) | Low (Requires custom API routing) |
| **Cost** | Free (OSS) | Free (OSS) | High (Requires paying for embedding API calls during chunking) | Free (OSS) | Free (OSS) | Pay-per-API call |

**Executive Summary: Market Options for RAG**
The market is heavily dominated by orchestration frameworks providing the chunking logic. **LangChain's RecursiveCharacterTextSplitter** is the ubiquitous, fast baseline for simple projects. However, **LlamaIndex** is currently the industry leader in advanced chunking methodologies, offering out-of-the-box support for **Hierarchical (Small-to-Big)** and **Semantic Chunking**. 
For enterprises prioritizing retrieval accuracy over ingestion speed/cost, Semantic Chunking ensures topics are never arbitrarily cut in half. For those dealing with massive documents where LLM context is key, Hierarchical chunking is the undisputed best practice. **Unstructured.io** remains the best choice for Structural chunking, perfectly marrying the parsing and chunking phases.

## 8. Benchmark Results
*   *Retrieval Accuracy (nDCG):* Benchmarks show that moving from a naive 500-token fixed splitter to a Semantic Splitter increases retrieval accuracy by 15-20% on complex reasoning tasks.
*   *Small-to-Big Retrieval:* Hierarchical chunking significantly reduces LLM hallucinations. By retrieving highly specific 128-token chunks but feeding the parent 1024-token chunk to the LLM, answer groundedness improves by up to 30%.
*   *Ingestion Latency:* Semantic chunking is computationally heavy. Processing a 100-page document takes milliseconds with Recursive splitters, but can take minutes with Semantic splitters due to the requirement of generating embeddings for every sentence to calculate breakpoints.

## 9. POC Results
*   *Pending internal POC for Q2:* Evaluating the cost-benefit ratio of LlamaIndex Semantic Chunking versus standard Recursive chunking with a 20% overlap on internal engineering wikis.
*   *Preliminary findings:* High overlap (e.g., 50%) in naive chunking leads to redundant vector storage and dilutes top-k retrieval results. Structural chunking based on Markdown headers yields the best cost-to-performance ratio for well-formatted internal documentation.

## 10. Cost Comparison
*   **Rule-Based/Structural (LangChain/Unstructured):** Free compute (runs locally/in-memory).
*   **Semantic Chunking:** Expensive. Requires making an API call to an embedding model (like OpenAI `text-embedding-3-small`) for *every single sentence* in the document just to determine where to place the cuts.
*   **Cloud Native:** Generally baked into the cost of the cloud vector/search service ingestion runs.

## 11. Security Comparison
*   Chunking inherently splits documents, meaning a single highly classified sentence might end up in a chunk separated from its surrounding context. 
*   **Crucial Security Pattern:** It is mandatory that the chunking framework inherits and attaches the Document-Level Access Control Lists (ACLs) as metadata to *every individual chunk* it creates, ensuring Vector DB filtering respects the original file permissions.

## 12. Scalability Comparison
*   Standard token/character splitting scales infinitely and can be parallelized across Spark or Ray clusters effortlessly.
*   Semantic splitting is heavily bottlenecked by Embedding API rate limits. Scaling this requires robust queueing and asynchronous processing to avoid `HTTP 429` errors during massive data lake ingests.

## 13. Operational Complexity
*   **Low Complexity:** Implementing a standard LangChain `RecursiveCharacterTextSplitter` with 512 tokens and 50 overlap.
*   **Medium Complexity:** Managing structural/Markdown chunking, which requires ensuring the upstream parser outputs perfectly clean Markdown.
*   **High Complexity:** Tuning the distance thresholds (e.g., standard deviation vs. percentile) for Semantic Chunking to ensure it splits appropriately for specific domain languages.

## 14. Implementation Effort
*   **Minutes:** Using out-of-the-box framework splitters.
*   **Days:** Implementing Hierarchical/Parent-Child chunking, which requires setting up a specialized `docstore` (e.g., Redis or Mongo) to hold the parent documents, while sending only the child chunks to the Vector DB.
*   **Weeks:** Building custom semantic chunking algorithms optimized for specialized vocabularies (e.g., Legal or Medical).

## 15. Enterprise Readiness
Frameworks like LangChain and LlamaIndex provide robust, heavily tested chunking utilities that are enterprise-ready. However, they lack native tracking. Enterprises must wrap these chunkers in observability tools (like LangSmith or Arize Phoenix) to monitor chunk size distributions and failure rates in production.

## 16. AI Readiness
Chunking is the bridge between raw data and AI. Utilizing tokenizers specific to your generation model (e.g., using `tiktoken` for OpenAI models) ensures that chunks perfectly align with the LLM's context window calculations, preventing truncation errors during generation.

## 17. Agentic Readiness
Advanced agents (like those built on LangGraph) can utilize dynamic chunking. An agent evaluating a complex prompt can autonomously decide to re-chunk a retrieved document at a different granularity on the fly if the initial retrieval lacks sufficient context.

## 18. Recommendation
For general enterprise knowledge bases, adopt **Structural/Markdown Chunking** using **Unstructured.io** or **LlamaIndex** as the baseline standard, as it respects the author's original intent. For highly complex Q&A over dense manuals, transition to **Hierarchical (Small-to-Big) Chunking**, storing 128-token children in the Vector DB and linking them to 1024-token parents in a standard Document Store.

## 19. Best Option by Scenario
*   **Scenario A (Simple, fast ingestion, budget constrained):** LangChain RecursiveCharacterTextSplitter.
*   **Scenario B (Well-formatted wikis and reports):** Structural/Markdown Chunking based on H1/H2/H3 tags.
*   **Scenario C (Complex reasoning, maximum retrieval accuracy required):** LlamaIndex HierarchicalNodeParser (Small-to-Big) combined with Semantic boundary detection.

## 20. ADR Reference
*   *See ADR-046: Standardized Chunking and Overlap Strategies for Enterprise Vector DBs.*
