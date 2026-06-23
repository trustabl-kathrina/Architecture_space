#Requires -Version 5.1
<#
.SYNOPSIS
  Install KEW monorepo dependencies (Python API + doc_factory + pnpm workspace).
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Venv = Join-Path $Root "documentation_ai_factory\.venv"
$Python = "python"

Write-Host "KEW setup - repo root: $Root"

if (-not (Test-Path $Venv)) {
    Write-Host "Creating Python venv at documentation_ai_factory\.venv ..."
    & $Python -m venv $Venv
}

$Pip = Join-Path $Venv "Scripts\pip.exe"
$PythonExe = Join-Path $Venv "Scripts\python.exe"

echo Installing kew-api and doc_factory (editable) ...
$ApiPkg = Join-Path $Root "services\api"
& $Pip install ('-e', ($ApiPkg + '[dev]'))
if ($LASTEXITCODE -ne 0) { throw "kew-api install failed" }

Push-Location (Join-Path $Root "documentation_ai_factory")
& $Pip install -e .
if ($LASTEXITCODE -ne 0) { throw "doc_factory install failed" }
Pop-Location

if (-not (Test-Path (Join-Path $Root ".env"))) {
    Copy-Item (Join-Path $Root ".env.example") (Join-Path $Root ".env")
    Write-Host "Created .env from .env.example - edit GEMINI_API_KEY or enable KEW_API_AI_MOCK_MODE"
}

# Ensure runtime data directories exist
& $PythonExe -c "from kew_api.config.settings import get_settings; get_settings()"
if ($LASTEXITCODE -ne 0) { throw "kew_api import failed after install" }

Write-Host "Installing pnpm workspace dependencies ..."
Push-Location $Root
try {
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        pnpm install
    } elseif (Get-Command corepack -ErrorAction SilentlyContinue) {
        corepack enable 2>$null
        corepack prepare pnpm@9.15.0 --activate 2>$null
        pnpm install
    } else {
        Write-Warning "pnpm not found. Install Node.js 20+ and run: corepack enable && pnpm install"
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Setup complete."
Write-Host "  API:  .\scripts\dev-api.ps1"
Write-Host "  UI:   .\scripts\dev-web.ps1  (or: pnpm dev)"
