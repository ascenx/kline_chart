import 'package:flutter/material.dart';
import 'indicator_data_cache.dart';
import 'indicator_line_painter.dart';
import '../indicators/indicator_result.dart';
import '../kline_chart_style.dart';
import '../kline_controller.dart';
import '../kline_data.dart';

class VolPainter {
  final List<KLineData> klineData;
  final double beginIdx;
  final KLineVolumeStyle _style;
  final KLineIndicatorDataCache _indicatorDataCache;

  VolPainter(this.klineData, this.beginIdx,
      {KLineIndicatorDataCache? indicatorDataCache})
      : _style = KLineController.shared.volumeStyle,
        _indicatorDataCache =
            indicatorDataCache ?? KLineIndicatorDataCache(klineData, beginIdx);

  final riseRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.green
    ..isAntiAlias = true;

  final fallRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red
    ..isAntiAlias = true;

  void paint(Canvas canvas, Size size, double max, double slideOffset,
      {int? selectedIndex, bool showInfo = true}) {
    if (klineData.isEmpty) return;
    riseRectPaint.color = _style.riseColor;
    fallRectPaint.color = _style.fallColor;

    double height = KLineController.shared.subIndicatorHeight;
    double width = size.width;

    double spacing = KLineController.shared.spacing;
    double itemW = KLineController.getItemWidth(width);
    double itemCount = KLineController.shared.itemCount;

    double min = 0.0;
    // calculated MA volume
    List<int> maPeriods = _indicatorDataCache.periodsFor(IndicatorType.maVol);
    IndicatorResult maRes = _indicatorDataCache.result(IndicatorType.maVol);
    List<List<double>> maList = [];
    double maMax = maRes.maxValue;
    maList = maRes.data;
    if (maMax > max) {
      max = maMax;
    }

    double valueOffset = max;
    double rectLeft = 0;

    List showSubIndicators = KLineController.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double originBtm = size.height;
    if (subIndicatorCount == 2 &&
        showSubIndicators.first == IndicatorType.vol) {
      originBtm = size.height -
          KLineController.shared.subIndicatorHeight -
          KLineController.shared.indicatorSpacing;
    }
    // originBtm -= KLineConfig.shared.indicatorInfoHeight;

    double endIndex = beginIdx + itemCount;
    if (endIndex > klineData.length) {
      endIndex = klineData.length.toDouble();
    }
    for (var i = beginIdx; i < endIndex; ++i) {
      final dataIndex = i.ceil();
      if (dataIndex >= klineData.length) break;
      KLineData data = klineData[dataIndex < 0 ? 0 : dataIndex];

      double open = data.open;
      double close = data.close;
      double volume = data.volume;

      double volumeH = valueOffset == 0.0
          ? 0.0
          : (height - KLineController.shared.indicatorInfoHeight) *
              volume /
              valueOffset;

      canvas.drawRect(
          Rect.fromLTWH(
              rectLeft + slideOffset, originBtm - volumeH, itemW, volumeH),
          close > open ? riseRectPaint : fallRectPaint);

      rectLeft += (itemW + spacing);
    }

    // debug
    // if (KLineConfig.shared.isDebug) {
    //   KLineConfig.shared.drawDebugRect(canvas, Rect.fromLTWH(0, originBtm - KLineConfig.shared.subIndicatorHeight, width, height), Colors.orange.withOpacity(0.5));
    // }

    // volume ma indicator
    IndicatorLinePainter.paint(
        canvas,
        Size(size.width, height),
        height - KLineController.shared.indicatorInfoHeight,
        IndicatorType.maVol,
        maList,
        maPeriods,
        beginIdx,
        slideOffset,
        max,
        min,
        top: originBtm - height,
        infoTopOffset: 0.0,
        selectedIndex: selectedIndex,
        showInfo: showInfo);
  }

  void drawMa(Canvas canvas, Size size) {}
}
