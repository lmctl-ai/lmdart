final class LinearScale {
  final double domainMin;
  final double domainMax;
  final double rangeMin;
  final double rangeMax;

  LinearScale(this.domainMin, this.domainMax, this.rangeMin, this.rangeMax) {
    if (![domainMin, domainMax, rangeMin, rangeMax].every((value) => value.isFinite) ||
        domainMax <= domainMin || rangeMax == rangeMin) {
      throw ArgumentError('Scale domains must be finite and nonempty');
    }
  }

  double map(double value) {
    return rangeMin + (value - domainMin) / (domainMax - domainMin) * (rangeMax - rangeMin);
  }

  List<double> ticks([int count = 6]) {
    if (count < 2) throw ArgumentError('At least two ticks required');
    final raw = (domainMax - domainMin) / (count - 1);
    final power = _pow10(raw.floorLog10());
    final fraction = raw / power;
    final step = (fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 5 ? 5 : 10) * power;
    final result = <double>[];
    var value = (domainMin / step).ceil() * step;
    while (value <= domainMax + step * 0.000001) {
      result.add(double.parse(value.toStringAsFixed(10)));
      value += step;
    }
    return result;
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent.abs(); i++) result *= exponent < 0 ? 0.1 : 10;
    return result;
  }
}

extension _DoubleLog on double {
  int floorLog10() {
    var value = this;
    var exponent = 0;
    while (value >= 10) {
      value /= 10;
      exponent++;
    }
    while (value < 1) {
      value *= 10;
      exponent--;
    }
    return exponent;
  }
}
