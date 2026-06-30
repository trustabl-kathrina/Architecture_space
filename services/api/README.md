# KEW API

FastAPI gateway for the Knowledge Engineering Workbench.

## Install

From the monorepo root (recommended):

```powershell
..\..\scripts\setup.ps1
```

Or manually:

```powershell
python -m venv ..\..\documentation_ai_factory\.venv
..\..\documentation_ai_factory\.venv\Scripts\Activate.ps1
pip install -e .[dev]
```

## Run

```powershell
kew-api
```

Environment is loaded from `Architecture_space/.env`. See `.env.example` at the repo root for all `KEW_API_*` variables.

### AI chat providers

| Provider | Env var | Notes |
|----------|---------|-------|
| **Cursor** (default when key present) | `CURSOR_API_KEY` | [Dashboard → Integrations](https://cursor.com/dashboard/integrations) |
| Gemini (optional) | `GEMINI_API_KEY` | Set `KEW_API_AI_PROVIDER=gemini` |
| Mock (offline) | `KEW_API_AI_MOCK_MODE=true` | No API key required |

`KEW_API_AI_PROVIDER=auto` prefers Cursor when both keys are set.

## Test

```powershell
$env:KEW_API_AI_MOCK_MODE="true"
pytest tests -q
```

## Package layout

```
src/kew_api/
├── main.py           # App factory + CLI entrypoint
├── api/v1/           # REST routes
├── services/         # Domain logic
├── ai/               # Cursor SDK + Gemini ADK agents
├── prompts/          # Agent prompt templates
└── config/           # Settings + logging
```

Chat agent architecture (Plan vs Agent modes, multi-agent folder pipeline, lineage): see [`docs/KEW_CHAT_AGENT_FLOW.md`](../../docs/KEW_CHAT_AGENT_FLOW.md).
