[CmdletBinding()]
param(
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "OpenCodePersianTypography")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (Get-Process -Name OpenCode -ErrorAction SilentlyContinue) {
    throw "Close every OpenCode window before uninstalling."
}

$expected = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA "OpenCodePersianTypography"))
$target = [IO.Path]::GetFullPath($StateRoot)
if ($target -ne $expected) { throw "Refusing to remove an unexpected path: $target" }

$statePath = Join-Path $target "state.json"
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    Write-Host "OpenCode Persian Typography is not installed."
    exit 0
}
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json

if (-not (Test-Path -LiteralPath $state.appAsar -PathType Leaf)) { throw "OpenCode app.asar is missing." }
if (-not (Test-Path -LiteralPath $state.backup -PathType Leaf)) { throw "Original app.asar backup is missing." }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $state.backup).Hash -ne $state.originalSha256) {
    throw "Original app.asar backup hash does not match state.json."
}

$currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $state.appAsar).Hash
if ($currentHash -eq $state.patchedSha256) {
    Copy-Item -LiteralPath $state.backup -Destination $state.appAsar -Force
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $state.appAsar).Hash -ne $state.originalSha256) {
        throw "Restoring the original app.asar failed. The backup remains at $($state.backup)."
    }
} elseif ($currentHash -ne $state.originalSha256) {
    throw "OpenCode changed after installation. Refusing to restore a backup from a different build."
}

if ([IO.Path]::GetFullPath($PSScriptRoot) -eq $target) {
    $escaped = $target.Replace("'", "''")
    $command = "Start-Sleep -Seconds 1; Remove-Item -LiteralPath '$escaped' -Recurse -Force"
    Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-WindowStyle", "Hidden", "-Command", $command) -WindowStyle Hidden
} else {
    Remove-Item -LiteralPath $target -Recurse -Force
}

Write-Host "Restored the original main OpenCode instance and removed the typography patch."
