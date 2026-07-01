@echo off
setlocal
call "%~dp0_root.cmd"
call "%~dp0_env.cmd"
set "PY=%ROOT%\backend\doc-factory\.venv\Scripts\python.exe"
if not exist "%PY%" (
  echo Python venv not found. Run deployment\scripts\setup.cmd first.
  exit /b 1
)
cd /d "%ROOT%"
"%PY%" -m kew_api.main
