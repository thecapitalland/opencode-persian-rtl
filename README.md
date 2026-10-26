# OpenCode Persian & Arabic RTL

**Readable Persian and Arabic-script chat in OpenCode Desktop — with Latin text and code kept left-to-right.**

[English](README.md) · [فارسی](README.fa.md) · [العربية](README.ar.md)

> [!IMPORTANT]
> **Unofficial Windows Desktop patch.** This project is not affiliated with OpenCode. It modifies the installed Electron `resources\app.asar` file and is not a native OpenCode plugin. **Check OpenCode's built-in RTL / Arabic-language options first**; use this patch only when those options do not meet your text-rendering needs.

## The problem it addresses

Mixed-script messages can be hard to read when Persian or Arabic prose, English names, paths and code share the same fixed text direction. This project applies **direction detection per supported text block** and loads **Vazirmatn** for Arabic-script glyphs.

| Content | Intended display |
| --- | --- |
| `این متن فارسی درباره GitHub است.` | RTL prose |
| `هذا مثال عربي مع OpenCode.` | RTL prose |
| `OpenCode supports multiple models.` | LTR |
| `C:\Users\name\project` and fenced code | LTR |

### What it changes

- Chat prose, selected session titles/tabs and the composer: automatic text-direction selection.
- Code blocks, paths, URLs, emails and technical content: LTR handling.
- Arabic-script typography: the bundled Vazirmatn font.
- Response streaming and input: rescan when text changes.

**It does not** translate OpenCode's interface, modify model responses or support the terminal-based TUI.

## Compatibility

| Requirement | Status |
| --- | --- |
| OS | Windows |
| App | OpenCode **Desktop (Electron)**, not OpenCode CLI/TUI |
| Renderer version | Designed for **OpenCode Desktop 2.1.4** private selectors; later releases are **not guaranteed** |
| Tooling | Node.js 18+ and npm/npx |
| Internet | `npx` may download `@electron/asar` at install/verification time |

Other Windows installation layouts may require setting `OPENCODE_EXE`:

```powershell
$env:OPENCODE_EXE = "D:\Apps\OpenCode\OpenCode.exe"
```

## Installation

**1. Download or clone this repository. Close OpenCode completely and save unfinished work.**

**2. From PowerShell in the repository folder, run:**

```powershell
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

The PowerShell installer refuses to proceed while OpenCode is running. The optional `install.bat` wrapper instead **force-closes** OpenCode; it can discard unsaved work.

**3. Reopen OpenCode and check mixed Persian/Arabic and English messages, code fences, tables and the composer.**

**4. Check installation state:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\doctor.ps1
```

The installer stores its original-archive backup and state under:

```text
%LOCALAPPDATA%\OpenCodePersianTypography\
```

## Restore / uninstall

Close OpenCode, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Or run `uninstall.bat` (which force-closes OpenCode). Restoration checks recorded hashes and refuses to overwrite an archive changed by an update. **Do not manually restore a backup from an older OpenCode version.**

## Updates, limitations and safety

- An OpenCode update can replace the patch. The private DOM selectors can change between versions.
- This installer currently repacks `app.asar` and does **not** provide a complete atomic-install / unpacked-file preservation guarantee. **Use only after testing on your specific installed build.**
- Existing automated tests cover selected JavaScript logic and static checks, **not** a full end-to-end Windows installation, rollback or visual RTL compatibility.
- The patch includes no remote runtime script or telemetry. However, `npx` may fetch its build tool during installation; the tool version is not pinned in this release.
- Font and runtime assets are bundled locally; the program executable, chats and settings are not intentionally edited.

**Prefer native support when it works:** OpenCode 2.x has Arabic language/RTL layout work, but full chat-level RTL remains under discussion: [OpenCode RTL issue #26915](https://github.com/anomalyco/opencode/issues/26915). This patch should be treated as a version-specific workaround.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `OpenCode Desktop was not found` | Set `OPENCODE_EXE` to the correct `OpenCode.exe` path |
| `OpenCode renderer changed` | Stop. The installed version is not verified; do **not** bypass the compatibility check |
| Patch disappears after update | Recheck compatibility before reinstalling |
| Restore refused | Archive hashes changed; repair/reinstall the matching official OpenCode build rather than forcing an old backup |
| Arabic layout already works | Prefer the built-in functionality and avoid an unnecessary patch |

## License and credits

- Patch code and installer: MIT — [LICENSE](LICENSE)
- Vazirmatn: SIL Open Font License 1.1 — [fonts/OFL.txt](fonts/OFL.txt)
- Adapted from [omid3098/opencode-persian-typography](https://github.com/omid3098/opencode-persian-typography)
- Font by [Saber Rastikerdar / Vazirmatn](https://github.com/rastikerdar/vazirmatn)

See [NOTICE.md](NOTICE.md) for attribution. Contributions and regression reports are welcome through GitHub issues.