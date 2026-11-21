#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$("$ROOT/scripts/install-dart.sh")"
DART="$SDK/bin/dart"
OUT="${1:-$ROOT/target/site}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
[[ "$OUT" != "/" && "$OUT" != "$ROOT" ]] || { echo "Unsafe output directory: $OUT" >&2; exit 2; }
python3 "$ROOT/scripts/generate-book.py"
cd "$ROOT"
"$DART" pub get
"$DART" compile js -O2 -o "$OUT/lmdart.js" web/main.dart
rm -f "$OUT/lmdart.js.map" "$OUT/lmdart.js.deps"
cp -R "$ROOT/web/static/." "$OUT/"
printf 'Built lmdart at %s\n' "$OUT"
