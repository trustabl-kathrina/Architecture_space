@echo off
setlocal
call "%~dp0_env.cmd"
set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "PY=%ROOT%\documentation_ai_factory\.venv\Scripts\python.exe"
if not exist "%PY%" (
  echo Python venv not found. Run scripts\setup.cmd first.
  exit /b 1
)
cd /d "%ROOT%"
"%PY%" -m kew_api.main
