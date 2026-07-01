# KEW — Complete Project Structure

**Product:** Knowledge Engineering Workbench  
**Monorepo root:** `Architecture_space/`  
**Layout:** Four top-level application folders — `frontend`, `backend`, `deployment`, `docs`.

---

## 1. Monorepo structure

```
Architecture_space/
├── frontend/                       # @kew/workbench — React SPA
│   ├── public/
│   ├── src/
│   │   ├── features/
│   │   │   ├── ai/                 # Chat panel, streaming, change plans
│   │   │   ├── editor/             # Tiptap + preview + multi-tab
│   │   │   └── workspace/          # Doc tree + folder planning
│   │   ├── layout/
│   │   └── shared/
│   ├── index.html
│   ├── package.json
│   └── vite.config.ts
│
├── backend/
│   ├── api/                        # kew-api — FastAPI gateway
│   │   ├── src/kew_api/
│   │   │   ├── ai/                 # Cursor runner, editor, folder planner
│   │   │   ├── api/v1/             # REST routes
│   │   │   ├── config/             # Settings + logging
│   │   │   ├── prompts/            # Chat agent prompts
│   │   │   ├── schemas/            # Pydantic models
│   │   │   └── services/           # Business logic
│   │   ├── tests/
│   │   └── pyproject.toml
│   │
│   └── doc-factory/                # doc_factory — CLI batch engine
│       └── src/doc_factory/
│
├── deployment/
│   ├── scripts/                    # setup, dev-api, dev-web, test-api
│   └── mkdocs/                     # MkDocs, validators, templates
│
├── docs/
│   ├── product/                    # KEW app docs (this file, agent flow, contributing)
│   ├── archive/                    # Legacy section snapshots
│   ├── 00_Architecture_Governance/ # Architecture corpus (canonical content)
│   ├── …                           # Numbered pillars + _hubs + _meta
│   └── README.md                   # Corpus overview
│
├── .data/                          # Local runtime (gitignored)
│   ├── conversations/
│   ├── edits/
│   ├── logs/
│   └── runs/
│
├── .github/workflows/              # CI (API tests, corpus validation, MkDocs)
├── package.json
├── pnpm-workspace.yaml
├── .env.example
└── README.md
```

---

## 2. Frontend (`frontend/src`)

```
src/
├── App.tsx
├── AppProviders.tsx
├── layout/WorkbenchShell.tsx
├── features/
│   ├── workspace/                  # Doc tree, tabs, folder planning panel
│   ├── editor/                     # Tiptap, save-to-disk, change review
│   └── ai/                         # Chat, Agent/Plan modes, streaming
└── shared/                         # API client, types, env
```

---

## 3. Backend (`backend/api/src/kew_api`)

```
kew_api/
├── main.py
├── config/settings.py              # KEW_API_* + path resolution
├── api/v1/                         # health, workspace, documents, chat
├── services/                       # document, chat, diff, workspace
├── ai/                             # Cursor/Gemini runners, editor, folder plan
└── prompts/                        # orchestrator, advisor, editor, folder agents
```

Batch pipeline agents: `backend/doc-factory/src/doc_factory/agents/`.

---

## 4. Deployment (`deployment/`)

| Path | Role |
|------|------|
| `scripts/` | Local dev: venv setup, API + Vite launch, pytest |
| `mkdocs/` | Public docs site, link/front-matter validators, templates |

CI workflows live in `.github/workflows/` (GitHub requirement).

---

## 5. Documentation (`docs/`)

| Area | Path | Audience |
|------|------|----------|
| Product / KEW | `docs/product/` | Developers building the workbench |
| Architecture corpus | `docs/00_*` … `docs/09_*`, `_hubs`, `_meta` | Architects + workbench content |
| Legacy | `docs/archive/` | Historical snapshots |

The workbench reads and writes the **corpus** under `docs/` (not `docs/product/`).

---

## 6. Configuration

| Layer | Location | Prefix |
|-------|----------|--------|
| API | `.env` at monorepo root | `KEW_API_*` |
| Secrets | Same `.env` | `CURSOR_API_KEY`, `GEMINI_API_KEY` |
| Frontend | `frontend/.env` (optional) | `VITE_*` |
| Doc factory | `backend/doc-factory/.env` | `DOC_FACTORY_*` |

---

## 7. Build & run

| Artifact | Command | Output |
|----------|---------|--------|
| API (dev) | `deployment/scripts/dev-api.cmd` | Uvicorn :8000 |
| Web (dev) | `deployment/scripts/dev-web.cmd` | Vite :5173 |
| API (test) | `deployment/scripts/test-api.cmd` | pytest |
| Web (prod) | `pnpm build` | `frontend/dist/` |
| Docs site | `mkdocs build -f deployment/mkdocs/mkdocs.yml` | `deployment/mkdocs/site/` |

---

## 8. Data flow

```
docs/  ←── PUT /documents ←── manual Save to disk
  ↑
  └── POST /edits/{id}/apply ←── approved Agent change plan

.data/conversations/  ← chat history
.data/edits/          ← pending change plans
```

---

## 9. Responsibility map

| Concern | Location |
|---------|----------|
| Workbench UI | `frontend/` |
| REST + chat API | `backend/api/` |
| Batch doc generation | `backend/doc-factory/` |
| Dev scripts + MkDocs | `deployment/` |
| KEW technical docs | `docs/product/` |
| Architecture knowledge | `docs/` (corpus pillars) |
| Runtime state | `.data/` |
