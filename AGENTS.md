# OpenCode Persian RTL

Adds Vazirmatn and smart Persian/English direction to the main OpenCode Desktop
instance on Windows. Compatible with OpenCode 2.1.4 (composer-editor).

## Installation task

When a user asks to install or update this repository:

1. Close every OpenCode window (or run install.bat, which stops OpenCode).
2. Run powershell -ExecutionPolicy Bypass -File .\install.ps1 from the repo root.
3. Run npm test and powershell -ExecutionPolicy Bypass -File .\doctor.ps1.
4. Launch OpenCode from its normal official shortcut and verify Persian chat/composer text.
5. After an OpenCode update, rerun install.ps1 because the updater replaces resources\app.asar.
6. If the renderer-contract check fails, update runtime/runtime.js selectors and the matching contract list in install.ps1; do not bypass the check.

Default path: %LOCALAPPDATA%\Programs\@opencodedesktop\OpenCode.exe
Backup: %LOCALAPPDATA%\OpenCodePersianTypography\app.asar.backup

Do not create a separate launcher. Do not use remote debugging. Do not modify
OpenCode.exe, the updater, settings, or message text. Presentation only.

OpenCode 2.1.4 renamed the prompt from prompt-input to composer-editor.
Keep that selector and install contracts in sync with the installed build.