#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK is required. Install Flutter stable and add flutter/bin to PATH.' >&2
  exit 1
fi
flutter --version
# flutter create without --overwrite retains existing Dart, pubspec and docs.
# Only missing platform scaffolding is generated. Do not use --overwrite here.
if [[ ! -d android || ! -d ios || ! -d web ]]; then
  flutter create --no-pub --platforms=android,ios,web --org ca.youju --project-name youju_ai .
fi
flutter pub get
echo 'Bootstrap finished. Run flutter analyze, flutter test, then flutter run.'
