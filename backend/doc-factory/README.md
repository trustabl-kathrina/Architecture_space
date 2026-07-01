# Documentation AI Factory

Local-first, AI-powered documentation and research platform for **Architecture Space**.

Automates web research, planning, and Markdown generation for enterprise architecture topics (Data Engineering, Streaming, Data Mesh, Kafka, Flink, Airflow, dbt, BigQuery, and more) using **Google ADK**, **Gemini**, and **Tavily**.

> **Status:** v0.2.0 — Multi-agent pipeline with Planner, Research, Structure, Writer,
> Benchmark, Comparison, Reviewer, and Markdown Publisher.

## Prerequisites

| Requirement | Version |
| --- | --- |
| Python | 3.12.x |
| OS | Windows 10/11 (also works on macOS/Linux) |
| API keys | [Gemini API](https://aistudio.google.com/apikey), [Tavily](https://tavily.com/) |

## Quick setup (Windows + Cursor)

```powershell
# 1. Navigate to the factory project
cd documentation_ai_factory

# 2. Create and activate a virtual environment (Python 3.12)
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1

# 3. Install dependencies
pip install -U pip
pip install -r requirements-dev.txt

# 4. Install package in editable mode
pip install -e .

# 5. Configure secrets
Copy-Item .env.example .env
# Edit .env and set GEMINI_API_KEY and TAVILY_API_KEY

# 6. Verify installation
doc-factory --help
pytest
```

## ADK Web UI (after agents are implemented)

```powershell
# From documentation_ai_factory/ with .env loaded
adk web src/doc_factory/agents
```

## CLI commands

| Command | Purpose |
| --- | --- |
| `doc-factory generate TOPIC` | Full multi-agent pipeline + Markdown publish |
| `doc-factory benchmark TOPIC` | Standalone benchmark evaluation (e.g. Apache Flink) |
| `doc-factory new TOPIC` | Create a run without executing |
| `doc-factory run RUN_ID` | Execute pipeline for existing run |
| `doc-factory status [RUN_ID]` | Show run status |
| `doc-factory export RUN_ID` | Re-export Markdown from saved artifacts |
| `doc-factory promote RUN_ID` | Promote staging → `docs/` (dry-run by default) |

## Project layout

```
documentation_ai_factory/
├── src/doc_factory/     # Application package
├── tests/               # Unit and contract tests
├── runs/                # Run artifacts (gitignored)
├── output/              # Staging Markdown (gitignored)
├── docs/                # Platform architecture documentation
├── requirements.txt     # Runtime dependencies
└── pyproject.toml       # Package metadata and tooling
```

See [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) for the complete file tree and responsibilities.

## Configuration

Configuration uses a **three-layer** strategy:

1. **Environment variables** — secrets and overrides (`.env`, see `.env.example`)
2. **`config/defaults.yaml`** — non-secret pipeline defaults
3. **`taxonomy/*.yaml`** — topic routing and template catalog

Loaded via `doc_factory.config.settings.get_settings()`.

## Relationship to Architecture Space

| Reads | Writes (MVP) |
| --- | --- |
| `../docs/` (canonical content) | `output/{run_id}/` (staging) |
| `../tools/docs/templates/` | `runs/{run_id}/` (artifacts) |
| `../tools/docs/scripts/doc_utils.py` conventions | `../docs/` (post-review promote only) |

## Development

```powershell
# Lint
ruff check src tests

# Type check
mypy src

# Tests with coverage
pytest --cov=doc_factory
```

## License

MIT
