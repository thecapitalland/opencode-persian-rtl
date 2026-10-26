# OpenCode Persian RTL

Vazirmatn font + smart Persian/English direction for the **main OpenCode Desktop** app on Windows.

This package patches `resources\app.asar` only. It does **not** modify `OpenCode.exe`, your chats, or settings.

Based on [omid3098/opencode-persian-typography](https://github.com/omid3098/opencode-persian-typography), adapted for **OpenCode Desktop 2.1.4** where the prompt component is `data-component="composer-editor"` (older builds used `prompt-input`).

## What it does

- Loads Vazirmatn for Arabic-script characters (Persian stays readable; Latin/code stay on system fonts)
- Sets `dir="rtl"` / `dir="ltr"` from letter counts on chat prose, Home titles, tabs, and the composer
- Keeps code, paths, URLs, emails, and hashes LTR
- Recomputes direction while answers stream and while you type

## Requirements

- Windows
- OpenCode Desktop (Electron)
- Node.js 18+ (for `npx @electron/asar`)

Default install path checked:

```text
%LOCALAPPDATA%\Programs\@opencodedesktop\OpenCode.exe
```

Also tries `@opencode-aidesktop` and `OpenCode`. Override with:

```powershell
$env:OPENCODE_EXE = "D:\path\to\OpenCode.exe"
```

## Install

Close every OpenCode window, then either:

**One click**

```bat
install.bat
```

**PowerShell**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Before changing anything, the installer:

1. Backs up the original `app.asar` to `%LOCALAPPDATA%\OpenCodePersianTypography\app.asar.backup`
2. Checks renderer contracts (`home-session-row`, `user-message-text`, `text-part-body`, `composer-editor`)
3. Injects `out/renderer/oppt/` + a small block into `index.html`
4. Repacks `app.asar`

## Verify

```powershell
npm test
powershell -ExecutionPolicy Bypass -File .\doctor.ps1
```

Then open OpenCode and check one Persian message and the composer.

## Uninstall

```bat
uninstall.bat
```

or:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Restores the recorded original `app.asar`. If OpenCode updated and hashes no longer match, uninstall refuses (safe).

## After OpenCode updates

The official updater may replace `app.asar`. Close OpenCode and run `install.bat` again.

If install stops with `missing '…'`, OpenCode changed internal `data-component` / `data-slot` names — update selectors in `runtime/runtime.js` and the contract list in `install.ps1`.

## Compatibility notes (2.1.4)

| Older selector | OpenCode 2.1.4 |
| --- | --- |
| `data-component="prompt-input"` | `data-component="composer-editor"` |

Runtime version marker: `1.0.2-oc214`.

## Security

All runtime code and the font are local files. No remote load, no debug port, no message rewriting.

## License

- Runtime / installer: MIT
- Vazirmatn: SIL OFL 1.1 (see `fonts/OFL.txt`)

## Credits

- Upstream idea and original installer: [omid3098/opencode-persian-typography](https://github.com/omid3098/opencode-persian-typography)
- Font: [rastikerdar/vazirmatn](https://github.com/rastikerdar/vazirmatn)