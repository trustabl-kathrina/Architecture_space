#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Venv = Join-Path $Root "backend\doc-factory\.venv"
$KewApi = Join-Path $Venv "Scripts\kew-api.exe"

if (-not (Test-Path $KewApi)) {
    Write-Error "kew-api not installed. Run .\deployment\scripts\setup.ps1 first."
}

Set-Location $Root
& $KewApi
