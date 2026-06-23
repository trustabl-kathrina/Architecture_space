# KEW — Knowledge Engineering Workbench

Local-first AI workbench for enterprise architecture documentation. Edit Markdown in `docs/`, browse the corpus in a React UI, and use Cursor-powered chat with **approval-gated** document changes.

## Monorepo layout

```
Architecture_space/
├── apps/
│   └── workbench/              # React 19 + Vite + Tailwind UI
├── services/
│   └── api/                    # FastAPI gateway (package: kew-api)
├── documentation_ai_factory/   # doc_factory CLI + batch doc generation
├── docs/                       # Markdown corpus (canonical content)
├── tools/
│   └── docs/                   # MkDocs, templates, corpus maintenance
├── archive/                    # Legacy section snapshots
├── .data/                      # Runtime state (conversations, edits, logs)
├── scripts/                    # Setup and dev helpers
├── package.json                # pnpm workspace root
└── pnpm-workspace.yaml
```

See [docs/KEW_PROJECT_STRUCTURE.md](docs/KEW_PROJECT_STRUCTURE.md) for the full tree.

## Prerequisites

| Tool | Version |
|------|---------|
| Python | 3.12 |
| Node.js | ≥ 20 |
| pnpm | ≥ 9 |

## Quick start

### 1. Configure environment

```powershell
copy .env.example .env
# Edit .env — set CURSOR_API_KEY for live chat, or KEW_API_AI_MOCK_MODE=true for offline dev
```

### 2. Install dependencies

```powershell
scripts\setup.cmd
```

Installs Python packages (`kew-api`, `doc_factory`) and frontend deps (`pnpm install`).  
Requires **Python 3.12** and **Node.js 20+** ([nodejs.org](https://nodejs.org/)).

> After installing Node.js for the first time, **close and reopen PowerShell** so `node`/`npm` are on PATH.

### 3. Run the stack

**Terminal A — API** (port 8000):

```powershell
scripts\dev-api.cmd
```

**Terminal B — Workbench** (port 5173):

```powershell
scripts\dev-web.cmd
```

Open http://127.0.0.1:5173 — select a `.md` file, edit in the center panel, chat in the right panel.

## npm / pnpm scripts

| Script | Description |
|--------|-------------|
| `pnpm setup` | Run `scripts/setup.cmd` |
| `pnpm dev` | Start Vite dev server |
| `pnpm dev:api` | Start FastAPI via `kew-api` |
| `pnpm test:api` | Run API pytest suite |
| `pnpm build` | Production build of workbench |
| `pnpm typecheck` | TypeScript check |

## API endpoints

Base URL: `http://127.0.0.1:8000/api/v1`

| Area | Endpoints |
|------|-----------|
| Health | `GET /health`, `GET /ready` |
| Workspace | `GET/POST/PATCH/DELETE /workspace/*` |
| Documents | `GET/PUT /documents` |
| Chat | `POST /chat/conversations`, `POST .../messages`, `POST .../messages/stream` |
| Edits | `GET/POST/DELETE /edits/{id}` |

Interactive docs (development): http://127.0.0.1:8000/docs

## AI chat flow

```
User prompt → Intent detection → Advisory OR change plan → User approval → Apply
```

The AI never writes files directly. Proposed edits are stored in `.data/edits/` until approved. Chat streams SSE events including execution trail steps.

## Documentation factory (CLI)

Batch documentation generation (separate from the workbench UI):

```powershell
.\documentation_ai_factory\.venv\Scripts\Activate.ps1
doc-factory --help
```

## Corpus tooling

MkDocs site and validation scripts:

```powershell
pip install -r tools\docs\requirements-docs.txt
python tools\docs\scripts\validate_front_matter.py
mkdocs serve -f tools\docs\mkdocs.yml
```

See [tools/docs/README.md](tools/docs/README.md).

## Tests

```powershell
scripts\test-api.cmd
```

API tests run in mock AI mode by default (no API key required).
