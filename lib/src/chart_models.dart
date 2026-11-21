import 'json_values.dart';

final class Bar {
  final String label;
  final double value;
  final String color;
  Bar(Object? value)
      : this._(jsonMap(value, 'bar'));
  Bar._(Map<String, Object?> data)
      : label = jsonString(data['label'], 'bar label'),
        value = jsonNumber(data['value'], 'bar value'),
        color = jsonString(data['color'], 'bar color');
}

final class Slice {
  final String label;
  final double value;
  final String color;
  Slice(Object? value)
      : this._(jsonMap(value, 'slice'));
  Slice._(Map<String, Object?> data)
      : label = jsonString(data['label'], 'slice label'),
        value = jsonNumber(data['value'], 'slice value'),
        color = jsonString(data['color'], 'slice color') {
    if (this.value < 0) throw FormatException('slice value must be nonnegative');
  }
}

final class Point {
  final double x;
  final double y;
  Point(Object? value)
      : this._(jsonMap(value, 'point'));
  Point._(Map<String, Object?> data)
      : x = jsonNumber(data['x'], 'point x'),
        y = jsonNumber(data['y'], 'point y');
}

final class Series {
  final String name;
  final String color;
  final List<Point> points;
  Series(Object? value)
      : this._(jsonMap(value, 'series'));
  Series._(Map<String, Object?> data)
      : name = jsonString(data['name'], 'series name'),
        color = jsonString(data['color'], 'series color'),
        points = jsonList(data['points'], 'series points').map(Point.new).toList() {
    if (points.isEmpty) throw FormatException('series must have points');
  }
}
