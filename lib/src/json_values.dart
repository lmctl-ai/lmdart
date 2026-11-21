Map<String, Object?> jsonMap(Object? value, String description) {
  if (value is! Map) throw FormatException('$description must be a JSON object');
  return value.map((key, value) {
    if (key is! String) throw FormatException('$description has a nonstring key');
    return MapEntry(key, value);
  });
}

List<Object?> jsonList(Object? value, String description) {
  if (value is! List<Object?>) throw FormatException('$description must be a JSON array');
  return value;
}

String jsonString(Object? value, String description) {
  if (value is! String) throw FormatException('$description must be a string');
  return value;
}

double jsonNumber(Object? value, String description) {
  if (value is! num || !value.isFinite) throw FormatException('$description must be a finite number');
  return value.toDouble();
}
