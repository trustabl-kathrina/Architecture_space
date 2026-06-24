---
title: Document Parsing
section: "07.03.02.01"
status: complete
template: evaluation
last_reviewed: 2026-06-24
owner: architecture-team
tags: [rag, ingestion-and-parsing]
canonical: true
---
# 1. Document Parsing

## 1. Problem Statement
In Retrieval-Augmented Generation (RAG) systems, Large Language Models (LLMs) cannot natively read binary files like PDFs, Word documents, or complex HTML. These unstructured formats contain vital enterprise knowledge locked within intricate layouts, nested tables, multi-column text, and embedded images. Standard text extraction often destroys this reading order, jumbles table data, and ignores visual context, resulting in garbage data being fed to the LLM, leading to hallucinations and poor retrieval accuracy. The challenge is to accurately convert complex, visually structured documents into clean, semantically correct, LLM-readable text chunks (like Markdown) at enterprise scale.

## 2. Business Use Cases
*   **Financial Document Analysis:** Extracting tabular data from 10-Ks, balance sheets, and invoices for automated financial reporting and querying.
*   **Legal Contract Review:** Parsing complex legal PDFs with specific clauses, footnotes, and multi-column layouts to feed into a legal RAG assistant.
*   **Scientific and Medical Research:** Ingesting academic papers containing complex mathematical formulas, charts, and dense double-column text.
*   **Customer Support Knowledge Base:** Converting legacy product manuals, technical diagrams, and troubleshooting guides into a searchable AI copilot index.

## 3. Architecture Pattern
The standard Document Parsing architecture within an ingestion pipeline follows a multi-modal extraction pattern:
1.  **Ingestion trigger:** File lands in raw storage (e.g., S3, Azure Blob).
2.  **Routing / Triage:** System determines file type and complexity (e.g., native text PDF vs. scanned image PDF).
3.  **Parsing Engine:**
    *   *Path A (Simple):* Text-stream extraction via standard libraries.
    *   *Path B (Scanned/Images):* OCR processing.
    *   *Path C (Complex Layouts/Tables):* Vision Language Models (VLMs) or layout-aware deep learning models parse the document visually.
4.  **Formatting:** The extracted elements (titles, paragraphs, tables) are reconstructed into a sequential, LLM-optimized format, almost exclusively **Markdown**.

## 4. Technology Options
*   **Rule-Based/Heuristic Extraction:** Uses explicit programmatic rules to extract text streams from the underlying file structure. Fast but fails on complex layouts or nested tables.
*   **Optical Character Recognition (OCR):** Translates visual representations of text into machine-readable text. Necessary for scanned documents but lacks structural awareness (e.g., reading multi-column text sequentially).
*   **Vision/Deep Learning-Based Layout Understanding:** Employs multimodal LLMs or specialized vision models (e.g., LayoutLM, Donut) to understand document geometry. Visually identifies titles, paragraphs, tables, and images, ensuring logical flow is preserved and tables are converted into structured formats.

## 5. Cloud Native Options
*   **AWS:** **Amazon Textract** is the primary service for OCR and extracting text, handwriting, and layout from scanned documents. **Amazon Bedrock Knowledge Bases** offers built-in parsing for standard types.
*   **Azure:** **Azure AI Document Intelligence** (formerly Form Recognizer) provides advanced machine learning models to extract text, key-value pairs, tables, and document structure from complex PDFs and images.
*   **GCP:** **Google Cloud Document AI** leverages pre-trained models for generic text extraction (OCR) and specialized parsers for contracts, invoices, and forms, alongside **Vertex AI Parsers**.

## 6. Top 10 Vendor Options
1.  **Unstructured.io** (Leading open-source/SaaS platform explicitly built for LLM data ingestion).
2.  **LlamaParse** (SaaS by LlamaIndex, highly optimized for parsing complex documents with tables for RAG).
3.  **Docling** (IBM’s open-source tool for parsing complex PDFs to Markdown/JSON).
4.  **Upstage Document Parse** (API offering highly accurate OCR, layout analysis, and table extraction).
5.  **Marker** (High-speed open-source library for converting PDFs directly to Markdown).
6.  **PyMuPDF / Fitz** (The industry-standard open-source library for high-speed, digital PDF extraction).
7.  **Apache Tika** (Veteran open-source toolkit for enterprise content extraction across thousands of formats).
8.  **Reducto.ai** (Developer API focused on reliable document ingestion and chunking for LLMs).
9.  **Nuclia** (End-to-end unstructured data platform with strong multi-format parsing capabilities).
10. **Sensible.so** (Developer-first SaaS platform for extracting structured data from documents).

