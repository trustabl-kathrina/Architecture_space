# 2. Data Cleaning

## 1. Problem Statement
Raw unstructured text extracted from documents or web pages is heavily polluted with noise. This includes HTML tags, CSS styling, repetitive boilerplate (headers, footers, page numbers), invisible characters, broken Unicode, and sensitive Personally Identifiable Information (PII). Feeding this "dirty" data directly into an embedding model or LLM context window leads to bloated token usage (increasing costs), semantic confusion, and high hallucination rates during retrieval. Furthermore, failing to sanitize PII prior to embedding introduces severe security and compliance risks. The challenge is to construct automated, highly accurate data cleaning and redaction pipelines that prepare text specifically for optimal RAG performance.

## 2. Business Use Cases
*   **Customer Support Logs:** Cleaning transcription errors and conversational filler from chat logs to create a concise, factual knowledge base for a support copilot.
*   **Web-Scraped Intelligence:** Stripping navigation menus, ads, and sidebars from competitor websites or news articles to isolate the core narrative text for analysis.
*   **HR and Legal Documentation:** Identifying and redacting employee names, SSNs, or sensitive client details from internal documents before they are indexed in a company-wide search tool.
*   **Legacy Data Lake Migration:** Deduplicating millions of historical text records to ensure the vector database isn't polluted with near-identical copies of the same document.

## 3. Architecture Pattern
The standard Data Cleaning architecture operates as a sequential middleware layer between parsing and chunking:
1.  **Normalization:** Converting text to a standard encoding (e.g., UTF-8), fixing mojibake, and normalizing whitespace.
2.  **Noise Reduction (Regex/Rules):** Applying deterministic rules to strip URLs, emails, HTML tags, and document boilerplate.
3.  **PII Redaction/Masking:** Passing text through NLP models (e.g., Presidio) to detect and replace sensitive entities with placeholders (e.g., `<PERSON_NAME>`).
4.  **Deduplication:** Utilizing probabilistic data structures (like MinHash/LSH) to filter out redundant content at the document or chunk level.
5.  *(Optional)* **AI-Assisted Rewriting:** For heavily distorted text (e.g., bad OCR), using a small LLM to synthesize and correct the text before embedding.

## 4. Technology Options
*   **Regex and Rule-Based Filtering:** Utilizing fast, deterministic regular expressions for predictable patterns.
*   **Statistical/Heuristic Cleaning:** Filtering out chunks based on character-to-word ratios or unusual character density.
*   **Algorithmic Deduplication:** Using MinHash, SimHash, or Locality-Sensitive Hashing (LSH) for rapid, large-scale duplicate detection.
*   **NLP/ML-Based Masking:** Utilizing pre-trained models to contextually identify and redact entities (PII).
*   **LLM-Assisted Cleaning (Rewriting):** Using a smaller LLM to rewrite messy chunks into clean prose.

## 5. Cloud Native Options
*   **AWS:** **AWS Glue DataBrew** provides visual data preparation. For unstructured text, **Amazon Macie** is critical for discovering and redacting sensitive PII.
*   **Azure:** **Azure Data Factory** handles data wrangling, while **Azure AI Language** provides native models for PII detection and automated redaction in text streams.
*   **GCP:** **Cloud Dataprep** handles structured/semi-structured cleaning, and **Cloud Data Loss Prevention (DLP)** is an industry leader for inspecting, classifying, and masking sensitive data/PII in unstructured text.

## 6. Top 10 Vendor Options
1.  **Cleanlab** (AI-driven platform that automatically detects and fixes data issues, noise, and label errors).
2.  **Microsoft Presidio** (Leading open-source framework specifically designed for identifying and anonymizing PII in text).
3.  **Unstructured.io** (Provides dedicated "cleaning bricks"—open-source functions for sanitizing text).
4.  **Snorkel Flow** (Data-centric AI platform that helps clean, filter, and iteratively improve ingestion data).
5.  **Great Expectations** (Open-source standard for data quality testing, validation, and profiling).
6.  **dbt (Data Build Tool)** (The industry standard for cleaning structured metadata feeds).
7.  **Dataiku** (Enterprise platform with visual tools for data preparation, deduplication, and text cleaning).
8.  **Tonic.ai** (SaaS focused on data de-identification and creating safe synthetic data).
9.  **OpenRefine** (Popular open-source tool for cleaning messy data).
10. **Giskard** (Open-source platform that evaluates data quality and detects vulnerabilities).

## 7. Comparison Matrix

### Table 1: Cloud Provider Evaluation Matrix

