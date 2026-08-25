class KLineData {
  double open = 0.0;
  double high = 0.0;
  double low = 0.0;
  double close = 0.0;
  double volume = 0.0;
  int time = 0;

  KLineData(
      {this.open = 0.0,
      this.high = 0.0,
      this.low = 0.0,
      this.close = 0.0,
      this.volume = 0.0,
      this.time = 0});

  KLineData.fromJson(dynamic json) {
    open = _asDouble(json['open']);
    high = _asDouble(json['high']);
    low = _asDouble(json['low']);
    close = _asDouble(json['close']);
    volume = _asDouble(json['volume']);
    time = _asInt(json['time']);
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
