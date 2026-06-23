@echo off
REM Ensure Node.js and npm global bin are on PATH for this session.
if exist "%ProgramFiles%\nodejs\node.exe" (
  set "PATH=%ProgramFiles%\nodejs;%PATH%"
)
if exist "%LocalAppData%\Programs\nodejs\node.exe" (
  set "PATH=%LocalAppData%\Programs\nodejs;%PATH%"
)
if exist "%APPDATA%\npm" (
  set "PATH=%APPDATA%\npm;%PATH%"
)

REM Activate pnpm via corepack when available (skip if not writable).
where corepack >nul 2>&1
if not errorlevel 1 (
  call corepack enable >nul 2>&1
  call corepack prepare pnpm@9.15.0 --activate >nul 2>&1
)

REM Fallback: user-global pnpm installed via npm.
where pnpm >nul 2>&1
if errorlevel 1 (
  where npm >nul 2>&1
  if not errorlevel 1 (
    call npm install -g pnpm@9.15.0 >nul 2>&1
    if exist "%APPDATA%\npm" set "PATH=%APPDATA%\npm;%PATH%"
  )
)
