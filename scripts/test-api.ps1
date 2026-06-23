#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Venv = Join-Path $Root "documentation_ai_factory\.venv"
$Pytest = Join-Path $Venv "Scripts\pytest.exe"

if (-not (Test-Path $Pytest)) {
    Write-Error "pytest not installed. Run .\scripts\setup.ps1 first."
}

$env:KEW_API_AI_MOCK_MODE = "true"
& $Pytest (Join-Path $Root "services\api\tests") @args
