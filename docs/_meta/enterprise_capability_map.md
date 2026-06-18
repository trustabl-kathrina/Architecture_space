# Enterprise Capability Map

Architecture-first capability model for the Architecture Space documentation (`docs/`).

**Principles**

1. **One home per capability** — no duplicate enterprise frameworks across sections.
2. **Concept vs implementation** — sections 00–01 define *what/why*; 02–14 define *how*; 04/17 define *which technology*.
3. **Reduced surface** — ~12 capabilities per section (not 200+ stub clones per legacy domain).
4. **Current corpus** — ~6,156 topic files; target after dedup ~1,200–1,500 authored topics.

See also: [canonical_ownership.yaml](canonical_ownership.yaml) | [taxonomy.yaml](taxonomy.yaml)

---

## Summary matrix

| # | Section | Role | Target capabilities | Current topics | Action |
| ---: | --- | --- | ---: | ---: | --- |
| 00 | Architecture Governance | Cross-cutting EA, ADRs, standards | 45 | 1,542 | **Purge** nested legacy 01–25 trees |
| 01 | Data Architecture | Enterprise data design concepts | 35 | 328 | Consolidate; remove engineering detail |
| 02 | Data Engineering | Pipelines, orchestration, reliability | 55 | 290 | Reorganize into 02.01–02.05 |
| 02.06 | Data Storage | Lake, WH, lakehouse, marts | 30 | 36 | Expand storage patterns |
| 04 | Cloud Data Platforms | GCP/AWS/Azure + FinOps | 80 | 962 | **Purge** non-cloud duplicates |
| 05 | Data Modeling | Conceptual → physical models | 40 | 38 | Align to subsection model |
| 06 | Data Products | Product lifecycle & contracts | 35 | 49 | Keep; link governance to 00.10 |
| 00.10 | Data Governance & Metadata | Policy, catalog, DQ, MDM | 60 | 738 | **Canonical** for governance frameworks |
| 08 | Analytics | BI, semantic layer, self-service | 40 | 214 | Remove real-time (→ 08.10) |
| 02.01.02 | Event & Streaming | Events, stream processing, CDC | 50 | 287 | **Canonical** for streaming |
| 08.10 | Real-Time Analytics | OLAP engines (Pinot, Druid, CH) | 25 | 9 | Expand; absorb 08.03 |
| 11 | AI Data Architecture | AI-ready data, RAG, features | 45 | 231 | Remove MCP/A2A (→ 11.12) |
| 11.12 | Agentic AI | Agents, MCP, A2A, AgentOps | 50 | 529 | **Canonical** for agent protocols |
| 13 | MLOps | ML lifecycle & model governance | 35 | 47 | Keep; boundary with 11.02 |
| 14 | Security & Privacy | IAM, encryption, zero trust | 45 | 264 | **Canonical** for security patterns |
| 15 | Industry Reference | Vertical architectures | 40 | 338 | **Canonical** for industry cases |
| 16 | Interview Prep | Role-based study guides | 25 | 0 | Greenfield |
| 17 | Technology Comparisons | Vendor evals & benchmarks | 50 | 253 | **Canonical** for comparisons |
| 19 | Templates & Frameworks | Doc templates | 15 | 0 | Greenfield |
| 20 | Pluto MIND | Product architecture | 30 | 0 | Greenfield |

---

## 00 — Architecture Governance

**Owns:** Enterprise architecture discipline — not domain data/AI implementation.

| Capability | Subsection | Notes |
| --- | --- | --- |
| Architecture principles | 00.01 | Single principles set for all domains |
| Reference architecture catalogue | 00.02 | **Generic** RA patterns only — not full legacy section copies |
| Architecture decision records (ADRs) | 00.03 | **Only** location for ADRs |
| Architecture patterns | 00.04 | Cross-domain patterns (integration, resilience, layering) |
| Architecture review checklists | 00.05 | Design review, security review gates |
| Non-functional requirements | 00.06 | Performance, availability, scalability NFRs |
| Solution blueprints | 00.07 | End-to-end blueprint templates (transformation, migration) |
| Standards & guidelines | 00.08 | Naming, documentation, diagram standards |
| Enterprise strategy alignment | 00.09 | Vision, operating model, funding — **not** duplicated per domain |

**Remove from 00:** Nested legacy folders (`01_*` … `25_*` inside 00.02/00.04/00.07) — ~1,200 duplicate files.  
**Remove:** Per-domain `Governance_Maturity.md`, `Compliance_Framework.md`, `Showback_Model.md` copies.

---

## 01 — Data Architecture

**Owns:** What the enterprise data landscape looks like — not how pipelines run.

