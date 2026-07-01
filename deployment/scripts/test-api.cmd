@echo off
setlocal
call "%~dp0_root.cmd"
set "PYTEST=%ROOT%\backend\doc-factory\.venv\Scripts\pytest.exe"
if not exist "%PYTEST%" (
  echo pytest not found. Run deployment\scripts\setup.cmd first.
  exit /b 1
)
set KEW_API_AI_MOCK_MODE=true
"%PYTEST%" "%ROOT%\backend\api\tests" %*
