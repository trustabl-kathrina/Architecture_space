#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    pnpm dev
} else {
    Set-Location (Join-Path $Root "frontend")
    if (-not (Test-Path "node_modules")) {
        Write-Error "Dependencies not installed. Run .\deployment\scripts\setup.ps1 first."
    }
    npx vite
}