| Criteria | AWS Glue DataBrew | Azure Data Factory (Wrangling) | Google Cloud Dataprep |
| :--- | :--- | :--- | :--- |
| **Data Profiling** | High (Visual profiling, anomaly detection) | Medium (Basic stats, requires Databricks/Synapse for deep profiling) | High (Intelligent visual profiling, histograms) |
| **Standardization** | High (250+ built-in transforms) | High (Power Query M-script) | High (Predictive transformation suggestions) |
| **Deduplication** | High (Fuzzy matching, exact matching) | Medium (Standard dedupe, fuzzy logic requires custom scripts) | High (Pattern-based deduplication) |
| **Address Cleaning** | Medium (Regex based, requires external API for validation) | Medium (Regex/custom logic) | Medium (Standardization tools available) |
| **AI Assisted Cleaning** | Medium (Some ML-based anomaly detection) | Low (Mostly manual/scripted rules) | High (AI-driven suggestions for cleaning steps) |
| **Metadata Awareness** | Medium (Works with AWS Glue Data Catalog) | High (Deep integration with Microsoft Purview) | Medium (Integrates with Dataplex) |
| **Data Lineage** | Medium (Job level tracking) | High (Through Purview) | High (Detailed transformation lineage) |
| **Governance Integration** | High (Lake Formation integration) | High (Purview integration) | High (Dataplex integration) |
| **Automation** | High (EventBridge/Event-driven) | High (ADF pipelines) | High (Cloud Composer/Airflow) |
| **Enterprise Readiness** | High | High | High |
| **Cost** | Medium (Pay per session/node-hour) | Medium (Pay per execution/activity) | Medium (Compute-based pricing) |
| **Scalability** | High (Serverless Spark backend) | High (Spark/Synapse backend) | High (Dataflow backend) |

**Executive Summary: Cloud Providers**
For enterprise data cleaning, **Google Cloud Dataprep (by Trifacta)** stands out due to its highly intelligent, AI-driven visual profiling and transformation suggestions, making it the most user-friendly for data stewards. However, if the enterprise is already heavily invested in Microsoft, **Azure Data Factory** paired with Microsoft Purview offers the strongest end-to-end data lineage and metadata governance. **AWS Glue DataBrew** remains a highly capable, serverless option with excellent built-in transformations, particularly strong for AWS-native data lakes.

### Table 2: Top 10 Market Options Evaluation Matrix

| Criteria | Cleanlab | Microsoft Presidio | Unstructured.io | Snorkel Flow | Great Expectations | dbt | Dataiku | Tonic.ai | OpenRefine | Giskard |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Data Profiling** | High (Detects label/data errors) | Low (PII specific) | Low (Focuses on structure) | High (Slices/Subsets) | High (Data quality metrics) | Medium (Testing focused) | High (Visual) | High (Privacy focused) | High (Visual facets) | High (Model vulnerability) |
| **Standardization** | Medium (Auto-fixes) | N/A | High (Text normalization) | High | High (Validation rules) | High (SQL transforms) | High (Visual/Code) | Medium | High (GREL scripts) | N/A |
| **Deduplication** | Medium | N/A | Medium (Exact match) | Medium | Low | High (SQL logic) | High | N/A | High (Clustering) | N/A |
| **Address Cleaning** | Low | Low | Low | Low | Low | Medium (via SQL) | Medium | Medium (Faking/Masking) | Medium (External APIs) | N/A |
| **AI Assisted Cleaning**| Best-in-class | Low | Medium (Vision models) | Best-in-class | Low | Low | High | High (Synthetic data) | Low | High (LLM evaluation) |
| **Metadata Awareness** | Medium | Medium | High (Extracts metadata) | Medium | Medium | High | High | Low | Low | High (Model metadata) |
| **Data Lineage** | Low | Low | Low | Medium | Low | Best-in-class | High | Low | Low (Action history) | Low |
| **Governance Integration**| Low | High (Compliance) | Low | Medium | High | High | High | High (Privacy compliance)| Low | Medium |
| **Automation** | High (API) | High (API/Scripts) | High (Pipelines) | High | High (CI/CD) | High (CI/CD) | High | High | Low (Manual tool) | High (CI/CD) |
| **Enterprise Readiness**| High | High | High | High | High | High | High | High | Low | Medium |
| **Cost** | SaaS | Open Source | OSS/SaaS | Enterprise | OSS/SaaS | OSS/SaaS | Enterprise | Enterprise | Open Source | Open Source |
| **Scalability** | High | High | High | High | High | High (Cloud DW) | High | High | Low (In-memory) | Medium |

**Executive Summary: Market Options for RAG**
When preparing data specifically for Retrieval-Augmented Generation (RAG), the needs shift heavily toward unstructured text manipulation and privacy. **Unstructured.io** is the absolute best overall open-source option for standardizing and normalizing raw documents into clean chunks. For privacy and compliance, **Microsoft Presidio** is essential for redacting PII before embedding data. 

