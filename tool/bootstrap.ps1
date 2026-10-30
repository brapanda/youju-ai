$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Install Flutter stable and add flutter/bin to PATH first."
}
flutter --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not ((Test-Path android) -and (Test-Path ios) -and (Test-Path web))) {
  flutter create --no-pub --platforms=android,ios,web --org ca.youju --project-name youju_ai .
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
dart tool/configure_android.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Bootstrap finished. Run flutter analyze, flutter test, then flutter run."
