# KEW — Complete Project Structure

**Product:** Knowledge Engineering Workbench  
**Monorepo root:** `Architecture_space/`  
**Strategy:** `documentation_ai_factory` is the batch AI engine; `apps/workbench` and `services/api` are the interactive workbench deployables.

---

## 1. Monorepo structure

```
Architecture_space/
├── .data/                          # Local runtime (gitignored except .gitkeep)
│   ├── conversations/              # Chat session JSON
│   ├── edits/                      # Pending change plans
│   ├── logs/                       # API logs (production)
│   ├── output/                     # Staged exports
│   └── runs/                       # Pipeline run artifacts
│
├── .github/
│   └── workflows/
│       ├── docs.yml                # Corpus validation + MkDocs build
│       └── kew-api.yml             # API pytest (mock AI mode)
│
├── apps/
│   └── workbench/                  # @kew/workbench — React SPA
│       ├── public/
│       ├── src/
│       │   ├── features/
│       │   │   ├── ai/             # Chat panel, streaming, change plans
│       │   │   ├── editor/         # Tiptap + preview + multi-tab
│       │   │   └── workspace/      # Doc tree + DnD
│       │   ├── layout/
│       │   └── shared/
│       ├── index.html
│       ├── package.json
│       └── vite.config.ts
│
├── services/
│   └── api/                        # kew-api — FastAPI gateway
│       ├── src/kew_api/
│       │   ├── ai/                 # Cursor runner, editor, structured output
│       │   ├── api/v1/             # REST routes
│       │   ├── config/             # Settings + logging
│       │   ├── prompts/            # Chat agent prompts
│       │   ├── schemas/            # Pydantic models
│       │   └── services/           # Business logic
│       ├── tests/
│       └── pyproject.toml
│
├── documentation_ai_factory/       # doc_factory — CLI batch engine
│   └── src/doc_factory/
│
├── docs/                           # Markdown corpus (Git-tracked, canonical)
│   └── KEW_PROJECT_STRUCTURE.md    # This file
│
├── tools/
│   └── docs/                       # MkDocs, templates, corpus maintenance
│       ├── scripts/
│       ├── templates/
│       └── mkdocs.yml
│
├── archive/                        # Legacy section snapshots (pre-consolidation)
│
├── scripts/                        # KEW setup + dev helpers (.cmd / .ps1)
├── package.json
├── pnpm-workspace.yaml
├── .env.example
└── README.md
```

---

## 2. Frontend structure (`apps/workbench/src`)

```
src/
├── App.tsx
├── AppProviders.tsx                # TanStack Query
├── main.tsx
├── globals.css
│
├── layout/
│   └── WorkbenchShell.tsx          # Header + sidebar + editor + chat
│
├── features/
│   ├── workspace/
│   │   ├── api/workspaceApi.ts
│   │   ├── components/             # DocTree, Sidebar, EditorTabBar, …
│   │   ├── hooks/
│   │   └── stores/workspaceStore.ts
│   │
│   ├── editor/
│   │   ├── api/documentsApi.ts
│   │   ├── components/             # TiptapEditor, MarkdownPreview, …
│   │   ├── hooks/
│   │   ├── lib/                    # frontMatter, markdown, normalize
│   │   └── stores/editorStore.ts
│   │
│   └── ai/
│       ├── api/                    # chatApi, chatStreamApi, editsApi
│       ├── components/             # ChatPanel, ExecutionTrailPanel, …
│       ├── hooks/useChat.ts
│       └── stores/chatStore.ts
│
└── shared/
    ├── api/client.ts
    ├── config/env.ts
    ├── types/                      # workspace, document, chat
    └── utils/cn.ts
```

---

## 3. Backend structure (`services/api/src/kew_api`)

```
kew_api/
├── main.py                         # create_app() + kew-api CLI
├── exceptions.py
│
├── config/
│   ├── settings.py                 # ApiSettings (KEW_API_* prefix)
│   └── logging.py
│
├── api/
│   ├── deps.py                     # FastAPI DI
│   ├── errors.py                   # Exception handlers + CORS
│   └── v1/
│       ├── router.py
│       ├── health.py
│       ├── workspace.py
│       ├── documents.py
│       └── chat.py                 # Chat + SSE stream + edits
│
├── schemas/
│   ├── common.py
│   ├── workspace.py
│   ├── document.py
│   └── chat.py
│
├── services/
│   ├── filesystem_guard.py
│   ├── workspace_service.py
│   ├── document_service.py
│   ├── chat_service.py
│   ├── chat_repository.py
│   ├── chat_streaming.py
│   ├── execution_trail.py
│   ├── diff_service.py
│   ├── markdown_utils.py
│   └── markdown_normalize.py
│
├── ai/
│   ├── cursor_runner.py            # Cursor SDK structured output
│   ├── cursor_worker.py
│   ├── cursor_pool.py
│   ├── bridge_manager.py           # Windows-safe bridge daemon
│   ├── cursor_bridge_compat.py
│   ├── editor_runner.py            # JSON + markdown fallback
│   ├── structured.py               # JSON repair + coercion
│   ├── intent_heuristics.py
│   └── prompts.py
│
└── prompts/
    ├── orchestrator.txt
    ├── advisor.txt
    └── editor.txt
```

---

## 4. Agents structure

| Agent | Provider | Role |
|-------|----------|------|
| Orchestrator | Cursor (or Gemini) | Intent classification |
| Advisor | Cursor (or Gemini) | Q&A, suggestions (no file writes) |
| Editor | Cursor (or Gemini) | Proposed markdown body + diff hunks |

Interactive chat agents live in `services/api/src/kew_api/ai/`.  
Batch pipeline agents live in `documentation_ai_factory/src/doc_factory/agents/`.

---

## 5. Configuration

| Layer | Location | Prefix |
|-------|----------|--------|
| API | `.env` at monorepo root | `KEW_API_*` |
| Secrets | Same `.env` | `CURSOR_API_KEY`, `GEMINI_API_KEY`, `TAVILY_API_KEY` |
| Frontend | `apps/workbench/.env` | `VITE_*` |

Load order: defaults → `.env` files → environment variables.

---

## 6. Build strategy

| Artifact | Command | Output |
|----------|---------|--------|
| API (dev) | `scripts/dev-api.cmd` | Uvicorn on :8000 |
| API (test) | `scripts/test-api.cmd` | pytest |
| Web (dev) | `scripts/dev-web.cmd` | Vite on :5173, proxies `/api` |
| Web (prod) | `pnpm build` | `apps/workbench/dist/` |
| Engine CLI | `doc-factory` | Batch doc generation |
| Docs site | `mkdocs build -f tools/docs/mkdocs.yml` | `tools/docs/site/` |

---

## 7. Data flow

```
docs/  ←── PUT /documents ←── user editor (autosave)
  ↑
  └── POST /edits/{id}/apply ←── approved change plan

.data/conversations/  ← chat history JSON
.data/edits/          ← pending change plans
```

---

## 8. What lives where

| Concern | Location |
|---------|----------|
| Canonical content | `docs/` |
| Workbench UI | `apps/workbench/` |
| REST + chat API | `services/api/` |
| Batch doc generation | `documentation_ai_factory/` |
| Corpus templates + MkDocs | `tools/docs/` |
| Local runtime state | `.data/` (gitignored) |
| Legacy snapshots | `archive/` |
| Dev/setup scripts | `scripts/` |
