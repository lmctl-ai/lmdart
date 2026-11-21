import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'chart_models.dart';
import 'draw2d.dart';
import 'json.dart';
import 'scale.dart';

void renderBarChart(web.Element container, Object? data) {
  final document = jsonMap(data, 'bar chart');
  final bars = jsonList(document['bars'], 'bars').map(Bar.new).toList();
  if (bars.isEmpty) throw FormatException('bar chart must have bars');
  drawSvg(container, _barDrawing(jsonString(document['title'], 'chart title'), bars));
}

void renderPieChart(web.Element container, Object? data) {
  final document = jsonMap(data, 'pie chart');
  final slices = jsonList(document['slices'], 'slices').map(Slice.new).toList();
  final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
  if (total <= 0) throw FormatException('pie chart requires a positive total');
  drawSvg(container, _pieDrawing(jsonString(document['title'], 'chart title'), slices, total));
}

void renderPlot(web.HTMLCanvasElement canvas, Object? data, {bool scatter = false}) {
  final document = jsonMap(data, 'plot');
  final series = jsonList(document['series'], 'plot series').map(Series.new).toList();
  if (series.isEmpty) throw FormatException('plot must have series');
  drawCanvas(canvas, _plotDrawing(jsonString(document['title'], 'plot title'), series, scatter));
}

Map<String, Object?> _barDrawing(String title, List<Bar> bars) {
  final commands = _base(title);
  final maximum = bars.map((bar) => bar.value).fold<double>(0, math.max);
  final scale = LinearScale(0, maximum == 0 ? 1 : maximum, 440, 100);
  for (final tick in scale.ticks()) {
    final y = scale.map(tick);
    commands.add({'type': 'line', 'x1': 65, 'y1': y, 'x2': 925, 'y2': y, 'color': '#263b53'});
    commands.add({'type': 'text', 'x': 54, 'y': y + 4, 'text': _number(tick), 'color': '#91a5bd', 'fontSize': 11});
  }
  final band = 860 / bars.length;
  for (var i = 0; i < bars.length; i++) {
    final bar = bars[i];
    final y = scale.map(bar.value);
    commands.add({'type': 'rect', 'x': 65 + i * band + band * .14, 'y': y,
      'width': band * .72, 'height': 440 - y, 'color': bar.color});
    commands.add({'type': 'text', 'x': 65 + (i + .5) * band, 'y': 466,
      'text': bar.label, 'color': '#91a5bd', 'fontSize': 12});
  }
  return _drawing(title, commands);
}

Map<String, Object?> _pieDrawing(String title, List<Slice> slices, double total) {
  final commands = _base(title);
  var angle = -math.pi / 2;
  for (final slice in slices) {
    final end = angle + slice.value / total * math.pi * 2;
    final startX = 270 + math.cos(angle) * 145;
    final startY = 310 + math.sin(angle) * 145;
    final endX = 270 + math.cos(end) * 145;
    final endY = 310 + math.sin(end) * 145;
    final large = end - angle > math.pi ? 1 : 0;
    commands.add({'type': 'path', 'd': 'M 270 310 L $startX $startY A 145 145 0 $large 1 $endX $endY Z', 'color': slice.color});
    final middle = (angle + end) / 2;
    if (slice.value / total > .07) {
      commands.add({'type': 'text', 'x': 270 + math.cos(middle) * 90, 'y': 310 + math.sin(middle) * 90,
        'text': '${(slice.value / total * 100).round()}%', 'color': '#07101c', 'fontSize': 15});
    }
    angle = end;
  }
  for (var i = 0; i < slices.length; i++) {
    final y = 180 + i * 65;
    commands.add({'type': 'rect', 'x': 555, 'y': y - 12, 'width': 14, 'height': 14, 'color': slices[i].color});
    commands.add({'type': 'text', 'x': 583, 'y': y, 'text': slices[i].label, 'color': '#edf5ff', 'fontSize': 14});
    commands.add({'type': 'text', 'x': 583, 'y': y + 21, 'text': _number(slices[i].value), 'color': '#91a5bd', 'fontSize': 12});
  }
  return _drawing(title, commands);
}

Map<String, Object?> _plotDrawing(String title, List<Series> series, bool scatter) {
  final points = series.expand((item) => item.points).toList();
  final minX = points.map((point) => point.x).reduce(math.min);
  final maxX = points.map((point) => point.x).reduce(math.max);
  final minY = points.map((point) => point.y).reduce(math.min);
  final maxY = points.map((point) => point.y).reduce(math.max);
  final x = LinearScale(minX == maxX ? minX - 1 : minX, minX == maxX ? maxX + 1 : maxX, 75, 920);
  final y = LinearScale(minY == maxY ? minY - 1 : minY, minY == maxY ? maxY + 1 : maxY, 440, 110);
  final commands = _base(title);
  for (final tick in y.ticks()) {
    final py = y.map(tick);
    commands.add({'type': 'line', 'x1': 75, 'y1': py, 'x2': 920, 'y2': py, 'color': '#263b53'});
    commands.add({'type': 'text', 'x': 60, 'y': py + 4, 'text': _number(tick), 'color': '#91a5bd', 'fontSize': 11});
  }
  for (final tick in x.ticks(7)) {
    commands.add({'type': 'text', 'x': x.map(tick), 'y': 468, 'text': _number(tick), 'color': '#91a5bd', 'fontSize': 11});
  }
  for (final item in series) {
    if (!scatter) {
      commands.add({'type': 'polyline', 'points': item.points.map((point) => {'x': x.map(point.x), 'y': y.map(point.y)}).toList(),
        'color': item.color, 'strokeWidth': 3});
    }
    for (final point in item.points) {
      commands.add({'type': 'circle', 'cx': x.map(point.x), 'cy': y.map(point.y), 'r': scatter ? 6 : 4, 'color': item.color});
    }
    final index = series.indexOf(item);
    commands.add({'type': 'circle', 'cx': 45 + index * 135, 'cy': 83, 'r': 5, 'color': item.color});
    commands.add({'type': 'text', 'x': 58 + index * 135, 'y': 88, 'text': item.name, 'color': '#91a5bd', 'fontSize': 12});
  }
  return _drawing(title, commands);
}

List<Map<String, Object?>> _base(String title) => [
  {'type': 'rect', 'x': 0, 'y': 0, 'width': 960, 'height': 540, 'color': '#0b1726'},
  {'type': 'text', 'x': 32, 'y': 48, 'text': title, 'color': '#edf5ff', 'fontSize': 24},
];

Map<String, Object?> _drawing(String title, List<Map<String, Object?>> commands) => {
  'title': title, 'width': 960, 'height': 540, 'commands': commands,
};

String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
