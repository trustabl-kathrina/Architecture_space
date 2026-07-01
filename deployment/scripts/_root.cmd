@echo off
REM Resolve monorepo root from deployment/scripts/
set "ROOT=%~dp0..\.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