| Capability | Subsection |
| --- | --- |
| Data architecture fundamentals | 01.01 |
| Data mesh & fabric principles | 01.02 |
| Domain-driven data design | 01.02 |
| Data product thinking (conceptual) | 01.02 |
| Lakehouse & modern platform concepts | 01.02 |
| Metadata-driven architecture (concept) | 01.02 |
| Enterprise data capability map | 01.01 |
| Data architecture maturity | 01.01 |
| Reference architectures (data-specific) | 01.03 |
| Case studies (cross-industry data) | 01.04 |

**Remove:** Ingestion/transformation implementation (→ 02), catalog/DQ implementation (→ 07), cloud services (→ 04).

---

## 02 — Data Engineering Architecture

**Owns:** How data is moved, transformed, scheduled, observed, and kept reliable.

| Capability | Subsection |
| --- | --- |
| **Ingestion** — patterns, onboarding, batch/API/file/DB/SaaS | 02.01 |
| **Ingestion** — CDC entry patterns (detail → 09) | 02.01 |
| **Transformation** — ETL/ELT, enrichment, harmonization, SCD | 02.02 |
| **Transformation** — batch processing architecture | 02.02 |
| **Orchestration** — Airflow/Dagster/Prefect, scheduling, retries | 02.03 |
| **Orchestration** — DataOps, CI/CD, GitOps for data | 02.03 |
| **Observability** — pipeline monitoring, freshness, schema drift | 02.04 |
| **Observability** — lineage-aware monitoring, alerting | 02.04 |
| **Reliability** — SLO/SLA, error budgets, resilience, DR | 02.05 |
| Lakehouse engineering (medallion execution) | 02.02 |
| Metadata-driven pipeline generation | 02.03 |
| Performance & query optimization (engineering) | 02.02 |
| AI-assisted pipeline engineering | 02.03 |
| DE governance (coding standards, pipeline review) | 02.05 |

**Remove:** `Governance_Maturity`, `Compliance_Framework`, `Showback_Model` (→ 04.06 / 07).  
**Remove:** Streaming fundamentals (→ 09), enterprise DQ framework (→ 00.10.04).  
**Migrate:** Legacy `04.xx` folders from 02.01 into 02.01–02.05.

---

## 02.06 — Data Storage Architecture

**Owns:** Where and how data is persisted analytically.

| Capability | Subsection |
| --- | --- |
| Data lake architecture | 02.06.01 |
| Data warehouse architecture | 02.06.02 |
| Lakehouse storage model | 02.06.03 |
| Data marts & ODS | 02.06.04–02.06.05 |
| Analytical stores (columnar, OLAP serving) | 02.06.06 |
| Partitioning, clustering, lifecycle | 02.06.07 |
| Open table formats (Delta, Iceberg, Hudi) | 02.06.03 |
| Storage tiering & archival | 02.06.07 |

**Remove:** Cloud-specific service docs (→ 04), real-time engines (→ 10).

---

## 04 — Cloud Data Platforms

**Owns:** Cloud-native implementation — **canonical for FinOps/showback/chargeback**.

| Capability | Subsection |
| --- | --- |
| GCP data services map | 04.01 |
| AWS data services map | 04.02 |
| Azure data services map | 04.03 |
| Platform engineering (IaC, IDP, K8s for data) | 04.04 |
| Lakehouse platforms (Databricks, Snowflake, BigQuery) | 04.05 |
| **FinOps** — showback, chargeback, cost allocation | 04.06 |
| Multi-cloud & hybrid patterns | 04.01–04.03 |
| Cloud data landing zones | 04.04 |

**Remove:** ~800 duplicate topics (governance, maturity, observability corpora copied from legacy).  
**Remove:** `Showback_Model` / `Chargeback_Model` copies in 00, 02.

---

## 05 — Data Modeling Architecture

**Owns:** All modeling disciplines.

| Capability | Subsection |
| --- | --- |
| Modeling fundamentals | 05.01 |
| Conceptual & logical modeling | 05.02–05.03 |
| Physical modeling | 05.04 |
| Dimensional modeling | 05.05 |
| Data Vault 2.0 | 05.06 |
| Canonical & semantic models | 05.07–05.08 |
| TMF SID & industry models | 05.09–05.10 |

---

## 06 — Data Product Architecture

**Owns:** Data as a product — lifecycle, design, marketplace.

| Capability | Subsection |
| --- | --- |
| Data product fundamentals | 06.01 |
| Product lifecycle (discover → retire) | 06.02 |
| Product design & boundaries | 06.03 |
| SDP / ADP / CDP patterns | 06.04–06.06 |
| Marketplace architecture | 06.07 |
| Data contracts (product interface) | 06.08 |
| Product governance (product-specific) | 06.09 |

**Remove:** Enterprise governance frameworks (→ 07); keep only product-specific governance deltas.

---

## 00.10 — Data Governance & Metadata

