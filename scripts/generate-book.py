#!/usr/bin/env python3
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "web/static"

CHAPTERS = [
    ("hydration", "HTML hydration", "Static markup, live behavior.", "Hydrate an ordinary static card with JSON values, then connect its existing button to JavaScript and Dart runtime handlers.", '''final data = await fetchJson('data/hydration.json');
hydrate(document.getElementById('hydration-card')!, data);
button.onClick.listen((_) {
  LMDart.call('hydrate.clicked', {'value': 'hydration'});
});''', "action"),
    ("table", "JSON HTML tables", "A table is just a bound model.", "Bind JSON columns and rows to a real HTML table. Row click and keyboard selection flow through a registered JavaScript handler.", '''final table = JsonTable(await fetchJson('data/table.json'));
table.bind(tableElement, (index) {
  bridge.call('table.selected', {'index': index}.jsify());
});''', None),
    ("svg", "SVG drawing", "Data becomes retained SVG.", "Load rectangles, circles, lines, polylines, and text from JSON. A JavaScript palette handler drives a Dart SVG redraw.", '''final data = await fetchJson('data/svg.json');
drawSvg(container, data);
final color = bridge.call('svg.palette', context) as JSString;
drawSvg(container, data, palette: color.toDart);''', "action"),
    ("canvas", "Canvas drawing", "Immediate pixels from the same data idea.", "Draw JSON commands through CanvasRenderingContext2D. Pointer coordinates pass through a JavaScript validator before Dart redraws the canvas.", '''final data = await fetchJson('data/canvas.json');
drawCanvas(canvas, data);
canvas.onClick.listen((event) {
  final accepted = bridge.call('canvas.point', point);
  if (accepted) drawCanvas(canvas, data, marks: marks);
});''', "canvas"),
    ("chart", "Charts", "Axes, bars, and arc wedges.", "Generate bar and pie charts from one JSON document. Dart computes scales, ticks, positions, labels, and SVG arc paths.", '''final data = await fetchJson('data/chart.json');
renderBarChart(barContainer, data['bar']);
renderPieChart(pieContainer, data['pie']);''', None),
    ("plot", "Line and scatter plots", "One series model, two plot forms.", "Render named point series as a connected line plot and a scatter plot. Both use Dart linear scales and immediate Canvas drawing.", '''renderPlot(lineCanvas, data['line']);
renderPlot(scatterCanvas, data['scatter'], scatter: true);''', None),
    ("animation", "Animation and tweening", "Position and attributes share a clock.", "Tween SVG transform, radius, and opacity while drawing Canvas particles with requestAnimationFrame. JavaScript controls pause, resume, and reset.", '''final player = TweenPlayer(await fetchJson('data/tween.json'),
  onFrame: (seconds) => drawParticles(canvas, seconds));
player.start();
player.toggle();
player.reset();''', "animation"),
    ("webgl", "3D Canvas with WebGL", "Shaders and matrices, directly from Dart.", "Compile shaders, upload a colored cube, compute perspective and rotation matrices, and animate WebGL without a 3D JavaScript library.", '''final cube = WebglCube(canvas,
  await fetchJson('data/webgl.json'));
cube.start();
cube.toggle();
cube.reset();''', "webgl"),
]


def header():
    return '''    <header class="site-header">
        <a class="brand" href="index.html" aria-label="lmdart demo book">lm<span>dart</span></a>
        <nav class="project-nav" aria-label="Project links">
            <a href="https://github.com/lmctl-ai/lmdart">Source on GitHub</a>
            <a href="https://dart.dev/">Dart language</a>
        </nav>
    </header>'''


def footer():
    return '''    <footer>
        <p><strong>lmdart</strong> · Dart 3.14.1 · MIT licensed</p>
        <p>No Flutter. No UI framework. Direct browser APIs and small JavaScript handlers.</p>
    </footer>'''


def document(title, description, page, body):
    return f'''<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="{escape(description, quote=True)}">
    <title>{escape(title)}</title>
    <link rel="icon" href="favicon.svg" type="image/svg+xml">
    <link rel="stylesheet" href="demo.css">
</head>
<body data-page="{page}">
{body}
    <script src="lmdart.js"></script>
    <script src="boot.js"></script>
</body>
</html>
'''


cards = []
for slug, title, heading, description, _code, _kind in CHAPTERS:
    cards.append(f'''            <li><a href="demo-{slug}.html"><div><h2>{escape(title)}</h2><p>{escape(description)}</p></div></a></li>''')
cover = f'''{header()}
    <main class="cover">
        <section class="cover-intro">
            <div><p class="eyebrow">A Dart browser demo book</p><h1>Small runtime.<br><span>Direct to the DOM.</span></h1></div>
            <p class="lede">Eight standalone chapters use HTML templates, JSON data, Dart-generated JavaScript, and registered JavaScript handlers. No Flutter or heavyweight framework.</p>
        </section>
        <ol class="chapter-grid">
{chr(10).join(cards)}
        </ol>
    </main>
{footer()}'''
(OUT / "index.html").write_text(document("lmdart · Dart directly in the browser", "A multi-page Dart DOM, SVG, Canvas, chart, tween, WebGL, and JavaScript handler demo.", "cover", cover))

