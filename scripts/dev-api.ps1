#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Venv = Join-Path $Root "documentation_ai_factory\.venv"
$KewApi = Join-Path $Venv "Scripts\kew-api.exe"

if (-not (Test-Path $KewApi)) {
    Write-Error "kew-api not installed. Run .\scripts\setup.ps1 first."
}

Set-Location $Root
& $KewApi
