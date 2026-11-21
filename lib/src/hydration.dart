import 'package:web/web.dart' as web;

import 'json.dart';

void hydrate(web.Element root, Map<String, Object?> data) {
  final nodes = root.querySelectorAll('[data-hydrate]');
  for (var i = 0; i < nodes.length; i++) {
    final element = nodes.item(i)! as web.Element;
    final key = element.getAttribute('data-hydrate')!;
    final value = jsonString(data[key], 'hydration field $key');
    final attribute = element.getAttribute('data-hydrate-attribute');
    if (attribute == null) {
      element.textContent = value;
    } else {
      element.setAttribute(attribute, value);
    }
  }
  root.setAttribute('data-hydrated', 'true');
}
