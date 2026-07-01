@echo off
setlocal EnableExtensions
call "%~dp0_root.cmd"
call "%~dp0_env.cmd"
cd /d "%ROOT%"

if exist "%ROOT%\node_modules\.modules.yaml" (
  call pnpm dev
  exit /b %errorlevel%
)

if exist "%ROOT%\frontend\node_modules" (
  pushd "%ROOT%\frontend"
  call npm run dev
  popd
  exit /b %errorlevel%
)

where pnpm >nul 2>&1
if not errorlevel 1 (
  echo Installing frontend dependencies...
  call pnpm install
  if errorlevel 1 exit /b 1
  call pnpm dev
  exit /b %errorlevel%
)

where npm >nul 2>&1
if not errorlevel 1 (
  echo Installing frontend dependencies with npm...
  pushd "%ROOT%\frontend"
  call npm install
  if errorlevel 1 exit /b 1
  call npm run dev
  popd
  exit /b %errorlevel%
)

echo.
echo Node.js is not installed or not on PATH.
echo   1. Install Node.js 20+ from https://nodejs.org/
echo   2. Close and reopen PowerShell
echo   3. Run: deployment\scripts\setup.cmd
exit /b 1
