# lmdart

A small Dart browser runtime and demo book using direct DOM, SVG, Canvas 2D, and WebGL APIs. Dart compiles to JavaScript; ordinary JavaScript functions register as runtime handlers and can call Dart handlers. No Flutter or heavyweight UI, drawing, chart, animation, or 3D framework is used.

- [Demo book](https://www.lmctl.com/tools/lmdart/)
- [Source on GitHub](https://github.com/lmctl-ai/lmdart)

The root page is the book cover. Eight separate chapter pages cover HTML hydration, JSON table binding, SVG, Canvas, charts, plots, animation/tweening, and WebGL. There is no feature selector.

## Architecture

- `.html` files are static page templates and retained SVG markup.
- `.json` files supply hydration values, table columns/rows, draw commands, chart series, tween parameters, and WebGL colors/speed.
- `web/main.dart` dispatches the current page and owns rendering, events, animation, and browser API calls.
- `web/static/boot.js` registers JavaScript handlers and starts the dispatched page after the Dart runtime has installed `LMDart`.
- `lib/src/` contains the reusable runtime and rendering APIs.

The generated application is about 124 KB of JavaScript before transport compression. No third-party JavaScript executes at runtime.

## Build

Linux x64 and arm64 are supported by the pinned SDK installer. Requirements are curl, unzip, Python 3, and Node 24.15 or newer for browser tests. The installer downloads official Dart SDK 3.14.1 and verifies its pinned SHA-256 checksum.

```sh
git clone https://github.com/lmctl-ai/lmdart.git
cd lmdart
bash scripts/build.sh
```

The complete static site is generated under `target/site/`. Open `index.html` through an HTTP server. To generate into another static directory:

```sh
bash scripts/build.sh /absolute/site/path
```

The HTML pages are deterministic outputs of `scripts/generate-book.py`; edit chapter definitions there and rerun the build. CI checks that generated sources are synchronized.

## JavaScript runtime bridge

The Dart entry point installs `window.LMDart` but does not start a page until JavaScript handlers are registered.

```javascript
LMDart.register('card.clicked', context => {
  const result = LMDart.call('dart.stamp', { value: context.value });
  LMDart.setText('#result', result);
  return true;
});
LMDart.start();
```

| API | Purpose |
| --- | --- |
| `LMDart.version` | Runtime version, currently 0.1.0 |
| `LMDart.register(name, handler)` | Register a unique JavaScript function accepting one context object |
| `LMDart.call(name, context)` | Invoke a JavaScript or Dart handler and return its JavaScript value |
| `LMDart.loadJson(path, success, failure)` | Fetch JSON and deliver a JavaScript value or error string |
| `LMDart.setText(selector, value)` | Set an existing element's textContent |
| `LMDart.setAttribute(selector, name, value)` | Set an existing element's attribute |
| `LMDart.start()` | Dispatch the current page after registration is complete |

Dart handlers are registered through `RuntimeBridge.registerDart`. JavaScript and Dart handler names share one namespace. Empty, duplicate, and unknown names are errors. Handler context values cross the boundary as ordinary JavaScript objects.

## HTML hydration and JSON tables

Hydration updates existing nodes marked with `data-hydrate`; it does not replace the static card. An optional `data-hydrate-attribute` selects attribute output instead of text.

`JsonTable` validates nonempty columns and rectangular rows, then builds table headings and body cells using textContent. Rows support click, Enter, and Space selection.

```dart
final data = jsonMap(await fetchJson('data/hydration.json'), 'hydration');
hydrate(document.getElementById('card')!, data);

final table = JsonTable(jsonMap(await fetchJson('data/table.json'), 'table'));
table.bind(tableElement, (index) {
  bridge.call('table.selected', {'index': index}.jsify());
});
```

## SVG and Canvas draw data

Both backends accept a document with title, width, height, and commands. Commands are `rect`, `circle`, `line`, `polyline`, `path`, and `text`. Points are JSON objects with finite x/y values. Canvas pointer marks are application state and redraw explicitly; SVG remains retained DOM.

```dart
final data = await fetchJson('data/svg.json');
drawSvg(container, data);
drawCanvas(canvas, await fetchJson('data/canvas.json'));
```

## Charts and plots

`BarChart` data becomes banded SVG rectangles with linear ticks. Pie slices become SVG arc paths and percentage labels. Named `Series` values render as line or scatter plots on Canvas. Chart models reject malformed, nonfinite, empty, or negative-slice input as appropriate.

The reusable pieces are `LinearScale`, `Bar`, `Slice`, `Point`, `Series`, `renderBarChart`, `renderPieChart`, and `renderPlot`.

## Animation and tweening

`TweenPlayer` reads duration, numeric attribute tweens, and position tweens from JSON. Position writes SVG translate transforms; attributes write values such as radius and opacity. The same frame callback draws Canvas particles. `toggle` and `reset` preserve explicit control over the animation state.

```dart
final player = TweenPlayer(await fetchJson('data/tween.json'),
    onFrame: (seconds) => drawParticles(canvas, seconds));
player.start();
```

`easeInOutCubic` and `tweenValue` are pure Dart and VM-testable. Frame deltas are capped at 50 milliseconds.

## WebGL

`WebglCube` compiles vertex and fragment shaders, uploads 36 colored vertices, enables depth testing, computes column-major perspective/translation/rotation matrices, and draws through WebGL 1. JSON supplies six colors and rotation speed. The demo uses a preserved drawing buffer for integration-test pixel readback.

```dart
final cube = WebglCube(canvas, await fetchJson('data/webgl.json'));
cube.start();
```

This is intentionally a small WebGL example, not a general Three.js replacement.

## Verification

```sh
scripts/install-dart.sh
.tools/dart-sdk/bin/dart analyze
.tools/dart-sdk/bin/dart test -r expanded
bash scripts/build.sh
npm ci
npx playwright install --with-deps chromium
npm test
```

The 12 VM tests cover chart models, JSON validation, scale mapping and ticks, tween easing/interpolation, and matrix math. Playwright visits all nine pages, checks static-card hydration, JavaScript-to-Dart calls, JSON table rows and keyboard selection, SVG DOM, Canvas pixels, four chart types, attribute and position tweening, pause/reset, real WebGL pixels and errors, mobile overflow, and runtime errors.

Set `DEMO_URL` to the deployed root index.html URL and `PLAYWRIGHT_CHROMIUM_EXECUTABLE` to an existing Chromium binary when needed. GitHub Actions runs the same checks from public dependencies.

## License

MIT. Dart and package:web are BSD licensed; Playwright is Apache-2.0. See `LICENSE` and `THIRD_PARTY_NOTICES.md`.
