# Deployment

Operations, local development, CI references, and documentation site tooling.

```
deployment/
├── scripts/          # Setup, dev servers, API tests (Windows .cmd + PowerShell)
├── mkdocs/           # MkDocs site, corpus validators, templates
└── README.md         # This file
```

## Local development

From the **monorepo root**:

| Task | Command |
|------|---------|
| First-time setup | `deployment\scripts\setup.cmd` or `pnpm setup` |
| API (port 8000) | `deployment\scripts\dev-api.cmd` or `pnpm dev:api` |
| Workbench (port 5173) | `deployment\scripts\dev-web.cmd` or `pnpm dev` |
| API tests | `deployment\scripts\test-api.cmd` or `pnpm test:api` |

Python virtualenv: `backend/doc-factory/.venv` (shared by API + doc-factory).

## CI / GitHub Actions

Workflows remain in [`.github/workflows/`](../.github/workflows/) (GitHub requirement):

| Workflow | Purpose |
|----------|---------|
| `kew-api.yml` | `backend/api` pytest (mock AI) |
| `docs.yml` | Corpus validation + MkDocs build (`deployment/mkdocs/`) |

## MkDocs

```bash
pip install -r deployment/mkdocs/requirements-docs.txt
mkdocs serve -f deployment/mkdocs/mkdocs.yml
```

Corpus validators:

```bash
python deployment/mkdocs/scripts/validate_front_matter.py
python deployment/mkdocs/scripts/validate_links.py
```

## Production (future)

Add Docker Compose, Kubernetes manifests, or cloud IaC under `deployment/` as the stack matures.