## 7. Comparison Matrix

### Table 1: Cloud Provider Evaluation Matrix

| Criteria | Amazon Textract | Azure AI Document Intelligence | Google Cloud Document AI |
| :--- | :--- | :--- | :--- |
| **Service** | Amazon Textract | Azure AI Document Intelligence | Google Cloud Document AI |
| **Cloud** | AWS | Azure | GCP |
| **OCR Quality** | High | Best-in-class | High |
| **PDF Parsing** | High | Excellent | High |
| **Table Extraction** | High (Struggles with deep nesting/merged cells) | Best-in-class (Handles merged cells flawlessly) | High |
| **Image Extraction** | Limited (Extracts text from images, but poor at raw image cropping) | Good (Provides bounding boxes and crops in newer APIs) | Limited (Bounding boxes provided, manual cropping needed) |
| **Layout Preservation**| Good | Best-in-class (Outputs native Markdown preserving reading order) | Good |
| **Handwriting Support**| Yes (High quality) | Yes (Excellent) | Yes (High quality) |
| **Multilingual Support**| Good (~6-10 major languages supported well) | Extensive (160+ languages) | Extensive (200+ via Google Vision API) |
| **Scanned PDFs** | Excellent | Excellent | Excellent |
| **Native LLM Integration**| Moderate (Requires LangChain/LlamaIndex AWS loaders) | High (Strong native loaders in major frameworks) | Moderate (Community loaders available) |
| **Structured Output** | JSON, CSV | Markdown, JSON | JSON (Document schema) |
| **Cost** | ~$1.50 - $15 per 1,000 pages (depends on features) | ~$1.50 - $10 per 1,000 pages | ~$1.50 - $10 per 1,000 pages |
| **Latency** | Medium | Medium | Medium |
| **Enterprise Readiness**| High (AWS SLAs, vast scale) | High (Azure SLAs, vast scale) | High (GCP SLAs, vast scale) |
| **Security** | High (HIPAA, FedRAMP, SOC) | High (Enterprise grade, HIPAA, SOC) | High (Enterprise grade, HIPAA) |
| **Private Deployment** | No (Cloud only, VPC endpoints available) | Yes (Via Azure Disconnected Containers) | No (Cloud only) |
| **Best Use Cases** | AWS-native workflows needing scalable OCR and structured form/invoice extraction. | Complex enterprise PDFs with heavy formatting and tables needing native Markdown for RAG. | GCP-native ecosystems and specialized document processing (e.g., invoices, IDs, receipts). |
| **Overall Score** | 8/10 | 9.5/10 | 8.5/10 |

**Executive Summary: Cloud Providers**
In the cloud provider landscape, **Azure AI Document Intelligence** is the clear winner for Generative AI and RAG pipelines. Its ability to accurately extract deeply nested tables and preserve complex layouts while natively outputting clean Markdown gives it a significant edge over AWS and GCP. Furthermore, Azure's unique ability to run via disconnected containers allows for private, on-premise deployments that AWS and GCP currently cannot match. GCP remains strong for heavy multilingual processing, while AWS is deeply embedded but slightly behind in native RAG/Markdown formatting.

### Table 2: Top 10 Market Options Evaluation Matrix

