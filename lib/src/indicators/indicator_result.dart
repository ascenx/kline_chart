class IndicatorResult {
  final List<List<double>> data;
  final double maxValue;
  final double minValue;

  IndicatorResult(this.data, this.maxValue, this.minValue);

  static IndicatorResult get empty => IndicatorResult([],0.0, 0.0);
}