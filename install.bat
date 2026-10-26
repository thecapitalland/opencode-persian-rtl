@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
echo Closing OpenCode if it is running...
taskkill /IM OpenCode.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
echo Installing Persian RTL patch...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
if errorlevel 1 (
  echo.
  echo Install failed. Close OpenCode fully and retry.
  pause
  exit /b 1
)
echo.
echo Done. Open OpenCode normally.
pause