**Owns:** **Canonical home for enterprise governance, metadata, quality, MDM.**

| Capability | Subsection |
| --- | --- |
| Metadata management strategy | 00.10.01 |
| Data catalog architecture | 00.10.02 |
| Data lineage architecture | 00.10.03 |
| Data quality framework & rules | 00.10.04 |
| Master data management | 00.10.05 |
| Reference data management | 00.10.06 |
| Data privacy (policy) | 00.10.07 |
| Data security (policy) | 00.10.08 |
| Regulatory compliance framework | 00.10.09 |
| **Governance operating model & maturity** | 00.10.10 |
| Stewardship & ownership model | 00.10.10 |
| Policy management & exceptions | 00.10.10 |

**Remove:** 15× `Governance_Maturity.md` copies in other sections — **keep one here**.  
**Boundary:** Implementation security controls → 14; privacy engineering → 14.09.

---

## 08 — Analytics Architecture

**Owns:** BI, semantic layer, dashboards, self-service — **not** stream OLAP engines.

| Capability | Subsection |
| --- | --- |
| BI architecture & platform selection | 08.01 |
| Semantic layer / metrics layer | 08.02 |
| Self-service analytics governance | 08.04 |
| Dashboard architecture | 08.05 |
| Tool architectures (Tableau, Power BI, Looker, Metabase) | 08.06–08.09 |

**Remove:** `08.03_Real_Time_Analytics` — merge into 08.10.  
**Remove:** Duplicate KPI/scorecard frameworks (→ 17 or 07).

---

## 02.07 — Event & Streaming Architecture

**Owns:** **Canonical for event-driven and stream processing.**

| Capability | Subsection |
| --- | --- |
| Event-driven architecture fundamentals | 02.01.02.01 |
| Stream processing patterns | 02.01.02.04 |
| CDC architecture (streaming path) | 02.01.02.01 |
| Cloud streaming (Pub/Sub, Kinesis, Event Hubs) | 02.01.02.02 |
| Open source (Kafka, Flink, Spark Streaming) | 02.01.02.03 |
| Streaming benchmarks & POCs | 02.01.02.05 |
| Technology comparisons (streaming) | 02.01.02.06 |
| Integration patterns (event API, saga) | 02.01.02.08 |

**Remove:** Duplicate streaming topics in 02, 04, 00.

---

## 08.10 — Real-Time Analytics Architecture

**Owns:** Low-latency analytical **serving** engines.

| Capability | Subsection |
| --- | --- |
| Real-time analytics architecture overview | 08.10.05 |
| ClickHouse architecture | 08.10.01 |
| Apache Pinot architecture | 08.10.02 |
| Apache Druid architecture | 08.10.03 |
| Elasticsearch as analytics store | 08.10.04 |
| Streaming analytics serving patterns | 08.10.05 |

**Absorb:** Content from `08.03_Real_Time_Analytics`.

---

## 11 — AI Data Architecture

**Owns:** Data platforms for AI — features, RAG, vectors — **not** agent runtime.

| Capability | Subsection |
| --- | --- |
| AI-ready data platform | 11.01 |
| Feature store architecture | 11.02 |
| RAG architecture & evaluations | 11.03 |
| Agentic AI **data** layer (context, memory stores) | 11.04 |
| Vector database architecture | 11.07 |
| Prompt engineering (data context) | 11.08 |
| AI governance (data side) | 11.09 |
| AI observability (data/LLM pipelines) | 11.10 |
| AI FinOps (token/compute cost) | 11.11 |

**Remove:** `11.05_MCP`, `11.06_A2A` — **canonical in 11.12**.  
**Boundary:** Model training/deployment → 13; agent orchestration → 12.

---

## 11.12 — Agentic AI Architecture

**Owns:** **Canonical for agents, MCP, A2A, multi-agent systems.**

| Capability | Subsection |
| --- | --- |
| Agentic AI fundamentals | 11.12.01 |
| Agent architecture & runtime | 11.12.02 |
| Agent design patterns | 11.12.03 |
| **MCP protocol & tool integration** | 11.12.04 |
| **A2A protocol & inter-agent comms** | 11.12.05 |
| Agent orchestration | 11.12.06 |
| AgentOps (deploy, monitor, evaluate agents) | 11.12.07 |
| Multi-agent systems | 11.12.08 |
| Digital workforce architecture | 11.12.09 |

**Remove:** Duplicate MCP/A2A/agent topics from 00, 11.  
**Remove:** Generic `Governance_Maturity` copies — use `Agentic_AI_Maturity` domain doc only.

---

## 13 — MLOps Architecture

**Owns:** ML lifecycle end-to-end.

| Capability | Subsection |
| --- | --- |
| ML lifecycle framework | 13.01 |
| Feature engineering pipelines | 13.02 |
| Training architecture | 13.03 |
| Model deployment & serving | 13.04 |
| Model monitoring & drift | 13.05 |
| Model governance & registry | 13.06 |