for index, (slug, title, heading, description, code, kind) in enumerate(CHAPTERS):
    nav = []
    for other_slug, other_title, *_ in CHAPTERS:
        current = ' aria-current="page"' if other_slug == slug else ''
        nav.append(f'                <li><a href="demo-{other_slug}.html"{current}>{escape(other_title)}</a></li>')
    buttons = '''                <div class="controls">
                    <p id="status" class="status" role="status" aria-live="polite">Loading the Dart application…</p>
                </div>'''
    if kind == "action" and slug == "svg":
        scene = f'''                <div id="scene" class="scene" aria-label="Dart-generated SVG scene"></div>'''
        buttons = f'''                <div class="controls">
                    <button id="action" type="button">Change palette</button>
                    <p id="status" class="status" role="status" aria-live="polite">Loading the Dart application…</p>
                </div>'''
    elif kind == "canvas":
        scene = '''                <canvas id="scene-canvas" width="960" height="540" aria-label="Interactive Dart Canvas drawing">Canvas 2D is required.</canvas>'''
        buttons = '''                <div class="controls">
                    <button id="action" type="button">Clear pointer marks</button>
                    <p id="status" class="status" role="status" aria-live="polite">Loading the Dart application…</p>
                </div>'''
    elif slug == "hydration":
        scene = '''                <section id="hydration-card" class="hydration-card" aria-label="Static card hydrated by Dart">
                    <h2 data-hydrate="title">Static template title</h2>
                    <p data-hydrate="description">This static description will be hydrated from JSON.</p>
                    <button id="action" type="button" data-hydrate="action">Static template button</button>
                    <p id="hydration-result">No runtime handler has run yet.</p>
                </section>'''
        buttons = '''                <div class="controls"><p id="status" class="status" role="status" aria-live="polite">Hydrating static HTML…</p></div>'''
    elif slug == "table":
        scene = '''                <div class="table-wrap"><table id="data-table"><thead><tr><th>Template column</th></tr></thead><tbody><tr><td>Waiting for table.json</td></tr></tbody></table></div>
                <p id="table-result">No row selected.</p>'''
    elif slug == "chart":
        scene = '''                <div class="dual-scenes">
                    <section><h2>SVG bar chart</h2><div id="bar-chart" class="scene"></div></section>
                    <section><h2>SVG pie chart</h2><div id="pie-chart" class="scene"></div></section>
                </div>'''
    elif slug == "plot":
        scene = '''                <div class="dual-scenes">
                    <section><h2>Canvas line plot</h2><canvas id="line-plot" width="960" height="540">Canvas 2D is required.</canvas></section>
                    <section><h2>Canvas scatter plot</h2><canvas id="scatter-plot" width="960" height="540">Canvas 2D is required.</canvas></section>
                </div>'''
    elif kind == "animation":
        scene = '''                <div class="animation-scenes">
                    <svg viewBox="0 0 640 540" role="img" aria-label="SVG position and attribute tween">
                        <rect width="640" height="540" fill="#0b1726"></rect>
                        <path d="M90 100 L470 310" stroke="#393e60" stroke-width="3" stroke-dasharray="8 8"></path>
                        <g id="tween-group" transform="translate(90 100)"><circle id="tween-dot" cx="0" cy="0" r="22" fill="#b7a1ff"></circle></g>
                    </svg>
                    <canvas id="particle-canvas" width="320" height="540" aria-label="Dart Canvas particles"></canvas>
                </div>'''
        buttons = '''                <div class="controls">
                    <button id="action" type="button" aria-pressed="false">Pause animation</button>
                    <button id="reset" type="button" class="secondary">Reset</button>
                    <p id="status" class="status" role="status" aria-live="polite">Starting animation…</p>
                </div>'''
    elif kind == "webgl":
        scene = '''                <canvas id="scene-canvas" width="960" height="540" aria-label="Rotating WebGL cube generated by Dart">WebGL is required.</canvas>'''
        buttons = '''                <div class="controls">
                    <button id="action" type="button" aria-pressed="false">Pause animation</button>
                    <button id="reset" type="button" class="secondary">Reset cube</button>
                    <p id="status" class="status" role="status" aria-live="polite">Starting WebGL…</p>
                </div>'''
    else:
        raise ValueError(kind)
    previous_link = '<a href="index.html">← Book contents</a>' if index == 0 else f'<a href="demo-{CHAPTERS[index - 1][0]}.html">← {escape(CHAPTERS[index - 1][1])}</a>'
    next_link = '<span></span>' if index == len(CHAPTERS) - 1 else f'<a href="demo-{CHAPTERS[index + 1][0]}.html">{escape(CHAPTERS[index + 1][1])} →</a>'
    body = f'''{header()}
    <main class="book-layout">
        <nav class="book-nav" aria-label="Demo chapters">
            <p>lmdart demo book</p>
            <ol>
{chr(10).join(nav)}
            </ol>
        </nav>
        <article class="chapter">
            <header class="chapter-heading">
                <p class="eyebrow">Chapter {index + 1:02d} · Dart + browser APIs</p>
                <h1>{escape(heading)}</h1>
                <p class="lede">{escape(description)}</p>
            </header>
            <section class="demo-shell" aria-label="Live {escape(title, quote=True)} example">
{scene}
{buttons}
            </section>
            <section class="chapter-notes">
                <div><h2>How it works</h2><p>The HTML is a static template. JSON supplies values or drawing data. Dart owns rendering and browser events; boot.js registers small JavaScript handlers through LMDart.register.</p></div>
                <pre><code>{escape(code)}</code></pre>
            </section>
            <nav class="pager" aria-label="Chapter navigation">{previous_link}{next_link}</nav>
        </article>
    </main>
{footer()}
    <noscript>This chapter needs JavaScript enabled. Dart compiles to JavaScript, then boot.js registers the handlers.</noscript>'''
    (OUT / f"demo-{slug}.html").write_text(document(f"{title} · lmdart", description, slug, body))

print(f"Generated {len(CHAPTERS) + 1} lmdart book pages")
