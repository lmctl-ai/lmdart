import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'json.dart';
import 'tween_math.dart';

final class AttributeTween {
  final String selector;
  final String attribute;
  final double from;
  final double to;
  AttributeTween(Object? value)
      : this._(jsonMap(value, 'attribute tween'));
  AttributeTween._(Map<String, Object?> data)
      : selector = jsonString(data['selector'], 'tween selector'),
        attribute = jsonString(data['attribute'], 'tween attribute'),
        from = jsonNumber(data['from'], 'tween from'),
        to = jsonNumber(data['to'], 'tween to');
}

final class PositionTween {
  final String selector;
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  PositionTween(Object? value)
      : this._(jsonMap(value, 'position tween'));
  PositionTween._(Map<String, Object?> data)
      : selector = jsonString(data['selector'], 'position selector'),
        fromX = jsonNumber(data['fromX'], 'position fromX'),
        fromY = jsonNumber(data['fromY'], 'position fromY'),
        toX = jsonNumber(data['toX'], 'position toX'),
        toY = jsonNumber(data['toY'], 'position toY');
}

final class TweenPlayer {
  final double duration;
  final List<AttributeTween> attributes;
  final List<PositionTween> positions;
  final void Function(double seconds)? onFrame;
  bool paused = false;
  double elapsed = 0;
  double? previous;

  factory TweenPlayer(Object? data, {void Function(double seconds)? onFrame}) {
    return TweenPlayer._(jsonMap(data, 'animation'), onFrame: onFrame);
  }
  TweenPlayer._(Map<String, Object?> data, {this.onFrame})
      : duration = jsonNumber(data['duration'], 'animation duration'),
        attributes = jsonList(data['attributes'], 'animation attributes').map(AttributeTween.new).toList(),
        positions = jsonList(data['positions'], 'animation positions').map(PositionTween.new).toList() {
    if (duration <= 0) throw FormatException('animation duration must be positive');
  }

  void start() {
    render();
    web.window.requestAnimationFrame(_frame.toJS);
  }

  void toggle() {
    paused = !paused;
    previous = null;
  }

  void reset() {
    elapsed = 0;
    previous = null;
    render();
  }

  void _frame(double timestamp) {
    if (!paused) {
      if (previous != null) elapsed += (timestamp - previous!).clamp(0, 50);
      previous = timestamp;
      render();
    }
    web.window.requestAnimationFrame(_frame.toJS);
  }

  void render() {
    for (final tween in attributes) {
      final value = tweenValue(tween.from, tween.to, elapsed, duration);
      web.document.querySelector(tween.selector)?.setAttribute(tween.attribute, '$value');
    }
    for (final tween in positions) {
      final x = tweenValue(tween.fromX, tween.toX, elapsed, duration);
      final y = tweenValue(tween.fromY, tween.toY, elapsed, duration);
      web.document.querySelector(tween.selector)?.setAttribute('transform', 'translate($x $y)');
    }
    onFrame?.call(elapsed / 1000);
  }
}
