import 'package:lmdart/src/matrix4.dart';
import 'package:test/test.dart';

void main() {
  test('identity multiplication preserves a matrix', () {
    final translation = Matrix4.translation(2, 3, 4);
    final result = Matrix4.identity() * translation;
    expect(result.values, translation.values);
    expect(result.values[12], 2);
    expect(result.values[14], 4);
  });

  test('perspective uses column-major camera conventions', () {
    final matrix = Matrix4.perspective(1, 16 / 9, .1, 100);
    expect(matrix.values[0], closeTo(matrix.values[5] * 9 / 16, .000001));
    expect(matrix.values[11], -1);
    expect(matrix.values[15], 0);
  });

  test('matrix composition applies translation in camera space', () {
    final result = Matrix4.translation(1, 2, -4) * Matrix4.rotation(.2, .3);
    expect(result.values[12], 1);
    expect(result.values[13], 2);
    expect(result.values[14], -4);
  });

  test('invalid perspective is rejected', () {
    expect(() => Matrix4.perspective(0, 1, .1, 100), throwsArgumentError);
    expect(() => Matrix4.perspective(1, 1, 10, 1), throwsArgumentError);
  });
}
