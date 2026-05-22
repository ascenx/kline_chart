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
    open = json['open'] ?? 0.0;
    high = json['high'] ?? 0.0;
    low = json['low'] ?? 0.0;
    close = json['close'] ?? 0.0;
    volume = json['volume'] ?? 0.0;
    time = json['time'] ?? 0;
  }
}