For advanced, AI-driven cleaning (fixing bad OCR, removing hallucinations from training data), **Cleanlab** and **Snorkel Flow** are the premier proprietary choices, using ML to actively find and fix dirty data points rather than relying on static rules. **dbt** remains the undisputed champion for cleaning the structured metadata or tabular data that might accompany your RAG vector stores.

## 8. Benchmark Results
*   *Regex/Rule-based Normalization:* Python libraries like `clean-text` can process and normalize gigabytes of text per minute with minimal memory overhead.
*   *PII Redaction:* Microsoft Presidio benchmarks show a >95% recall rate for standard PII entities (SSN, credit cards, emails) when combining regex with NER models, with processing speeds suitable for near real-time ingestion.
*   *Deduplication:* MinHash LSH implementations can deduplicate million-document datasets in minutes, compared to days for standard O(N^2) cosine similarity comparisons.

## 9. POC Results
*   *Pending internal POC for Q3:* Integrating Microsoft Presidio into the unstructured ingestion pipeline to evaluate processing overhead and false-positive redaction rates on historical HR documents.
*   *Preliminary findings:* Relying solely on LLMs for data cleaning (rewriting text) is cost-prohibitive and too slow for bulk ingestion; it should be reserved strictly for edge cases where standard OCR completely fails.

## 10. Cost Comparison
*   **Regex/Libraries (e.g., clean-text, Datasketch):** Virtually free. Runs efficiently on commodity CPU hardware.
*   **Managed PII Services (e.g., GCP DLP, AWS Macie):** Pay-per-GB inspected. Can become expensive for massive, repetitive data lakes; best utilized via incremental processing.
*   **LLM-Assisted Rewriting:** Highest cost. Generating new, clean text using an LLM API costs significantly more (per token) than embedding generation.

## 11. Security Comparison
*   Data cleaning is fundamentally a security control. Failing to properly configure PII redaction (e.g., Presidio) risks leaking sensitive data into vector databases, which can then be extracted via prompt injection by unauthorized users.
*   Cloud-native DLP services provide the highest security assurance, as they update classification patterns automatically to comply with evolving regulations (GDPR, CCPA).

## 12. Scalability Comparison
*   **Deterministic Cleaning (Regex/Normalization):** Scales linearly and can be easily distributed across Spark clusters or parallelized in Python.
*   **NLP/PII Detection:** Heavier compute footprint. Scaling requires deploying multiple instances of NER models (e.g., via spaCy pipelines) behind a load balancer.

## 13. Operational Complexity
*   **Low Complexity:** Implementing basic regex stripping and unicode normalization.
*   **Medium Complexity:** Maintaining and tuning custom PII redaction models to minimize false positives (e.g., accidentally redacting non-sensitive numbers).
*   **High Complexity:** Managing large-scale MinHash deduplication indices and ensuring they stay perfectly synchronized with the underlying knowledge base.

## 14. Implementation Effort
*   **Days:** Setting up basic Unstructured.io cleaning "bricks" (cleaning whitespace, removing URLs).
*   **Weeks:** Implementing, tuning, and deploying an enterprise-wide Presidio API service for reliable PII masking across different data domains.

## 15. Enterprise Readiness
Tools like GCP DLP, AWS Macie, and Azure AI Language are highly enterprise-ready, offering built-in audit trails, compliance certifications, and SLA guarantees for sensitive data handling. Open-source tools like Presidio are widely adopted but require internal infrastructure management to achieve enterprise-grade reliability.

## 16. AI Readiness
Proper data cleaning directly impacts AI readiness. Clean, normalized data drastically improves the clustering quality of embedding models and significantly reduces the token load required for the LLM context window, resulting in faster, cheaper, and more accurate generation.

## 17. Agentic Readiness
Data cleaning pipelines must be accessible as programmatic tools for autonomous agents. For instance, an agent tasked with ingesting a user-provided file must first be able to call a "Clean Text" and "Redact PII" tool before attempting to store that information in the agent's long-term memory.

## 18. Recommendation
For unstructured text standardization, adopt the **Unstructured.io** cleaning libraries as the standard baseline. For security and compliance, **Microsoft Presidio** must be integrated into all pipelines processing potentially sensitive data prior to vectorization.

## 19. Best Option by Scenario
*   **Scenario A (Strict PII/Compliance requirements):** Microsoft Presidio or GCP DLP.
*   **Scenario B (Massive scale, fast text normalization):** Python `clean-text` and custom Regex pipelines.
*   **Scenario C (Enterprise Deduplication):** Datasketch (MinHash/LSH) or Spark-based deduplication algorithms.

## 20. ADR Reference
*   *See ADR-043: Unstructured Data Sanitization and PII Redaction Strategy.*