**Boundary:** Feature store **serving** → 11.02; feature **pipelines** → 13.02.

---

## 14 — Security & Privacy Architecture

**Owns:** **Canonical for security & privacy engineering.**

| Capability | Subsection |
| --- | --- |
| IAM for data platforms | 14.01 |
| Encryption (at rest, in transit) | 14.02 |
| Secrets management | 14.03 |
| Row-level security | 14.04 |
| Column-level security | 14.05 |
| Zero trust for data | 14.06 |
| Compliance controls (SOC2, GDPR technical) | 14.07 |
| AI security & guardrails | 14.08 |
| Privacy engineering | 14.09 |

**Remove:** `Governance_Maturity` security copies — use `Security_Maturity` one-pager linking to 00.10.10.

---

## 15 — Industry Reference Architectures

**Owns:** **Canonical for vertical-specific architectures and case studies.**

| Capability | Subsection |
| --- | --- |
| Telecom reference architecture | 15.01 |
| Banking | 15.02 |
| Insurance | 15.03 |
| Retail | 15.04 |
| Healthcare | 15.05 |
| Manufacturing | 15.06 |
| Government | 15.07 |
| Cross-industry case studies | 15.08 |

**Remove:** Per-section case study stubs (02.25, 04.25, etc.) — link here or delete.

---

## 16 — Architecture Interview Preparation

| Capability | Subsection |
| --- | --- |
| Data architect interview guide | 16.01 |
| Solution architect | 16.02 |
| Enterprise architect | 16.03 |
| AI architect | 16.04 |
| GCP / AWS architect | 16.05–16.06 |
| Scenario-based questions | 16.07 |

---

## 17 — Technology Comparisons

**Owns:** **Canonical for all vendor evaluations and comparison matrices.**

| Capability | Subsection |
| --- | --- |
| BigQuery vs Snowflake | 17.01 |
| Kafka vs Pulsar | 17.02 |
| Airflow vs Dagster | 17.03 |
| Databricks vs Snowflake | 17.04 |
| ClickHouse vs Druid | 17.05 |
| Data Mesh vs Fabric | 17.06 |
| ETL vs ELT | 17.07 |
| Vendor evaluations (by category) | 17.08 |
| Selection frameworks & scorecards | 17.09 |

**Remove:** `Vendor_Scorecards`, `Platform_Scorecards` copies in 00, 04.

---

## 19 — Templates & Frameworks

| Capability | Subsection |
| --- | --- |
| Architecture document template | 19.01 |
| HLD / LLD templates | 19.02–19.03 |
| Data product & contract templates | 19.04–19.05 |
| ADR template | 19.06 |
| Governance & benchmark templates | 19.07–19.08 |

---

## 20 — Pluto MIND

| Capability | Subsection |
| --- | --- |
| Acquisition AI | 20.01 |
| Model AI | 20.02 |
| Transformation AI | 20.03 |
| Fluid specification | 20.04 |
| Data product builder & marketplace | 20.05–20.06 |
| AI governance, FinOps, data quality (product) | 20.07–20.09 |

---

## Deduplication priority (execution order)

| Priority | Action | Impact |
| ---: | --- | ---: |
| 1 | Purge nested legacy trees in **section 00** | ~1,200 files |
| 2 | Purge non-cloud duplicates in **section 04** | ~700 files |
| 3 | Resolve **426 duplicate filename groups** via canonical_ownership.yaml | ~800 files |
| 4 | Reorganize **section 02** into 02.01–02.05 | structural |
| 5 | Remove **11.05/11.06** and **08.03** | ~50 files |
| 6 | Consolidate case studies into **15.08** | ~100 files |

**Estimated target corpus:** ~1,200–1,500 unique capabilities (from ~6,156 today).

---

## Cross-section quick reference

| Topic | Keep in | Delete elsewhere |
| --- | --- | --- |
| Governance maturity | 00.10.10 | 00, 01, 04, 09, 12, 14 |
| FinOps / showback / chargeback | 04.06 | 00, 02 |
| Compliance framework | 00.10.09 | 00, 02, 04, 12 |
| MCP / A2A | 11.12.04–11.12.05 | 11, 00 |
| RAG / vectors | 11.03, 11.07 | 11.12 |
| Streaming / events | 02.01.02 | 02, 04, 00 |
| Real-time OLAP | 08.10 | 08 |
| ADRs | 00.03 | all sections |
| Vendor comparisons | 17 | all sections |
| Industry cases | 15 | per-section case folders |
| Data quality (enterprise) | 00.10.04 | 02 (keep pipeline validation only) |
| Security controls | 14 | 00.10.08 (policy only in 07) |
