[CmdletBinding()]
param(
    [string]$Root = (Join-Path $env:LOCALAPPDATA "OpenCodePersianTypography")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$statePath = Join-Path $Root "state.json"
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "No installation state found. Run install.ps1 first."
}
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json

$required = @(
    "runtime\runtime.js", "runtime\runtime.css", "fonts\Vazirmatn[wght].woff2",
    "tests\runtime.test.cjs", "install.ps1", "uninstall.ps1"
)
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $item))) { throw "Missing: $item" }
}

$node = Get-Command node -ErrorAction SilentlyContinue
$npx = Get-Command npx -ErrorAction SilentlyContinue
if (-not $node -or -not $npx) { throw "Node.js and npx were not found." }
& $node.Source (Join-Path $Root "tests\runtime.test.cjs")
if ($LASTEXITCODE) { throw "Runtime tests failed." }

if (-not (Test-Path -LiteralPath $state.appAsar -PathType Leaf)) { throw "OpenCode app.asar is missing." }
if (-not (Test-Path -LiteralPath $state.backup -PathType Leaf)) { throw "Original app.asar backup is missing." }

$patchedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $state.appAsar).Hash
$backupHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $state.backup).Hash
if ($patchedHash -ne $state.patchedSha256) {
    throw "OpenCode app.asar changed, probably after an update. Rerun install.ps1."
}
if ($backupHash -ne $state.originalSha256) { throw "Original app.asar backup hash does not match state.json." }

$listing = (& npx --yes "@electron/asar" list $state.appAsar) -join "`n"
if ($LASTEXITCODE) { throw "Could not inspect app.asar." }
foreach ($payload in @("runtime.js", "runtime.css", "Vazirmatn.woff2")) {
    if ($listing -notmatch "out[\\/]renderer[\\/]oppt[\\/]$([regex]::Escape($payload))") {
        throw "Patched app.asar is missing $payload."
    }
}

$resources = Split-Path -Parent $state.appAsar
$openCode = Join-Path (Split-Path -Parent $resources) "OpenCode.exe"
$signature = Get-AuthenticodeSignature -LiteralPath $openCode
if ($signature.Status -ne "Valid") { throw "OpenCode.exe signature is not valid: $($signature.Status)" }

Write-Host "Doctor passed: main OpenCode instance is patched; backup, payload, tests, and executable signature are valid."
