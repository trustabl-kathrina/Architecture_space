#Requires -Version 5.1
<#
.SYNOPSIS
  Start API and workbench dev servers (API in a new window).
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $PSScriptRoot "dev-api.ps1")
)

Start-Sleep -Seconds 2
Set-Location $Root
& (Join-Path $PSScriptRoot "dev-web.ps1")