| Criteria | Unstructured.io | LlamaParse | Docling (IBM) | Upstage Document Parse | Marker | PyMuPDF / Fitz | Apache Tika | Reducto.ai | Nuclia | Sensible.so |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Service** | Unstructured.io | LlamaParse | Docling | Upstage Doc Parse | Marker | PyMuPDF | Apache Tika | Reducto.ai | Nuclia | Sensible.so |
| **Cloud** | Agnostic/Local | SaaS (LlamaCloud) | Local/Open Source | SaaS API | Local/Open Source | Local/Open Source | Local/Open Source | SaaS API | SaaS Platform | SaaS Platform |
| **OCR Quality** | High (via Tesseract/PaddleOCR) | High (VLM based) | High (VLM based) | Best-in-class (Proprietary) | High (via OCR libraries) | N/A (Digital text only) | Low (Basic OCR wrapper) | High | High | High |
| **PDF Parsing** | Excellent | Excellent | Excellent | Excellent | Good | Best-in-class (Digital) | Good | Excellent | Excellent | Excellent |
| **Table Extraction** | High (Table Transformer) | Best-in-class (Markdown output) | Excellent | Best-in-class (HTML/Markdown) | Good | Low (Custom logic needed) | Poor | High | High | High (Structured JSON) |
| **Image Extraction** | High | High (Extracts & captions) | High | High | Good | High (Extracts raw images) | Low | Medium | High | Low |
| **Layout Preservation**| Excellent (RAG-native) | Excellent (LLM reading order) | Excellent | Excellent | Good | Medium | Poor | Excellent | High | High |
| **Handwriting Support**| Medium | Yes | Yes | Yes | Medium | No | No | Unknown | Yes | Yes |
| **Multilingual Support**| Good | Good | Good | Excellent (Asian languages strong) | Good | Excellent (Encoding based) | Extensive | Good | Extensive | Good |
| **Scanned PDFs** | Good (Requires vision routing) | Excellent | Excellent | Excellent | Good | Poor (Fails) | Poor | Excellent | Excellent | Excellent |
| **Native LLM Integration**| Best-in-class | Best-in-class | High | High | Medium | High (Baseline used widely) | Low | High | High | Medium |
| **Structured Output** | JSON, Markdown, HTML | Markdown, JSON | Markdown, JSON | HTML, Markdown | Markdown | Text, HTML, Dict | Text, XML, JSON | Markdown | JSON | JSON |
| **Cost** | Free (OSS) / Tiered API | Freemium / Pay-per-page | Free (OSS) | Pay-per-page | Free (OSS) | Free (OSS/Commercial) | Free (OSS) | Pay-per-page | SaaS Tiered | SaaS Tiered |
| **Latency** | Fast (Local) to Slow (Hi-Res API) | Slow (VLM compute) | Medium | Fast (Optimized API) | Fast (Local GPU) | Fastest (Instant) | Fast | Fast | Medium | Medium |
| **Enterprise Readiness**| High (SOC2 SaaS) | Medium (Growing startup) | Medium (IBM Backed OSS) | High (Enterprise SLAs) | Low (Solo OSS project) | High (Standard library) | High (Legacy Standard) | Medium | High | High |
| **Security** | High (Local is private) | Medium (SaaS) | High (Local is private) | High (SaaS SLAs) | High (Local is private) | High (Local is private) | High (Local is private) | Medium (SaaS) | High | High |
| **Private Deployment** | Yes (OSS/Enterprise VPC) | Dedicated deployments | Yes (OSS) | Enterprise agreements | Yes (OSS) | Yes (OSS) | Yes (OSS) | No | Yes (Enterprise) | No |
| **Best Use Cases** | General RAG, mixed repos, strict privacy | Complex PDFs, math formulas, native LlamaIndex | Academic papers, complex layouts, local processing | High accuracy OCR/Table extraction, Asian languages | Fast local Markdown generation | Massive volumes of digital text PDFs | Legacy parsing of 1000s of varied file types | Developer-focused API for reliable LLM chunking | End-to-end multi-format RAG ingestion | Extracting highly structured fields from forms |
| **Overall Score** | 9/10 | 9/10 | 8.5/10 | 9/10 | 7.5/10 | 7/10 | 6.5/10 | 8/10 | 8/10 | 8/10 |

**Executive Summary: Market Options**
In the broader market, **Unstructured.io** remains the most robust open-source and flexible option, serving as the de facto standard for building custom, multi-format RAG pipelines (especially where local processing and data privacy are paramount). For proprietary SaaS, **LlamaParse** and **Upstage Document Parse** are fiercely competing for best-in-class performance on complex PDFs, specifically around preserving table structures and outputting LLM-ready Markdown/HTML. 

For teams building open-source, local-first RAG pipelines with highly complex documents (like scientific papers), IBM's **Docling** is emerging as a powerful, free alternative to SaaS parsers. For simple, digitally native text extraction at massive scale, **PyMuPDF** remains the fastest and most cost-effective tool, though it completely lacks the vision capabilities necessary for modern, complex RAG implementations.

## 8. Benchmark Results
*   *Table Extraction Accuracy:* LlamaParse and Azure AI Document Intelligence consistently score >95% accuracy in recreating merged cells and nested tables in Markdown formats, compared to ~60% for basic OCR wrappers.
*   *Processing Throughput:* Pure digital text extraction tools (PyMuPDF) benchmark at 1000+ pages/minute on standard CPUs. Vision-based models (hi-res Unstructured, LlamaParse) run considerably slower, averaging 0.5 to 2 seconds per page depending on GPU availability.

