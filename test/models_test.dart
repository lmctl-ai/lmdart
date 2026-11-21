import 'package:lmdart/src/chart_models.dart';
import 'package:test/test.dart';

void main() {
  group('JSON chart models', () {
    test('parse bars, slices, points, and series', () {
      final bar = Bar({'label': 'A', 'value': 42, 'color': '#fff'});
      expect(bar.label, 'A');
      expect(bar.value, 42);
      final slice = Slice({'label': 'A', 'value': 2.5, 'color': '#fff'});
      expect(slice.value, 2.5);
      final series = Series({'name': 'A', 'color': '#fff', 'points': [
        {'x': 1, 'y': 2}, {'x': 3, 'y': 4},
      ]});
      expect(series.points, hasLength(2));
      expect(series.points[1].y, 4);
    });

    test('reject malformed and negative chart data', () {
      expect(() => Bar({'label': 'A', 'value': 'bad', 'color': '#fff'}), throwsFormatException);
      expect(() => Slice({'label': 'A', 'value': -1, 'color': '#fff'}), throwsFormatException);
      expect(() => Series({'name': 'A', 'color': '#fff', 'points': []}), throwsFormatException);
    });

    test('reject nonfinite coordinates and nonobject input', () {
      expect(() => Point({'x': double.nan, 'y': 1}), throwsFormatException);
      expect(() => Bar('bad'), throwsFormatException);
    });
  });
}
