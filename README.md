# Architecture Space

Enterprise architecture documentation and tooling in a two-folder layout.

| Folder | Purpose |
| --- | --- |
| [`docs/`](docs/) | Architecture documentation (20 sections, hubs, metadata) |
| [`code/`](code/) | Scripts, templates, MkDocs config, and CI tooling |

## Quick links

- [Browse documentation](docs/README.md)
- [Contributing guide](docs/CONTRIBUTING.md)
- [Tooling and local docs site](code/README.md)

## Local docs site

```bash
pip install -r code/requirements-docs.txt
mkdocs serve -f code/mkdocs.yml
```