## 9. POC Results
*   *Pending official execution:* Q3 POC will evaluate Azure AI Document Intelligence vs. LlamaParse specifically on 5,000 legacy PDF financial reports. 
*   *Preliminary findings:* Initial testing shows that naive text extraction without layout preservation completely breaks semantic chunking for RAG. Markdown formatting is a strict requirement for successful LLM ingestion.

## 10. Cost Comparison
*   **Open Source (Local):** Free software licensing (Unstructured, PyMuPDF, Docling) but carries high compute costs (GPUs required for layout models) and heavy engineering maintenance.
*   **Cloud Providers:** Pay-per-page model. Averages $1.50 to $15.00 per 1,000 pages depending on the complexity of features invoked (e.g., basic OCR vs. deep table/form extraction).
*   **SaaS API (e.g., LlamaParse):** Generally tiered freemium models moving to a pay-per-page structure (around $3.00 per 1,000 pages).

## 11. Security Comparison
*   **SaaS APIs:** Data must leave the enterprise boundary. Requires strict scrutiny of BAA/DPA agreements, data retention policies, and SOC2/HIPAA compliance.
*   **Cloud Native:** Data stays within the cloud provider's tenant boundary, adhering to enterprise cloud security policies and IAM.
*   **Local/Open Source & Containerized (Azure Disconnected):** Highest security. Data never leaves the VPC or on-premise hardware, crucial for highly sensitive PII/PHI or defense data.

## 12. Scalability Comparison
*   **Cloud/SaaS APIs:** Infinitely scalable but subject to strict API rate limits and throttling limits that must be managed via queueing mechanisms (e.g., Kafka/SQS).
*   **Local/Open Source:** Scalability is entirely dependent on internal cluster provisioning (e.g., Kubernetes pods with attached GPUs). Scaling horizontally requires significant infrastructure management.

## 13. Operational Complexity
*   **Low Complexity:** Cloud SaaS options (LlamaParse) require simple API keys and handle all model updates and scaling invisibly.
*   **Medium Complexity:** Cloud Native options (Azure Document Intelligence) require setting up cloud networking, IAM roles, and storage buckets.
*   **High Complexity:** Hosting heavy vision models locally (Unstructured `hi_res`) requires managing CUDA drivers, GPU provisioning, and continuous MLOps patching.

## 14. Implementation Effort
*   **Days to Weeks:** Integrating SaaS APIs into existing Python pipelines.
*   **Weeks to Months:** Deploying secure, enterprise-grade cloud-native extraction pipelines with retry logic and error handling.
*   **Months:** Building, tuning, and hosting open-source vision-based layout extraction models on private clusters.

## 15. Enterprise Readiness
Cloud providers (Azure, AWS, GCP) offer the highest enterprise readiness with guaranteed SLAs, 24/7 support, and built-in disaster recovery. Open-source libraries require the enterprise to assume full responsibility for uptime and support.

## 16. AI Readiness
Modern parsing tools are highly AI-ready. Tools like LlamaParse and Unstructured directly output LangChain `Document` objects and LlamaIndex `Nodes`, seamlessly integrating into downstream embedding and LLM prompt generation processes.

## 17. Agentic Readiness
Parsing tools are increasingly being wrapped as "Tools" for autonomous agents. For example, a research agent can be given a tool to dynamically call a parsing API to read a PDF on the fly during a reasoning loop, rather than requiring the PDF to be pre-indexed in a vector database.

## 18. Recommendation
For the core enterprise standard, **Azure AI Document Intelligence** is the recommended parsing engine due to its unparalleled ability to generate perfect Markdown tables and preserve layout reading order for complex documents. For highly sensitive, air-gapped data, **Unstructured.io (local deployment)** or **Docling** are the recommended open-source alternatives.

## 19. Best Option by Scenario
*   **Scenario A (Highly complex PDFs, tables, charts, no strict data residency):** LlamaParse or Azure AI Document Intelligence.
*   **Scenario B (Massive volume of purely digital text, cost-sensitive):** PyMuPDF.
*   **Scenario C (Strict data privacy, highly confidential, requires custom rules):** Unstructured.io (Local) or Docling.

## 20. ADR Reference
*   *See ADR-042: Unstructured Data Parsing Standard for RAG* (Drafting phase).
