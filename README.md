# KEW — Knowledge Engineering Workbench

Local-first AI workbench for enterprise architecture documentation. Edit Markdown in `docs/`, browse the corpus in a React UI, and use Cursor-powered chat with **approval-gated** document changes.

## Four-folder layout

```
Architecture_space/
├── frontend/                   # React workbench (Vite + Tailwind)
├── backend/
│   ├── api/                    # FastAPI gateway (kew-api)
│   └── doc-factory/            # Batch documentation engine (CLI)
├── deployment/
│   ├── scripts/                # Setup + dev helpers
│   └── mkdocs/                 # Site build + corpus validators
├── docs/
│   ├── product/                # KEW application documentation
│   ├── archive/                # Legacy section snapshots
│   └── …                       # Architecture corpus (pillars, hubs, meta)
├── .data/                      # Runtime state (gitignored)
├── .github/workflows/          # CI (see deployment/README.md)
├── package.json                # pnpm workspace root
└── .env                        # Secrets + API config
```

See [docs/product/KEW_PROJECT_STRUCTURE.md](docs/product/KEW_PROJECT_STRUCTURE.md) for the full tree.

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
deployment\scripts\setup.cmd
# or: pnpm setup
```

### 3. Run the stack

**Terminal A — API** (port 8000):

```powershell
deployment\scripts\dev-api.cmd
```

**Terminal B — Workbench** (port 5173):

```powershell
deployment\scripts\dev-web.cmd
```

Open http://127.0.0.1:5173 — select a `.md` file, edit in the center panel, chat in the right panel.

## npm / pnpm scripts

| Script | Description |
|--------|-------------|
| `pnpm setup` | Run `deployment/scripts/setup.cmd` |
| `pnpm dev` | Start Vite dev server |
| `pnpm dev:api` | Start FastAPI via `kew-api` |
| `pnpm test:api` | Run API pytest suite |
| `pnpm build` | Production build of workbench |

## AI providers

| Variable | Purpose |
|----------|---------|
| `CURSOR_API_KEY` | Primary agent provider (Cursor SDK) |
| `GEMINI_API_KEY` | Optional fallback / doc-factory |
| `KEW_API_AI_MOCK_MODE=true` | Offline deterministic responses |

## License

Internal enterprise architecture knowledge base — see corpus governance in `docs/product/CONTRIBUTING.md`.
