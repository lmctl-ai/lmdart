import 'dart:js_interop';

import 'package:web/web.dart' as web;

export 'json_values.dart';

Future<Object?> fetchJson(String path) async {
  final response = await web.window.fetch(path.toJS).toDart;
  if (!response.ok) {
    throw StateError('JSON request failed: HTTP ${response.status} for $path');
  }
  final value = await response.json().toDart;
  return value.dartify();
}
