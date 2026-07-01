# Contributing to Architecture Space

Thank you for contributing to the architecture documentation. This guide explains how to add, update, migrate, and review content in `docs/`.

## Before you start

1. Read the [repository README](../README.md) and [docs README](README.md).
2. Check `status` in front matter — do not expand `stub` files without updating status.
3. Use the correct [template](../../deployment/mkdocs/templates/) for your document type.
4. Check the [migration map](_meta/migration_map.yaml) before creating new canonical docs.

## Document types

| Type | Template | Use when |
| --- | --- | --- |
| Overview | `deployment/mkdocs/templates/overview.md` | Section introductions, `What_Is_*`, vision docs |
| Concept | `deployment/mkdocs/templates/concept.md` | Fundamentals, patterns, technical primers |
| Evaluation | `deployment/mkdocs/templates/evaluation.md` | Vendor/platform selection, benchmarks |
| ADR | `deployment/mkdocs/templates/adr.md` | Architecture Decision Records in `*_ADR/` folders |
| Hub | Existing hub pattern | Cross-section indexes in `_hubs/` |
| Interview | Section skeleton | Interview preparation and scenario questions |
| POC | Evaluation/concept | Benchmarks and proof-of-concepts in technology sections |

## Naming conventions

- **Content root:** `docs/`
- **Parent sections:** `NN_Topic_Name/` (e.g. `02_Data_Engineering_Architecture/`)
- **Nested domains:** `NN.MM_Topic_Name/` under a parent (e.g. `01_Data_Ingestion_Architecture/02_Streaming/`)
- **Subsections:** `NN.MM_Topic_Name/` or `NN.MM.SS_Topic_Name/` for topic groups
- **Files:** sequenced prefixes where applicable (`02.01.02.01.01.01_Topic.md`) or `Topic_Name.md` in Pascal_Snake_Case
- **Hubs:** `_hubs/Topic_Hub.md`
- **Metadata:** `_meta/taxonomy.yaml`, `_meta/migration_map.yaml`, `_meta/poc_index.md`

## Active taxonomy

| Range | Sections |
| --- | --- |
| Foundations | `00_Architecture_Governance` (incl. `00.10` governance), `01_Data_Architecture` |
| Data Platform | `02_Data_Engineering_Architecture` (incl. `02.05` storage, `02.01.02` streaming under `02.01`), `04`–`06` |
| Analytics and AI | `08_Analytics_Architecture` (incl. `08.10` real-time), `11_AI_Data_Architecture` (incl. `11.12` agentic), `13_MLOps_Architecture` |
| Assurance and Industry | `14_Security_And_Privacy_Architecture`, `15_Industry_Reference_Architectures` |
| Practitioner | `16_Architecture_Interview_Preparation` through `19_Templates_And_Frameworks` |
| Product | `20_Pluto_MIND` |

Use hierarchical IDs **02.05**, **00.10**, **02.01.02** (streaming under data ingestion), **08.10**, and **11.12** at every level.

POCs and benchmarks live in the relevant technology section (see [POC Index](_meta/poc_index.md)).

## Front matter (required)

```yaml
---
title: Document Title
section: "11.03"
status: draft          # stub | draft | review | complete
template: evaluation   # overview | concept | evaluation | adr | hub | interview | poc | redirect
last_reviewed: 2026-06-18
owner: architecture-team
tags: [genai, rag]
canonical: true
---
```

### Status transitions

| From | To | Criteria |
| --- | --- | --- |
| `stub` | `draft` | Author has replaced template placeholders with real content |
| `draft` | `review` | Self-reviewed, links validated, ready for peer review |
| `review` | `complete` | Approved by section owner or architecture review board |

## Linking conventions

- **Up:** Link to the section README and relevant `_hubs/` page.
- **Across:** Link related topics in other sections (use relative paths).
- **Canonical:** For duplicate topics, link to the canonical doc or a hub:

  ```markdown
  > See also: [FinOps Hub](../_hubs/FinOps_Hub.md)
  ```

## Diagrams

- Prefer **mermaid** diagrams embedded in markdown.
- Include at least one diagram in overview and reference architecture documents.

## Workflow

1. Create or edit the markdown file under `docs/`.
2. Refresh indexes if needed:
   ```powershell
   powershell -ExecutionPolicy Bypass -File deployment/mkdocs/scripts/revamp_taxonomy.ps1 -RefreshOnly
   ```
3. Validate when Python is available:
   ```bash
   python deployment/mkdocs/scripts/validate_front_matter.py
   python deployment/mkdocs/scripts/validate_links.py
   ```
4. Submit a pull request with a clear summary of what changed and why.

## What not to do

- Do not leave `Vendor A`–`Vendor J` placeholders in `draft` or `complete` docs.
- Do not use the evaluation template for ADR files.
- Do not create duplicate canonical topics — extend the canonical doc or add a short domain-specific delta.

## Tooling

See [deployment/mkdocs/README.md](../../deployment/mkdocs/README.md) for scripts, MkDocs, and CI details.
