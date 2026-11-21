import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'json.dart';

typedef DartRuntimeHandler = Object? Function(JSObject context);

final class RuntimeBridge {
  final Map<String, JSFunction> _javascriptHandlers = {};
  final Map<String, DartRuntimeHandler> _dartHandlers = {};
  void Function()? onStart;

  void register(String name, JSFunction handler) {
    if (name.isEmpty || _dartHandlers.containsKey(name)) {
      throw ArgumentError('Duplicate or empty runtime handler: $name');
    }
    _javascriptHandlers[name] = handler;
  }

  void registerDart(String name, DartRuntimeHandler handler) {
    if (name.isEmpty || _javascriptHandlers.containsKey(name)) {
      throw ArgumentError('Duplicate or empty runtime handler: $name');
    }
    _dartHandlers[name] = handler;
  }

  JSAny? call(String name, JSObject context) {
    final javascript = _javascriptHandlers[name];
    if (javascript != null) return javascript.callAsFunction(null, context);
    final dart = _dartHandlers[name];
    if (dart != null) return dart(context).jsify();
    throw ArgumentError('Unknown runtime handler: $name');
  }

  void install() {
    final api = JSObject();
    api['version'] = '0.1.0'.toJS;
    api['register'] = ((JSString name, JSFunction handler) {
      register(name.toDart, handler);
    }).toJS;
    api['call'] = ((JSString name, JSObject context) {
      return call(name.toDart, context);
    }).toJS;
    api['start'] = (() => onStart?.call()).toJS;
    api['loadJson'] = ((JSString path, JSFunction success, JSFunction failure) {
      fetchJson(path.toDart).then((value) {
        success.callAsFunction(null, value.jsify());
      }).catchError((Object error) {
        failure.callAsFunction(null, error.toString().toJS);
      });
    }).toJS;
    api['setText'] = ((JSString selector, JSString value) {
      requireSelector(selector.toDart).textContent = value.toDart;
    }).toJS;
    api['setAttribute'] = ((JSString selector, JSString name, JSString value) {
      requireSelector(selector.toDart).setAttribute(name.toDart, value.toDart);
    }).toJS;
    globalContext['LMDart'] = api;
  }
}

web.Element requireSelector(String selector) {
  final element = web.document.querySelector(selector);
  if (element == null) throw StateError('No element matches $selector');
  return element;
}
