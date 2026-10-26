[CmdletBinding()]
param(
    [string]$OpenCodeExe,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "OpenCodePersianTypography")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Find-OpenCode {
    if ($OpenCodeExe -and (Test-Path -LiteralPath $OpenCodeExe -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $OpenCodeExe).Path
    }
    $candidates = @(
        $env:OPENCODE_EXE,
        (Join-Path $env:LOCALAPPDATA "Programs\@opencodedesktop\OpenCode.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\@opencode-aidesktop\OpenCode.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\OpenCode\OpenCode.exe")
    ) | Where-Object { $_ }
    return $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

function Invoke-Asar([string[]]$Arguments) {
    & npx --yes "@electron/asar" @Arguments
    if ($LASTEXITCODE) { throw "@electron/asar failed: $($Arguments -join ' ')" }
}

function Assert-RendererContracts([string]$RendererRoot) {
    $scripts = Get-ChildItem -LiteralPath (Join-Path $RendererRoot "assets") -Filter "*.js" -File
    if (-not $scripts) { throw "OpenCode renderer assets were not found." }
    foreach ($contract in @("home-session-row", "user-message-text", "text-part-body", "data-component=composer-editor")) {
        if (-not (Select-String -LiteralPath $scripts.FullName -SimpleMatch -Pattern $contract -Quiet)) {
            throw "OpenCode renderer changed: missing '$contract'. Update the runtime selectors before installing."
        }
    }
}

function Remove-LegacyLauncher([string]$Root) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcuts = @(
        (Join-Path ([Environment]::GetFolderPath("Desktop")) "OpenCode Persian.lnk"),
        (Join-Path ([Environment]::GetFolderPath("Programs")) "OpenCode Persian.lnk")
    )
    foreach ($shortcutPath in $shortcuts) {
        if (-not (Test-Path -LiteralPath $shortcutPath)) { continue }
        $shortcut = $shell.CreateShortcut($shortcutPath)
        if ($shortcut.Arguments -like "*$(Join-Path $Root 'launch.ps1')*") {
            Remove-Item -LiteralPath $shortcutPath -Force
        }
    }
    foreach ($legacy in @("launcher.mjs", "launch.ps1")) {
        $path = Join-Path $Root $legacy
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    $logs = Join-Path $Root "logs"
    if (Test-Path -LiteralPath $logs) { Remove-Item -LiteralPath $logs -Recurse -Force }
}

if (Get-Process -Name OpenCode -ErrorAction SilentlyContinue) {
    throw "Close every OpenCode window before installing the main-instance patch."
}

$node = Get-Command node -ErrorAction SilentlyContinue
$npx = Get-Command npx -ErrorAction SilentlyContinue
if (-not $node -or -not $npx) { throw "Node.js 18 or newer and npx are required." }
$nodeMajor = [int]((& $node.Source --version).TrimStart("v").Split(".")[0])
if ($nodeMajor -lt 18) { throw "Node.js 18 or newer is required." }

$openCode = Find-OpenCode
if (-not $openCode) { throw "OpenCode Desktop was not found. Set OPENCODE_EXE and retry." }
$appAsar = Join-Path (Split-Path -Parent $openCode) "resources\app.asar"
if (-not (Test-Path -LiteralPath $appAsar -PathType Leaf)) { throw "OpenCode app.asar was not found." }

$required = @(
    "runtime\runtime.js", "runtime\runtime.css", "fonts\Vazirmatn[wght].woff2",
    "doctor.ps1", "uninstall.ps1", "tests\runtime.test.cjs", "package.json"
)
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $item))) { throw "Missing: $item" }
}

New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null
$backup = Join-Path $StateRoot "app.asar.backup"
$temp = Join-Path ([IO.Path]::GetTempPath()) "oppt-$([Guid]::NewGuid().ToString('N'))"
$extracted = Join-Path $temp "app"
$rebuilt = Join-Path $temp "app.asar"

try {
    New-Item -ItemType Directory -Force -Path $extracted | Out-Null
    Invoke-Asar @("extract", $appAsar, $extracted)

    $indexPath = Join-Path $extracted "out\renderer\index.html"
    if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) { throw "Renderer index.html was not found." }
    Assert-RendererContracts (Split-Path -Parent $indexPath)
    $index = Get-Content -Raw -LiteralPath $indexPath
    $markerPattern = '(?s)\s*<!-- opencode-persian-typography:start -->.*?<!-- opencode-persian-typography:end -->\s*'
    $alreadyPatched = [regex]::IsMatch($index, $markerPattern)

    if (-not $alreadyPatched) {
        Copy-Item -LiteralPath $appAsar -Destination $backup -Force
    } elseif (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        throw "The app is patched but its original app.asar backup is missing."
    }

    $payload = Join-Path $extracted "out\renderer\oppt"
    New-Item -ItemType Directory -Force -Path $payload | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "runtime\runtime.js") -Destination (Join-Path $payload "runtime.js") -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "runtime\runtime.css") -Destination (Join-Path $payload "runtime.css") -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "fonts\Vazirmatn[wght].woff2") -Destination (Join-Path $payload "Vazirmatn.woff2") -Force

    $index = [regex]::Replace($index, $markerPattern, "`r`n")
    $block = @'
    <!-- opencode-persian-typography:start -->
    <link rel="stylesheet" href="./oppt/runtime.css" />
    <script defer src="./oppt/runtime.js"></script>
    <!-- opencode-persian-typography:end -->
'@
    if ($index -notmatch '</head>') { throw "Renderer index.html has no closing head tag." }
    $index = $index -replace '</head>', "$block`r`n  </head>"
    [IO.File]::WriteAllText($indexPath, $index, [Text.UTF8Encoding]::new($false))

    Invoke-Asar @("pack", $extracted, $rebuilt)
    $listing = (& npx --yes "@electron/asar" list $rebuilt) -join "`n"
    if ($LASTEXITCODE -or $listing -notmatch 'out[\\/]renderer[\\/]oppt[\\/]runtime\.js') {
        throw "Rebuilt app.asar does not contain the runtime payload."
    }

    Copy-Item -LiteralPath $rebuilt -Destination $appAsar -Force
    $originalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $backup).Hash
    $patchedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $appAsar).Hash
    if ($originalHash -eq $patchedHash) { throw "Patched app.asar hash unexpectedly matches the original." }

    $state = [ordered]@{
        installedAt = [DateTime]::UtcNow.ToString("o")
        runtimeVersion = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "package.json") | ConvertFrom-Json).version
        openCodeVersion = (Get-Item -LiteralPath $openCode).VersionInfo.ProductVersion
        appAsar = $appAsar
        backup = $backup
        originalSha256 = $originalHash
        patchedSha256 = $patchedHash
    }
    $state | ConvertTo-Json -Depth 3 | Set-Content -Encoding utf8 -LiteralPath (Join-Path $StateRoot "state.json")

    if ([IO.Path]::GetFullPath($PSScriptRoot) -ne [IO.Path]::GetFullPath($StateRoot)) {
        foreach ($item in @("install.ps1", "doctor.ps1", "uninstall.ps1", "package.json", "README.md", "LICENSE", "AGENTS.md", "runtime", "fonts", "tests")) {
            $source = Join-Path $PSScriptRoot $item
            if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $StateRoot -Recurse -Force }
        }
    }
    Remove-LegacyLauncher $StateRoot
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}

Write-Host "Patched the main OpenCode $($state.openCodeVersion) instance."
Write-Host "Original app.asar backup: $backup"
Write-Host "Normal OpenCode shortcuts now load Vazirmatn and smart Persian direction."
