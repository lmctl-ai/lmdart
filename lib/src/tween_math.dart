double easeInOutCubic(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value < .5 ? 4 * value * value * value : 1 - 4 * (1 - value) * (1 - value) * (1 - value);
}

double tweenValue(double from, double to, double milliseconds, double duration) {
  if (duration <= 0 || !duration.isFinite) throw ArgumentError('Tween duration must be positive');
  final progress = easeInOutCubic(milliseconds / duration);
  return from + (to - from) * progress;
}
