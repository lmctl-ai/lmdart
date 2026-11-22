# Architecture

## Runtime boundary

lmdart uses Dart 3.14.1 and package:web 1.1.1. The SDK installer is `scripts/install-dart.sh`; versions and Linux x64/arm64 SHA-256 hashes live in `scripts/dart-sdk.lock`. No Flutter or JavaScript application framework is used.

`web/main.dart` installs `window.LMDart` through `RuntimeBridge`. It does not start a chapter during compilation. `web/static/boot.js` registers ordinary JavaScript handlers and calls `LMDart.start()` afterward. JavaScript and Dart handlers share a namespace and accept one JavaScript context object. `LMDart.call` returns JavaScript values directly through dart:js_interop rather than JSON serialization.

Pure code is separated from browser-only code so VM tests do not import package:web or dart:js_interop. In particular, `json_values.dart`, `chart_models.dart`, `scale.dart`, `tween_math.dart`, and `matrix4.dart` remain VM-testable. Dart's `dartify()` can produce dynamically typed maps, so `jsonMap` validates keys and normalizes them to `Map<String, Object?>` instead of testing an exact generic runtime type.

## Demo book

The root `index.html` is the executable cover. Eight `demo-*.html` pages are independent chapters: hydration, JSON table, SVG, Canvas, charts, plots, animation/tweening, and WebGL. There is no selector.

HTML files are static templates. JSON files provide hydration values, table rows, draw commands, chart models, tween parameters, and WebGL settings. `scripts/generate-book.py` owns page structure; generated HTML is committed and checked for drift in CI.

The website treats an index with `body[data-page]` as a raw demo cover, not a decorated documentation index. `guide.html` is the quick reference and `skill.html` is the authoring skill.

## Rendering and validation

SVG uses namespaced retained elements. Canvas is immediate mode and redraws explicit application state. Both accept command-oriented JSON. Chart code generates SVG bar/pie charts and Canvas line/scatter plots. TweenPlayer updates SVG position transforms and numeric attributes while a shared frame callback draws Canvas particles. WebglCube compiles shaders, uploads 36 colored vertices, and uses column-major matrices with depth testing.

The build removes `lmdart.js.map` and `lmdart.js.deps` because the tools publisher intentionally rejects unknown file types. The current compiled JavaScript is approximately 124 KB before transport compression.

## Verification

`dart analyze` must report no issues. Twelve VM tests cover chart models, JSON validation, scales, tween math, and matrices. `tests/browser.mjs` covers all nine pages, real SVG DOM and Canvas pixels, JavaScript-to-Dart calls, pointer/keyboard interaction, position and attribute tweening, WebGL pixel output and errors, and mobile overflow.

The standard local sequence is:

```sh
.tools/dart-sdk/bin/dart pub get
.tools/dart-sdk/bin/dart analyze
.tools/dart-sdk/bin/dart test -r expanded
bash scripts/build.sh
npm ci
npm test
```

The latest application commit is `1442337`, with GitHub Actions run `44957433636` passing.
