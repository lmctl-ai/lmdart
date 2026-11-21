import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'json.dart';

const svgNamespace = 'http://www.w3.org/2000/svg';

final class DrawCommand {
  final String type;
  final Map<String, Object?> values;

  DrawCommand(Object? input)
      : values = jsonMap(input, 'draw command'),
        type = jsonString(jsonMap(input, 'draw command')['type'], 'draw type');

  double number(String name, [double fallback = 0]) {
    final value = values[name];
    return value == null ? fallback : jsonNumber(value, '$type.$name');
  }

  String string(String name, [String fallback = '']) {
    final value = values[name];
    return value == null ? fallback : jsonString(value, '$type.$name');
  }

  List<DrawCommand> children() {
    return jsonList(values['points'] ?? const [], '$type.points').map((value) {
      return DrawCommand({'type': 'point', ...jsonMap(value, '$type point')});
    }).toList();
  }
}

List<DrawCommand> drawCommands(Object? data) {
  return jsonList(jsonMap(data, 'drawing')['commands'], 'drawing commands').map(DrawCommand.new).toList();
}

void drawSvg(web.Element container, Object? data, {String? palette}) {
  container.textContent = '';
  final document = jsonMap(data, 'drawing');
  final width = jsonNumber(document['width'], 'drawing width');
  final height = jsonNumber(document['height'], 'drawing height');
  final svg = web.document.createElementNS(svgNamespace, 'svg');
  svg.setAttribute('viewBox', '0 0 $width $height');
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', jsonString(document['title'], 'drawing title'));
  container.appendChild(svg);
  for (final command in drawCommands(data)) {
    final element = _svgCommand(command, palette);
    if (element != null) svg.appendChild(element);
  }
}

web.Element? _svgCommand(DrawCommand command, String? palette) {
  final color = palette ?? command.string('color', '#61d6c5');
  final web.Element element;
  switch (command.type) {
    case 'rect':
      element = web.document.createElementNS(svgNamespace, 'rect');
      _attributes(element, command, ['x', 'y', 'width', 'height', 'rx']);
      element.setAttribute('fill', color);
    case 'circle':
      element = web.document.createElementNS(svgNamespace, 'circle');
      _attributes(element, command, ['cx', 'cy', 'r']);
      element.setAttribute('fill', color);
    case 'line':
      element = web.document.createElementNS(svgNamespace, 'line');
      _attributes(element, command, ['x1', 'y1', 'x2', 'y2']);
      element.setAttribute('stroke', color);
      element.setAttribute('stroke-width', '${command.number('strokeWidth', 2)}');
    case 'polyline':
      element = web.document.createElementNS(svgNamespace, 'polyline');
      final points = command.children().map((point) => '${point.number('x')},${point.number('y')}').join(' ');
      element.setAttribute('points', points);
      element.setAttribute('fill', 'none');
      element.setAttribute('stroke', color);
      element.setAttribute('stroke-width', '${command.number('strokeWidth', 2)}');
    case 'path':
      element = web.document.createElementNS(svgNamespace, 'path');
      element.setAttribute('d', command.string('d'));
      element.setAttribute('fill', color);
    case 'text':
      element = web.document.createElementNS(svgNamespace, 'text');
      _attributes(element, command, ['x', 'y']);
      element.setAttribute('fill', color);
      element.setAttribute('font-size', '${command.number('fontSize', 16)}');
      element.textContent = command.string('text');
    default:
      throw FormatException('Unknown SVG command: ${command.type}');
  }
  if (command.values.containsKey('opacity')) {
    element.setAttribute('opacity', '${command.number('opacity')}');
  }
  return element;
}

void drawCanvas(web.HTMLCanvasElement canvas, Object? data, {List<web.DOMPoint> marks = const []}) {
  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
  if (context == null) throw StateError('Canvas 2D is unavailable');
  final document = jsonMap(data, 'drawing');
  final width = jsonNumber(document['width'], 'drawing width');
  final height = jsonNumber(document['height'], 'drawing height');
  canvas.width = width.toInt();
  canvas.height = height.toInt();
  final commands = drawCommands(data);
  for (final command in commands) {
    _canvasCommand(context, command);
  }
  for (final mark in marks) {
    context.beginPath();
    context.arc(mark.x, mark.y, 12, 0, math.pi * 2);
    context.fillStyle = '#ff7f9f'.toJS;
    context.fill();
    context.strokeStyle = '#ffffff'.toJS;
    context.lineWidth = 2;
    context.stroke();
  }
}

void _canvasCommand(web.CanvasRenderingContext2D context, DrawCommand command) {
  final color = command.string('color', '#61d6c5');
  switch (command.type) {
    case 'rect':
      context.fillStyle = color.toJS;
      context.fillRect(command.number('x'), command.number('y'), command.number('width'), command.number('height'));
    case 'circle':
      context.beginPath();
      context.arc(command.number('cx'), command.number('cy'), command.number('r'), 0, math.pi * 2);
      context.fillStyle = color.toJS;
      context.fill();
    case 'line':
      context.beginPath();
      context.moveTo(command.number('x1'), command.number('y1'));
      context.lineTo(command.number('x2'), command.number('y2'));
      context.strokeStyle = color.toJS;
      context.lineWidth = command.number('strokeWidth', 2);
      context.stroke();
    case 'polyline':
      final points = command.children();
      if (points.isEmpty) return;
      context.beginPath();
      context.moveTo(points.first.number('x'), points.first.number('y'));
      for (final point in points.skip(1)) context.lineTo(point.number('x'), point.number('y'));
      context.strokeStyle = color.toJS;
      context.lineWidth = command.number('strokeWidth', 2);
      context.stroke();
    case 'path':
      final path = web.Path2D(command.string('d').toJS);
      context.fillStyle = color.toJS;
      context.fill(path);
    case 'text':
      context.fillStyle = color.toJS;
      context.font = '${command.number('fontSize', 16)}px system-ui, sans-serif';
      context.fillText(command.string('text'), command.number('x'), command.number('y'));
    default:
      throw FormatException('Unknown Canvas command: ${command.type}');
  }
}

void _attributes(web.Element element, DrawCommand command, List<String> names) {
  for (final name in names) element.setAttribute(name, '${command.number(name)}');
}
