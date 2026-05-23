import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_chart/kline_chart.dart';
import 'package:kline_chart/src/indicators/indicator_data_cache.dart';
import 'package:kline_chart/src/kline_painter.dart';

const _dataSizes = [2000, 5000, 10000];
const _warmupIterations = 10;
const _iterations = 100;
const _chartSize = Size(390, 900);

void main() {
  testWidgets('benchmark indicator calculation and chart painting', (_) async {
    debugPrint('Run: fvm flutter test tool/kline_benchmark_test.dart');
    debugPrint('warmup_iterations=$_warmupIterations,iterations=$_iterations');
    debugPrint('size,indicator_avg_ms,paint_avg_ms');

    for (final size in _dataSizes) {
      final data = _buildKLineData(size);
      _configureController(data);
      final beginIdx = (data.length - KLineController.shared.itemCount)
          .clamp(0.0, data.length.toDouble());

      _runRepeated(
          () => _benchmarkIndicators(data, beginIdx), _warmupIterations);
      _runRepeated(() => _paintChart(data, beginIdx), _warmupIterations);

      final indicatorAvgMs = _averageMilliseconds(
        () => _benchmarkIndicators(data, beginIdx),
        _iterations,
      );
      final paintAvgMs = _averageMilliseconds(
        () => _paintChart(data, beginIdx),
        _iterations,
      );

      debugPrint(
        '$size,${indicatorAvgMs.toStringAsFixed(3)},'
        '${paintAvgMs.toStringAsFixed(3)}',
      );
    }
  });
}

double _averageMilliseconds(void Function() body, int iterations) {
  final stopwatch = Stopwatch()..start();
  _runRepeated(body, iterations);
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds / iterations / 1000.0;
}

void _runRepeated(void Function() body, int iterations) {
  for (var i = 0; i < iterations; ++i) {
    body();
  }
}

void _benchmarkIndicators(List<KLineData> data, double beginIdx) {
  final cache = KLineIndicatorDataCache(data, beginIdx);
  cache.result(IndicatorType.ma);
  cache.result(IndicatorType.boll);
  cache.result(IndicatorType.sar);
  cache.result(IndicatorType.maVol);
  cache.result(IndicatorType.macd);
  cache.result(IndicatorType.kdj);
  cache.result(IndicatorType.rsi);
  cache.result(IndicatorType.wr);
  cache.result(IndicatorType.obv);
}

void _paintChart(List<KLineData> data, double beginIdx) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  KLinePainter(data, beginIdx).paint(canvas, _chartSize);
  recorder.endRecording().dispose();
}

void _configureController(List<KLineData> data) {
  KLineController.shared.data = data;
  KLineController.shared.itemCount = 120;
  KLineController.shared.spacing = 2;
  KLineController.shared.itemWidth = 0;
  KLineController.shared.klineMargin = const EdgeInsets.all(0);
  KLineController.shared.mainIndicatorInfoMargin = 5;
  KLineController.shared.subIndicatorInfoMargin = 5;
  KLineController.shared.indicatorSpacing = 10;
  KLineController.shared.subIndicatorHeight = 80;
  KLineController.shared.indicatorInfoHeight = 15;
  KLineController.shared.showMainIndicators = [
    IndicatorType.boll,
    IndicatorType.sar,
  ];
  KLineController.shared.showSubIndicators = [
    IndicatorType.vol,
    IndicatorType.macd,
    IndicatorType.kdj,
    IndicatorType.rsi,
    IndicatorType.wr,
    IndicatorType.obv,
  ];
  KLineController.shared.volMaPeriods = [7, 14];
  KLineController.shared.macdPeriods = [12, 26, 9];
  KLineController.shared.kdjPeriods = [9, 3, 3];
  KLineController.shared.rsiPeriods = [6, 12, 24];
  KLineController.shared.wrPeriods = [7, 14];
  KLineController.shared.bollPeriod = 20;
  KLineController.shared.bollBandwidth = 2;
  KLineController.shared.sarStart = 0.02;
  KLineController.shared.sarIncrement = 0.02;
  KLineController.shared.sarMax = 0.2;
  KLineController.shared.showTimeChart = false;
  KLineController.shared.chartStyle = const KLineChartStyle();
  KLineController.shared.candleStyle = const KLineCandleStyle();
  KLineController.shared.volumeStyle = const KLineVolumeStyle();
}

List<KLineData> _buildKLineData(int count) {
  return List.generate(count, (index) {
    final wave = (index % 97) * 0.35;
    final drift = index * 0.015;
    final close = 100.0 + drift + wave;
    final open = close + (index.isEven ? -0.8 : 0.8);
    final high = open > close ? open + 1.4 : close + 1.4;
    final low = open < close ? open - 1.4 : close - 1.4;
    return KLineData(
      open: open,
      high: high,
      low: low,
      close: close,
      volume: 500.0 + (index % 73) * 13.0,
      time: index,
    );
  });
}
