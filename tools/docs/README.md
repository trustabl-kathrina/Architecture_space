# Documentation tooling

MkDocs site, document templates, and maintenance scripts for the `docs/` corpus.

## Layout

```
tools/docs/
├── scripts/              # Automation (metadata, indexes, migration, validation)
├── templates/            # Document type templates
├── mkdocs.yml            # MkDocs Material site configuration
├── requirements-docs.txt # Python dependencies for docs tooling
└── .gitignore            # Build artifacts and local env ignores
```

## Common commands

```bash
# Install dependencies
pip install -r tools/docs/requirements-docs.txt

# Serve documentation locally
mkdocs serve -f tools/docs/mkdocs.yml

# Build site (strict)
mkdocs build --strict -f tools/docs/mkdocs.yml

# Refresh section README indexes
powershell -ExecutionPolicy Bypass -File tools/docs/scripts/revamp_taxonomy.ps1 -RefreshOnly

# Validate (Python)
python tools/docs/scripts/validate_front_matter.py
python tools/docs/scripts/validate_links.py
python tools/docs/scripts/status_report.py
```

## Scripts

| Script | Purpose |
| --- | --- |
| `revamp_taxonomy.ps1` | Taxonomy refresh, index generation, link reports |
| `redistribute_pocs.ps1` | Distribute POCs into technology sections |
| `consolidate_single_structure.ps1` | One-time legacy-to-docs consolidation |
| `remove_duplicates.ps1` | Deduplicate content with redirect stubs |
| `add_front_matter.ps1` | Batch YAML front matter injection |

Documentation content lives in [`../../docs/`](../../docs/).
