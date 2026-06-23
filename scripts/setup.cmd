@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "VENV=%ROOT%\documentation_ai_factory\.venv"
set "PIP=%VENV%\Scripts\pip.exe"
set "PY=%VENV%\Scripts\python.exe"
set "SITE=%VENV%\Lib\site-packages"

echo KEW setup - repo root: %ROOT%

if not exist "%PY%" (
  echo Creating Python venv...
  python -m venv "%VENV%"
  if errorlevel 1 (
    echo Failed to create venv. Install Python 3.12 and try again.
    exit /b 1
  )
)

REM Remove corrupted partial installs from failed pip runs
for /d %%D in ("%SITE%\~ew-api*") do rmdir /s /q "%%D" 2>nul
for /d %%D in ("%SITE%\~ew_api*") do rmdir /s /q "%%D" 2>nul
for /d %%D in ("%SITE%\~kew-api*") do rmdir /s /q "%%D" 2>nul
for /d %%D in ("%SITE%\~kew_api*") do rmdir /s /q "%%D" 2>nul

echo Installing kew-api...
echo If pip warns about kew-api.exe in use, close any running API terminal and ignore if import succeeds.
pushd "%ROOT%\services\api"
"%PIP%" install -e ".[dev]" --no-cache-dir
set "PIP_RC=%ERRORLEVEL%"
popd

"%PY%" -c "from kew_api.config.settings import get_settings; get_settings()"
if errorlevel 1 (
  if not "%PIP_RC%"=="0" echo kew-api install failed.
  echo Close terminals running the API, then rerun scripts\setup.cmd
  exit /b 1
)
if not "%PIP_RC%"=="0" (
  echo NOTE: pip could not update kew-api.exe ^(file in use^). Using python -m kew_api.main instead.
)

echo Installing doc_factory...
pushd "%ROOT%\documentation_ai_factory"
"%PIP%" install -e .
if errorlevel 1 (
  echo doc_factory install failed.
  popd
  exit /b 1
)
popd

if not exist "%ROOT%\.env" (
  copy "%ROOT%\.env.example" "%ROOT%\.env" >nul
  echo Created .env from .env.example
)

cd /d "%ROOT%"

call "%~dp0_env.cmd"

set "NODE_OK=0"
where node >nul 2>&1 && set "NODE_OK=1"

if "%NODE_OK%"=="1" (
  where pnpm >nul 2>&1
  if errorlevel 1 (
    echo Installing pnpm...
    call npm install -g pnpm@9.15.0
    if exist "%APPDATA%\npm" set "PATH=%APPDATA%\npm;%PATH%"
  )
  echo Installing frontend dependencies with pnpm...
  call pnpm install
  if errorlevel 1 exit /b 1
) else (
  where npm >nul 2>&1
  if not errorlevel 1 (
    echo pnpm not found - using npm in apps\workbench...
    pushd "%ROOT%\apps\workbench"
    call npm install
    if errorlevel 1 (
      popd
      exit /b 1
    )
    popd
  ) else (
    echo ERROR: Node.js not found. Install from https://nodejs.org/ then rerun scripts\setup.cmd
    exit /b 1
  )
)

echo.
echo Setup complete.
echo   API:  scripts\dev-api.cmd
echo   UI:   scripts\dev-web.cmd
