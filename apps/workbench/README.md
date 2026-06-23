# KEW Workbench

React + TypeScript frontend for the Knowledge Engineering Workbench.

## Dev

From monorepo root:

```powershell
pnpm dev
# or
..\..\scripts\dev-web.ps1
```

Requires the API running on port 8000 (`pnpm dev:api` or `scripts/dev-api.ps1`). Vite proxies `/api` to the backend.

## Environment

Copy `.env.example` to `.env` (optional — defaults work with the Vite proxy):

```
VITE_API_BASE_URL=/api/v1
```

## Structure

See [docs/KEW_PROJECT_STRUCTURE.md](../../docs/KEW_PROJECT_STRUCTURE.md#2-frontend-structure-appsworkbenchsrc).
