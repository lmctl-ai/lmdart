import 'package:lmdart/src/scale.dart';
import 'package:test/test.dart';

void main() {
  test('linear scale maps normal and inverted ranges', () {
    final scale = LinearScale(0, 100, 500, 100);
    expect(scale.map(0), 500);
    expect(scale.map(50), 300);
    expect(scale.map(100), closeTo(100, 0.000001));
  });

  test('ticks use stable round steps', () {
    expect(LinearScale(0, 100, 0, 1).ticks(), [0, 20, 40, 60, 80, 100]);
    expect(LinearScale(0, 1, 0, 1).ticks(), [0, .2, .4, .6, .8, 1]);
  });

  test('invalid domains and tick counts are rejected', () {
    expect(() => LinearScale(1, 1, 0, 100), throwsArgumentError);
    expect(() => LinearScale(0, 1, 0, 1).ticks(1), throwsArgumentError);
  });
}
