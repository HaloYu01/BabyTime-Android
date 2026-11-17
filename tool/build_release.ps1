# BabyTime release build (ABI splits + symbols separated)
# Usage (from project root):
#   powershell -ExecutionPolicy Bypass -File tool\build_release.ps1

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    Write-Host "Building release APKs (split-per-abi)..." -ForegroundColor Cyan
    flutter build apk --release --split-per-abi --split-debug-info=build\symbols

    Write-Host "`nAPK outputs:" -ForegroundColor Green
    Get-ChildItem build\app\outputs\flutter-apk\*.apk |
        Select-Object Name, @{N = 'SizeMB'; E = { [math]::Round($_.Length / 1MB, 2) } } |
        Format-Table -AutoSize

    Write-Host "Install the arm64 package on modern devices; distribute per-ABI." -ForegroundColor Cyan
    Write-Host "Debug symbols: build\symbols" -ForegroundColor Cyan
}
finally {
    Pop-Location
}