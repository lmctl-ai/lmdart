#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$ROOT/.tools/dart-sdk"
if [[ -x "$SDK/bin/dart" ]]; then printf '%s\n' "$SDK"; exit 0; fi
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) platform=linux-x64 ;;
  Linux-aarch64|Linux-arm64) platform=linux-arm64 ;;
  *) echo "Unsupported Dart SDK platform: $(uname -s)-$(uname -m)" >&2; exit 2 ;;
esac
version=$(sed -n 's/^version=//p' "$ROOT/scripts/dart-sdk.lock")
expected=$(sed -n "s/^$platform=//p" "$ROOT/scripts/dart-sdk.lock")
archive="$ROOT/.tools/dartsdk-$platform-$version.zip"
url="https://storage.googleapis.com/dart-archive/channels/stable/release/$version/sdk/dartsdk-$platform-release.zip"
mkdir -p "$ROOT/.tools"
curl -fsSL --retry 3 -o "$archive" "$url"
echo "$expected  $archive" | sha256sum -c - >&2
unzip -q "$archive" -d "$ROOT/.tools"
printf '%s\n' "$SDK"
