import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:lmdart/src/bridge.dart';
import 'package:lmdart/src/charts.dart';
import 'package:lmdart/src/draw2d.dart';
import 'package:lmdart/src/hydration.dart';
import 'package:lmdart/src/json.dart';
import 'package:lmdart/src/table.dart';
import 'package:lmdart/src/tween.dart';
import 'package:lmdart/src/webgl_cube.dart';
import 'package:web/web.dart' as web;

final bridge = RuntimeBridge();

void main() {
  bridge.registerDart('dart.stamp', (context) {
    final value = context['value'] as JSString?;
    return 'Dart received ${value?.toDart ?? 'empty'}';
  });
  bridge.install();
  bridge.onStart = () => _dispatch();
}

Future<void> _dispatch() async {
  final page = web.document.body?.getAttribute('data-page') ?? 'cover';
  try {
    switch (page) {
      case 'cover':
        break;
      case 'hydration':
        await _hydration();
      case 'table':
        await _table();
      case 'svg':
        await _svg();
      case 'canvas':
        await _canvas();
      case 'chart':
        await _chart();
      case 'plot':
        await _plot();
      case 'animation':
        await _animation();
      case 'webgl':
        await _webgl();
      default:
        throw StateError('Unknown page $page');
    }
  } catch (error) {
    web.document.getElementById('status')?.textContent = 'Unable to start $page: $error';
    rethrow;
  }
}

Future<void> _hydration() async {
  final data = jsonMap(await fetchJson('data/hydration.json'), 'hydration');
  final card = _element('hydration-card');
  hydrate(card, data);
  _element('action').onClick.listen((_) {
    bridge.call('hydrate.clicked', _context({'value': 'hydration'}));
  });
  _ready('Hydrated static HTML from JSON. Click the button to run JavaScript and Dart handlers.');
}

Future<void> _table() async {
  final table = JsonTable(jsonMap(await fetchJson('data/table.json'), 'table'));
  table.bind(_element('data-table') as web.HTMLTableElement, (index) {
    bridge.call('table.selected', _context({'index': index, 'name': table.rows[index][0]}));
  });
  _ready('Bound ${table.rows.length} JSON rows to the HTML table. Select a row with click or Enter.');
}

Future<void> _svg() async {
  final data = await fetchJson('data/svg.json');
  drawSvg(_element('scene'), data);
  _element('action').onClick.listen((_) {
    final color = bridge.call('svg.palette', _context({})) as JSString;
    drawSvg(_element('scene'), data, palette: color.toDart);
    _ready('SVG redrawn from JSON with JavaScript-selected color ${color.toDart}.');
  });
  _ready('SVG created from data/svg.json. Change the palette through the registered JavaScript handler.');
}

Future<void> _canvas() async {
  final data = await fetchJson('data/canvas.json');
  final canvas = _element('scene-canvas') as web.HTMLCanvasElement;
  final marks = <web.DOMPoint>[];
  drawCanvas(canvas, data, marks: marks);
  canvas.onClick.listen((event) {
    final bounds = canvas.getBoundingClientRect();
    final x = event.offsetX * canvas.width / bounds.width;
    final y = event.offsetY * canvas.height / bounds.height;
    final accepted = bridge.call('canvas.point', _context({'x': x, 'y': y})) as JSBoolean;
    if (accepted.toDart) marks.add(web.DOMPoint(x, y));
    drawCanvas(canvas, data, marks: marks);
    _ready('Canvas redrawn with ${marks.length} JavaScript-approved pointer mark(s).');
  });
  _element('action').onClick.listen((_) {
    marks.clear();
    drawCanvas(canvas, data);
    _ready('Canvas pointer marks cleared.');
  });
  _ready('Canvas drawn from data/canvas.json. Click the drawing to add a pointer mark.');
}

Future<void> _chart() async {
  final data = jsonMap(await fetchJson('data/chart.json'), 'charts');
  renderBarChart(_element('bar-chart'), data['bar']);
  renderPieChart(_element('pie-chart'), data['pie']);
  _ready('Rendered bar and pie charts from data/chart.json as retained SVG.');
}

Future<void> _plot() async {
  final data = jsonMap(await fetchJson('data/plot.json'), 'plots');
  renderPlot(_element('line-plot') as web.HTMLCanvasElement, data['line']);
  renderPlot(_element('scatter-plot') as web.HTMLCanvasElement, data['scatter'], scatter: true);
  _ready('Rendered line and scatter plots from data/plot.json through Canvas 2D.');
}

Future<void> _animation() async {
  final data = await fetchJson('data/tween.json');
  final canvas = _element('particle-canvas') as web.HTMLCanvasElement;
  final player = TweenPlayer(data, onFrame: (seconds) => _particles(canvas, seconds));
  player.start();
  _element('action').onClick.listen((_) {
    player.toggle();
    bridge.call('animation.toggled', _context({'paused': player.paused}));
  });
  _element('reset').onClick.listen((_) {
    player.reset();
    bridge.call('animation.reset', _context({}));
  });
  _ready('Animation running: SVG position/radius/opacity tweens and Canvas particles share one Dart clock.');
}

Future<void> _webgl() async {
  final data = await fetchJson('data/webgl.json');
  final cube = WebglCube(_element('scene-canvas') as web.HTMLCanvasElement, data);
  cube.start();
  _element('action').onClick.listen((_) {
    cube.toggle();
    bridge.call('animation.toggled', _context({'paused': cube.paused}));
  });
  _element('reset').onClick.listen((_) {
    cube.reset();
    bridge.call('animation.reset', _context({}));
  });
  _ready('WebGL cube running: Dart shaders, matrices, buffers, and animation; no 3D JavaScript library.');
}

void _particles(web.HTMLCanvasElement canvas, double seconds) {
  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  context.fillStyle = '#0b1726'.toJS;
  context.fillRect(0, 0, 320, 540);
  for (var i = 0; i < 16; i++) {
    final angle = seconds * (.7 + i % 4 * .1) + i * .7;
    final x = 160 + math.cos(angle) * (35 + i * 5);
    final y = 270 + math.sin(angle * 1.17) * (25 + i * 4);
    context.beginPath();
    context.arc(x, y, 4 + i % 4, 0, math.pi * 2);
    context.fillStyle = (i % 2 == 0 ? '#61d6c5' : '#ffcb6b').toJS;
    context.fill();
  }
}

JSObject _context(Map<String, Object?> values) => values.jsify() as JSObject;
web.Element _element(String id) => web.document.getElementById(id) ?? (throw StateError('Missing #$id'));
void _ready(String message) => _element('status').textContent = 'Ready: $message';
