# Parent hierarchy reorganization report

Generated: 2026-06-18

## Summary

Five former top-level sections were nested under parent folders. Flat legacy numbers (03, 07, 09, 10, 12) are **retired**; hierarchical IDs are used at every level.

| Former flat # | Current domain ID | Parent | Path |
| --- | --- | --- | --- |
| 07 | **00.10** | 00 Architecture Governance | `00_Architecture_Governance/10_Data_Governance_And_Metadata/` |
| 03 | **02.05** | 02 Data Engineering | `02_Data_Engineering_Architecture/05_Data_Storage_Architecture/` |
| 09 | **02.07** | 02 Data Engineering | `02_Data_Engineering_Architecture/01_Data_Ingestion_Architecture/02_Streaming/` |
| 10 | **08.10** | 08 Analytics | `08_Analytics_Architecture/10_Real_Time_Analytics_Architecture/` |
| 12 | **11.12** | 11 AI Data | `11_AI_Data_Architecture/12_Agentic_AI_Architecture/` |

## Numbering scheme

| Level | Example | Applies to |
| --- | --- | --- |
| Parent section | `02` | `02_Data_Engineering_Architecture/` |
| Nested domain | `02.07` | `01_Data_Ingestion_Architecture/02_Streaming/` |
| Subsection | `02.01.02.01` | `01_Fundamentals/` |
| Topic group | `02.01.02.01.01` | `01_Overview/` |
| Sequenced file | `02.01.02.01.01.01` | `02.01.02.01.01.01_What_Is_*.md` |

Folder names, taxonomy `id`, front matter `section:`, and cross-links all follow this scheme.

## Scripts

- `tools/docs/scripts/apply_parent_hierarchy.ps1` — folder renames, internal prefix renumbering, link and front matter updates
- `tools/docs/scripts/repair_parent_hierarchy_link_damage.ps1` — fixes cross-prefix corruption
- `tools/docs/scripts/update_hierarchical_section_numbers.ps1` — retires legacy section number prose references

## Metadata

- `docs/_meta/taxonomy.yaml` — domain entries use IDs `02.05`, `00.10`, `02.07`, `08.10`, `11.12`
- `docs/README.md`, `docs/CONTRIBUTING.md`, `tools/docs/mkdocs.yml`
