#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    pnpm dev
} else {
    Set-Location (Join-Path $Root "apps\workbench")
    if (-not (Test-Path "node_modules")) {
        Write-Error "Dependencies not installed. Run .\scripts\setup.ps1 first."
    }
    npx vite
}
