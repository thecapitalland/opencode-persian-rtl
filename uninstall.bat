@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
echo Closing OpenCode if it is running...
taskkill /IM OpenCode.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
echo Restoring original OpenCode...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
if errorlevel 1 (
  echo.
  echo Uninstall failed.
  pause
  exit /b 1
)
echo.
echo Restored.
pause