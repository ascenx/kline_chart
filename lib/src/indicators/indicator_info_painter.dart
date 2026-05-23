import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'indicator_data_cache.dart';
import 'indicator_line_painter.dart';
import 'indicator_result.dart';
import 'macd_painter.dart';
import '../kline_controller.dart';
import '../kline_data.dart';
import '../kline_painter.dart';

class KLineIndicatorInfoPainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;
  final _IndicatorInfoConfig _config;
  final KLineIndicatorDataCache _indicatorDataCache;

  KLineIndicatorInfoPainter(this.klineData, this.beginIdx,
      {KLineIndicatorDataCache? indicatorDataCache})
      : _config = _IndicatorInfoConfig.fromController(KLineController.shared),
        _indicatorDataCache =
            indicatorDataCache ?? KLineIndicatorDataCache(klineData, beginIdx),
        super(repaint: KLineController.shared.longPressOffset);

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    final controller = KLineController.shared;
    final spacing = _config.spacing;
    final itemW = size.width / _config.itemCount - spacing;
    final selectedIndex = KLinePainter.selectedVisibleIndexForLongPress(
      longPressOffset: controller.longPressOffset.value,
      beginIdx: beginIdx,
      itemWidth: itemW,
      spacing: spacing,
      dataLength: klineData.length,
    );

    _paintMainIndicatorInfo(canvas, size, selectedIndex);
    _paintSubIndicatorInfo(canvas, size, selectedIndex);
  }

  void _paintMainIndicatorInfo(Canvas canvas, Size size, int? selectedIndex) {
    final showMainIndicators = _config.showMainIndicators;
    if (showMainIndicators.isEmpty) return;

    final isShowMA = showMainIndicators.contains(IndicatorType.ma);
    final isShowEMA = showMainIndicators.contains(IndicatorType.ema);
    if (isShowMA || isShowEMA) {
      final type = isShowMA ? IndicatorType.ma : IndicatorType.ema;
      final periods = _indicatorDataCache.periodsFor(type);
      final result = _indicatorResult(type);
      final leadingItemCount = isShowMA
          ? 1
          : KLinePainter.leadingLineDataCountForBeginIndex(beginIdx);
      IndicatorLinePainter.paintInfo(
        canvas,
        size,
        showMainIndicators.first,
        result.data,
        periods,
        _config.klineTop,
        selectedIndex: selectedIndex,
        leadingItemCount: leadingItemCount,
      );
    }

    final isShowBOLL = showMainIndicators.contains(IndicatorType.boll);
    if (isShowBOLL) {
      final periods = _indicatorDataCache.periodsFor(IndicatorType.boll);
      final result = _indicatorResult(IndicatorType.boll);
      IndicatorLinePainter.paintInfo(
        canvas,
        size,
        showMainIndicators.first,
        result.data,
        periods,
        _config.klineTop,
        selectedIndex: selectedIndex,
        leadingItemCount:
            KLinePainter.leadingLineDataCountForBeginIndex(beginIdx),
      );
    }

    final isShowSAR = showMainIndicators.contains(IndicatorType.sar);
    if (isShowSAR) {
      final result = _indicatorResult(IndicatorType.sar);
      IndicatorLinePainter.paintInfo(
        canvas,
        size,
        IndicatorType.sar,
        result.data,
        const [0],
        _config.klineTop,
        lineColors: [_config.sarColor],
        selectedIndex: selectedIndex,
      );
    }
  }

  void _paintSubIndicatorInfo(Canvas canvas, Size size, int? selectedIndex) {
    final showSubIndicators = _config.showSubIndicators;
    final subIndicatorCount = showSubIndicators.length;
    final indicatorH = _config.subIndicatorHeight;
    final indicatorSpacing = _config.indicatorSpacing;

    for (var idx = subIndicatorCount - 1; idx >= 0; --idx) {
      final type = showSubIndicators[idx];
      final orderIdx = subIndicatorCount - idx;
      final subTop = size.height -
          orderIdx * (indicatorH + indicatorSpacing) +
          indicatorSpacing;

      if (type == IndicatorType.vol) {
        final periods = _indicatorDataCache.periodsFor(IndicatorType.maVol);
        final result = _indicatorResult(IndicatorType.maVol);
        IndicatorLinePainter.paintInfo(
          canvas,
          size,
          IndicatorType.maVol,
          result.data,
          periods,
          subTop,
          selectedIndex: selectedIndex,
          leadingItemCount: 1,
        );
      } else if (type == IndicatorType.macd) {
        final result = _indicatorResult(IndicatorType.macd);
        final leadingDataCount =
            KLinePainter.leadingDataCountForBeginIndex(beginIdx);
        MACDPainter.paintInfoForData(
          canvas,
          size,
          result.data,
          _indicatorDataCache.periodsFor(type),
          subTop,
          lineColors: _config.indicatorColors,
          selectedIndex:
              selectedIndex == null ? null : selectedIndex + leadingDataCount,
        );
      } else if (type.isLine) {
        final result = _indicatorResult(type).data;
        IndicatorLinePainter.paintInfo(
          canvas,
          size,
          type,
          result,
          _indicatorDataCache.periodsFor(type),
          subTop,
          lineColors: _config.indicatorColors,
          selectedIndex: selectedIndex,
          leadingItemCount:
              KLinePainter.leadingLineDataCountForBeginIndex(beginIdx),
        );
      }
    }
  }

  IndicatorResult _indicatorResult(IndicatorType type) {
    return _indicatorDataCache.result(type);
  }

  @override
  bool shouldRepaint(covariant KLineIndicatorInfoPainter oldDelegate) {
    return oldDelegate.klineData != klineData ||
        oldDelegate.beginIdx != beginIdx ||
        oldDelegate._config != _config;
  }
}

