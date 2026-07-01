#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Venv = Join-Path $Root "backend\doc-factory\.venv"
$Pytest = Join-Path $Venv "Scripts\pytest.exe"

if (-not (Test-Path $Pytest)) {
    Write-Error "pytest not installed. Run .\deployment\scripts\setup.ps1 first."
}

$env:KEW_API_AI_MOCK_MODE = "true"
& $Pytest (Join-Path $Root "backend\api\tests") @args
