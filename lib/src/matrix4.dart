import 'dart:math' as math;
import 'dart:typed_data';

final class Matrix4 {
  final Float32List values;

  Matrix4._(this.values);

  factory Matrix4.identity() {
    final value = Float32List(16);
    value[0] = value[5] = value[10] = value[15] = 1;
    return Matrix4._(value);
  }

  factory Matrix4.perspective(double fov, double aspect, double near, double far) {
    if (fov <= 0 || aspect <= 0 || near <= 0 || far <= near) throw ArgumentError('Invalid perspective');
    final f = 1 / math.tan(fov / 2);
    final value = Float32List(16);
    value[0] = f / aspect;
    value[5] = f;
    value[10] = (far + near) / (near - far);
    value[11] = -1;
    value[14] = 2 * far * near / (near - far);
    return Matrix4._(value);
  }

  factory Matrix4.translation(double x, double y, double z) {
    final value = Matrix4.identity();
    value.values[12] = x;
    value.values[13] = y;
    value.values[14] = z;
    return value;
  }

  factory Matrix4.rotation(double x, double y) {
    final sx = math.sin(x), cx = math.cos(x), sy = math.sin(y), cy = math.cos(y);
    final value = Matrix4.identity();
    value.values[0] = cy;
    value.values[2] = -sy;
    value.values[4] = sy * sx;
    value.values[5] = cx;
    value.values[6] = cy * sx;
    value.values[8] = sy * cx;
    value.values[9] = -sx;
    value.values[10] = cy * cx;
    return Matrix4._(value.values);
  }

  Matrix4 operator *(Matrix4 other) {
    final result = Float32List(16);
    for (var column = 0; column < 4; column++) {
      for (var row = 0; row < 4; row++) {
        var value = 0.0;
        for (var i = 0; i < 4; i++) value += values[i * 4 + row] * other.values[column * 4 + i];
        result[column * 4 + row] = value;
      }
    }
    return Matrix4._(result);
  }
}
