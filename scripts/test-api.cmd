@echo off
setlocal
set "ROOT=%~dp0.."
set "PYTEST=%ROOT%\documentation_ai_factory\.venv\Scripts\pytest.exe"
if not exist "%PYTEST%" (
  echo pytest not found. Run scripts\setup.cmd first.
  exit /b 1
)
set KEW_API_AI_MOCK_MODE=true
"%PYTEST%" "%ROOT%\services\api\tests" %*
