# Architecture Space

Architecture-first documentation space for enterprise data, analytics, AI, cloud data platforms, governance, security, POCs, and Pluto MIND.

## Start Here

- [Architecture Governance](00_Architecture_Governance/README.md)
- [Data Architecture](01_Data_Architecture/README.md)
- [Data Engineering Architecture](02_Data_Engineering_Architecture/README.md)
- [AI Data Architecture](11_AI_Data_Architecture/README.md)
- [Pluto MIND](20_Pluto_MIND/README.md)

## Hubs

- [Data Mesh Hub](_hubs/Data_Mesh_Hub.md)
- [FinOps Hub](_hubs/FinOps_Hub.md)
- [Agentic AI Hub](_hubs/Agentic_AI_Hub.md)
- [Pluto MIND Hub](_hubs/Pluto_MIND_Hub.md)

## Sections

Numbering is hierarchical at every level: parent sections (`00`–`20`), nested domains (`00.10`, `02.06`, `08.10`, `11.12`), ingestion modes under `02.01` (`02.01.01` batch, `02.01.02` streaming, `02.01.03` near-real-time, `02.01.04` shared foundations), and sequenced topic files (`02.01.02.01.01.01_*`). Folder names, front matter `section:` fields, and taxonomy IDs all use the same scheme.

| # | Section | Path | Purpose |
| --- | --- | --- | --- |
| 00 | [Architecture Governance](00_Architecture_Governance/README.md) | `00_*` | Architecture principles, reference architectures, ADRs, patterns, review checklists, NFRs, blueprints, standards, and strategy alignment. |
| 00.10 | ↳ Data Governance And Metadata | `00.10_*` under 00 | Metadata, catalog, lineage, quality, MDM, privacy, security, compliance, and governance operating model. |
| 01 | [Data Architecture](01_Data_Architecture/README.md) | `01_*` | Data architecture fundamentals, enterprise data architecture, mesh, fabric, lakehouse concepts, and domain-driven design. |
| 02 | [Data Engineering Architecture](02_Data_Engineering_Architecture/README.md) | `02_*` | Data ingestion, transformation, orchestration, observability, and reliability architecture. |
| 02.01 | ↳ Data Ingestion (batch / streaming / NRT / shared) | `02.01_*` under 02 | [02.01.01](02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.01_Batch_Ingestion/README.md) batch, [02.01.02](02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.02_Streaming/README.md) streaming, [02.01.03](02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.03_Near_Real_Time_Ingestion/README.md) near-real-time, [02.01.04](02_Data_Engineering_Architecture/02.01_Data_Ingestion_Architecture/02.01.04_Shared_Foundations/README.md) shared |
| 02.06 | ↳ Data Storage Architecture | `02.06_*` under 02 | Data lake, warehouse, lakehouse, marts, ODS, analytical stores, and storage design patterns. |
| 04 | [Cloud Data Platforms](04_Cloud_Data_Platforms/README.md) | `04_*` | Cloud data platform services across GCP, AWS, and Azure. |
| 05 | [Data Modeling Architecture](04_Data_Modeling_Architecture/README.md) | `05_*` | Traditional, enterprise, modern, and industry reference modeling. |
| 06 | [Data Product Architecture](06_Data_Product_Architecture/README.md) | `06_*` | Data product lifecycle, design, marketplace, data contracts, and product governance. |
| 08 | [Analytics Architecture](08_Analytics_Architecture/README.md) | `08_*` | BI, semantic layer, self-service analytics, dashboards, and analytics tools. |
| 08.10 | ↳ Real Time Analytics Architecture | `08.10_*` under 08 | Real-time analytics engines, streaming analytics stores, and low-latency analytical workloads. |
| 11 | [AI Data Architecture](11_AI_Data_Architecture/README.md) | `11_*` | AI-ready data platforms, feature stores, RAG, vector databases, AI governance, observability, and FinOps. |
| 11.12 | ↳ Agentic AI Architecture | `11.12_*` under 11 | Agent design, MCP/A2A, orchestration, AgentOps, multi-agent systems, and digital workforce. |
| 13 | [MLOps Architecture](13_MLOps_Architecture/README.md) | `13_*` | ML lifecycle, feature engineering, training, deployment, monitoring, and model governance. |
| 14 | [Security And Privacy Architecture](14_Security_And_Privacy_Architecture/README.md) | `14_*` | IAM, encryption, secrets, RLS/CLS, zero trust, compliance, AI security, and privacy engineering. |
| 15 | [Industry Reference Architectures](15_Industry_Reference_Architectures/README.md) | `15_*` | Telecom, banking, insurance, retail, healthcare, manufacturing, and government reference architectures. |
| 16 | [Architecture Interview Preparation](16_Architecture_Interview_Preparation/README.md) | `16_*` | Role-based architecture interview preparation and scenario questions. |
| 17 | [Technology Comparisons](17_Technology_Comparisons/README.md) | `17_*` | Technology comparisons, vendor evaluations, and selection frameworks. |
| 19 | [Templates And Frameworks](19_Templates_And_Frameworks/README.md) | `19_*` | Architecture, HLD, LLD, data product, ADR, and governance templates. |
| 20 | [Pluto MIND](20_Pluto_MIND/README.md) | `20_*` | Pluto MIND product architecture, Acquisition AI, Model AI, Transformation AI, and marketplace. |

## Metadata

- [Taxonomy Registry](_meta/taxonomy.yaml)
- [Parent Hierarchy Report](_meta/parent_hierarchy_report.md)
- [02.01.02 Consolidation Report](_meta/section_02.01.02_consolidation_report.md)
- [Consolidation Report](_meta/consolidation_report.md)
- [Migration Map](_meta/migration_map.yaml)
