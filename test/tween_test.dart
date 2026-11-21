import 'package:lmdart/src/tween_math.dart';
import 'package:test/test.dart';

void main() {
  test('ease clamps both ends and is symmetric', () {
    expect(easeInOutCubic(-1), 0);
    expect(easeInOutCubic(2), 1);
    expect(easeInOutCubic(.5), .5);
    expect(easeInOutCubic(.25), closeTo(1 - easeInOutCubic(.75), .000001));
  });

  test('position and attribute math interpolate and clamp', () {
    expect(tweenValue(20, 60, 0, 3200), 20);
    expect(tweenValue(20, 60, 1600, 3200), 40);
    expect(tweenValue(20, 60, 4000, 3200), 60);
    expect(() => tweenValue(0, 1, 0, 0), throwsArgumentError);
  });

}
