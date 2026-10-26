# راست‌چین فارسی برای OpenCode Desktop

فونت وزیرمتن + تشخیص هوشمند راست‌چین/چپ‌چین برای اپ دسکتاپ OpenCode روی ویندوز.

فقط فایل `resources\app.asar` پچ می‌شود. `OpenCode.exe`، چت‌ها و تنظیمات دست نخورده می‌مانند.

بر پایهٔ [omid3098/opencode-persian-typography](https://github.com/omid3098/opencode-persian-typography)، سازگار با **OpenCode 2.1.4** (ورودی پیام: `composer-editor`).

## نصب

همه پنجره‌های OpenCode را ببند، بعد:

```bat
install.bat
```

یا:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

بکاپ اصل:

```text
%LOCALAPPDATA%\OpenCodePersianTypography\app.asar.backup
```

## حذف

```bat
uninstall.bat
```

## بعد از آپدیت OpenCode

دوباره `install.bat` را اجرا کن. اگر خطای `missing '…'` دیدی، سلکتورهای داخل `runtime/runtime.js` را با نسخهٔ جدید هماهنگ کن.

## پیش‌نیاز

- ویندوز
- OpenCode Desktop
- Node.js 18 یا بالاتر