class _IndicatorInfoConfig {
  final List<IndicatorType> showMainIndicators;
  final List<IndicatorType> showSubIndicators;
  final List<int> volMaPeriods;
  final List<int> macdPeriods;
  final List<int> kdjPeriods;
  final List<int> rsiPeriods;
  final List<int> wrPeriods;
  final List<Color> indicatorColors;
  final int bollPeriod;
  final int bollBandwidth;
  final double sarStart;
  final double sarIncrement;
  final double sarMax;
  final Color sarColor;
  final double subIndicatorHeight;
  final double indicatorSpacing;
  final double klineTop;
  final double itemCount;
  final double spacing;
  final KLineNumberFormatter? volumeFormatter;
  final KLineIndicatorFormatter? indicatorFormatter;

  _IndicatorInfoConfig({
    required this.showMainIndicators,
    required this.showSubIndicators,
    required this.volMaPeriods,
    required this.macdPeriods,
    required this.kdjPeriods,
    required this.rsiPeriods,
    required this.wrPeriods,
    required this.indicatorColors,
    required this.bollPeriod,
    required this.bollBandwidth,
    required this.sarStart,
    required this.sarIncrement,
    required this.sarMax,
    required this.sarColor,
    required this.subIndicatorHeight,
    required this.indicatorSpacing,
    required this.klineTop,
    required this.itemCount,
    required this.spacing,
    required this.volumeFormatter,
    required this.indicatorFormatter,
  });

  factory _IndicatorInfoConfig.fromController(KLineController controller) {
    return _IndicatorInfoConfig(
      showMainIndicators: List<IndicatorType>.of(controller.showMainIndicators),
      showSubIndicators: List<IndicatorType>.of(controller.showSubIndicators),
      volMaPeriods: List<int>.of(controller.volMaPeriods),
      macdPeriods: List<int>.of(controller.macdPeriods),
      kdjPeriods: List<int>.of(controller.kdjPeriods),
      rsiPeriods: List<int>.of(controller.rsiPeriods),
      wrPeriods: List<int>.of(controller.wrPeriods),
      indicatorColors: List<Color>.of(controller.indicatorColors),
      bollPeriod: controller.bollPeriod,
      bollBandwidth: controller.bollBandwidth,
      sarStart: controller.sarStart,
      sarIncrement: controller.sarIncrement,
      sarMax: controller.sarMax,
      sarColor: controller.sarColor,
      subIndicatorHeight: controller.subIndicatorHeight,
      indicatorSpacing: controller.indicatorSpacing,
      klineTop: controller.klineMargin.top,
      itemCount: controller.itemCount,
      spacing: controller.spacing,
      volumeFormatter: controller.volumeFormatter,
      indicatorFormatter: controller.indicatorFormatter,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _IndicatorInfoConfig &&
            listEquals(other.showMainIndicators, showMainIndicators) &&
            listEquals(other.showSubIndicators, showSubIndicators) &&
            listEquals(other.volMaPeriods, volMaPeriods) &&
            listEquals(other.macdPeriods, macdPeriods) &&
            listEquals(other.kdjPeriods, kdjPeriods) &&
            listEquals(other.rsiPeriods, rsiPeriods) &&
            listEquals(other.wrPeriods, wrPeriods) &&
            listEquals(other.indicatorColors, indicatorColors) &&
            other.bollPeriod == bollPeriod &&
            other.bollBandwidth == bollBandwidth &&
            other.sarStart == sarStart &&
            other.sarIncrement == sarIncrement &&
            other.sarMax == sarMax &&
            other.sarColor == sarColor &&
            other.subIndicatorHeight == subIndicatorHeight &&
            other.indicatorSpacing == indicatorSpacing &&
            other.klineTop == klineTop &&
            other.itemCount == itemCount &&
            other.spacing == spacing &&
            other.volumeFormatter == volumeFormatter &&
            other.indicatorFormatter == indicatorFormatter;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      Object.hashAll(showMainIndicators),
      Object.hashAll(showSubIndicators),
      Object.hashAll(volMaPeriods),
      Object.hashAll(macdPeriods),
      Object.hashAll(kdjPeriods),
      Object.hashAll(rsiPeriods),
      Object.hashAll(wrPeriods),
      Object.hashAll(indicatorColors),
      bollPeriod,
      bollBandwidth,
      sarStart,
      sarIncrement,
      sarMax,
      sarColor,
      subIndicatorHeight,
      indicatorSpacing,
      klineTop,
      itemCount,
      spacing,
      volumeFormatter,
      indicatorFormatter,
    ]);
  }
}
