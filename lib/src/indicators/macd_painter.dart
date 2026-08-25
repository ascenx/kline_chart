import 'package:flutter/material.dart';

import '../kline_controller.dart';

class MACDPainter {
  final List<List<double>> dataList;

  MACDPainter([this.dataList = const []]);

  static final TextPainter _infoTextPainter =
      TextPainter(textDirection: TextDirection.ltr);

  final Paint _positivePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.green
    ..isAntiAlias = true;

  final Paint _negativePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red
    ..isAntiAlias = true;

  final Paint _positiveStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Colors.green
    ..isAntiAlias = true;

  final Paint _negativeStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Colors.red
    ..isAntiAlias = true;

  final Paint _zeroLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5
    ..color = Colors.blueGrey.withAlpha(77);
  final Path _positiveHistogramPath = Path();
  final Path _negativeHistogramPath = Path();
  final Path _positiveStrokeHistogramPath = Path();
  final Path _negativeStrokeHistogramPath = Path();
  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 1;
  final Path _linePath = Path();

  void paint(
    Canvas canvas,
    Size size,
    double drawAreaHeight,
    List<int> periods,
    double slideOffset,
    double maxValue,
    double minValue, {
    double top = 0.0,
    List<Color> lineColors = const [],
    int? selectedIndex,
    int leadingItemCount = 0,
    bool showInfo = true,
    KLineController? controller,
  }) {
    paintData(
      canvas,
      size,
      dataList,
      drawAreaHeight,
      periods,
      slideOffset,
      maxValue,
      minValue,
      top: top,
      lineColors: lineColors,
      selectedIndex: selectedIndex,
      leadingItemCount: leadingItemCount,
      showInfo: showInfo,
      controller: controller,
    );
  }

  void paintData(
    Canvas canvas,
    Size size,
    List<List<double>> dataList,
    double drawAreaHeight,
    List<int> periods,
    double slideOffset,
    double maxValue,
    double minValue, {
    double top = 0.0,
    List<Color> lineColors = const [],
    int? selectedIndex,
    int leadingItemCount = 0,
    bool showInfo = true,
    KLineController? controller,
  }) {
    if (dataList.length < 3 || periods.length != 3) return;
    if (dataList[0].isEmpty || dataList[1].isEmpty || dataList[2].isEmpty) {
      return;
    }
    final resolvedController = controller ?? KLineController.shared;
    if (lineColors.isEmpty) {
      lineColors = resolvedController.indicatorColors;
    }
    Color macdColor = _lineColor(lineColors, 0, Colors.orange);
    Color signalColor = _lineColor(lineColors, 1, Colors.purple);

    double spacing = resolvedController.spacing;
    double itemW = KLineController.getItemWidth(size.width,
        controller: resolvedController);
    double itemExtent = itemW + spacing;
    double valueOffset = maxValue - minValue;
    double contentTop = top + resolvedController.indicatorInfoHeight;
    double zeroY = _valueToY(
      0.0,
      drawAreaHeight,
      contentTop,
      valueOffset,
      maxValue,
      minValue,
    );

    canvas.drawLine(
        Offset(0, zeroY), Offset(size.width, zeroY), _zeroLinePaint);
    _drawHistogram(canvas, drawAreaHeight, contentTop, itemW, itemExtent,
        slideOffset, valueOffset, maxValue, minValue, dataList[2],
        leadingItemCount: leadingItemCount);
    _drawLine(canvas, drawAreaHeight, contentTop, itemW, itemExtent,
        slideOffset, valueOffset, maxValue, minValue, dataList[0], macdColor,
        leadingItemCount: leadingItemCount);
    _drawLine(canvas, drawAreaHeight, contentTop, itemW, itemExtent,
        slideOffset, valueOffset, maxValue, minValue, dataList[1], signalColor,
        leadingItemCount: leadingItemCount);
    if (showInfo) {
      paintInfoForData(canvas, size, dataList, periods, top,
          controller: resolvedController,
          lineColors: lineColors,
          selectedIndex: selectedIndex);
    }
  }

  void _drawHistogram(
      Canvas canvas,
      double drawAreaHeight,
      double contentTop,
      double itemW,
      double itemExtent,
      double slideOffset,
      double valueOffset,
      double maxValue,
      double minValue,
      List<double> histogram,
      {int leadingItemCount = 0}) {
    double zeroY = _valueToY(
      0.0,
      drawAreaHeight,
      contentTop,
      valueOffset,
      maxValue,
      minValue,
    );
    double barWidth = itemW * 0.7;
    double previousValue = 0.0;
    _positiveHistogramPath.reset();
    _negativeHistogramPath.reset();
    _positiveStrokeHistogramPath.reset();
    _negativeStrokeHistogramPath.reset();
    var hasPositiveHistogram = false;
    var hasNegativeHistogram = false;
    var hasPositiveStrokeHistogram = false;
    var hasNegativeStrokeHistogram = false;

    for (int i = 0; i < histogram.length; ++i) {
      double value = histogram[i];
      if (_isInvalidValue(value)) continue;
      double centerX =
          (i - leadingItemCount) * itemExtent + itemW * 0.5 + slideOffset;
      double valueY = _valueToY(
        value,
        drawAreaHeight,
        contentTop,
        valueOffset,
        maxValue,
        minValue,
      );
      double topY = value >= 0 ? valueY : zeroY;
      double height = (zeroY - valueY).abs();
      if (height == 0.0) {
        height = 1.0;
      }
      bool isSolid = isSolidHistogramBar(value, previousValue);
      final rect =
          Rect.fromLTWH(centerX - barWidth * 0.5, topY, barWidth, height);
      if (value >= 0) {
        if (isSolid) {
          _positiveHistogramPath.addRect(rect);
          hasPositiveHistogram = true;
        } else {
          _positiveStrokeHistogramPath.addRect(rect);
          hasPositiveStrokeHistogram = true;
        }
      } else if (isSolid) {
        _negativeHistogramPath.addRect(rect);
        hasNegativeHistogram = true;
      } else {
        _negativeStrokeHistogramPath.addRect(rect);
        hasNegativeStrokeHistogram = true;
      }
      previousValue = value;
    }
    if (hasPositiveHistogram) {
      canvas.drawPath(_positiveHistogramPath, _positivePaint);
    }
    if (hasPositiveStrokeHistogram) {
      canvas.drawPath(_positiveStrokeHistogramPath, _positiveStrokePaint);
    }
    if (hasNegativeHistogram) {
      canvas.drawPath(_negativeHistogramPath, _negativePaint);
    }
    if (hasNegativeStrokeHistogram) {
      canvas.drawPath(_negativeStrokeHistogramPath, _negativeStrokePaint);
    }
  }

  void _drawLine(
      Canvas canvas,
      double drawAreaHeight,
      double contentTop,
      double itemW,
      double itemExtent,
      double slideOffset,
      double valueOffset,
      double maxValue,
      double minValue,
      List<double> values,
      Color color,
      {int leadingItemCount = 0}) {
    _linePaint.color = color;
    _linePath.reset();

    var hasPoint = false;
    var hasLine = false;
    for (int i = 0; i < values.length; ++i) {
      if (_isInvalidValue(values[i])) {
        hasPoint = false;
        continue;
      }
      double x =
          (i - leadingItemCount) * itemExtent + itemW * 0.5 + slideOffset;
      double y = _valueToY(
        values[i],
        drawAreaHeight,
        contentTop,
        valueOffset,
        maxValue,
        minValue,
      );
      if (!hasPoint) {
        _linePath.moveTo(x, y);
        hasPoint = true;
      } else {
        _linePath.lineTo(x, y);
        hasLine = true;
      }
    }
    if (hasLine) {
      canvas.drawPath(_linePath, _linePaint);
    }
  }

  double _valueToY(
    double value,
    double height,
    double top,
    double valueOffset,
    double maxValue,
    double minValue,
  ) {
    if (valueOffset == 0.0) {
      return top + height * 0.5;
    }
    return height * (1 - (value - minValue) / valueOffset) + top;
  }

  void paintInfo(
    Canvas canvas,
    Size size,
    List<int> periods,
    double top, {
    List<Color> lineColors = const [],
    int? selectedIndex,
    KLineController? controller,
  }) {
    paintInfoForData(
      canvas,
      size,
      dataList,
      periods,
      top,
      controller: controller,
      lineColors: lineColors,
      selectedIndex: selectedIndex,
    );
  }

  static void paintInfoForData(
    Canvas canvas,
    Size size,
    List<List<double>> dataList,
    List<int> periods,
    double top, {
    List<Color> lineColors = const [],
    int? selectedIndex,
    KLineController? controller,
  }) {
    if (dataList.length < 3 || periods.length != 3) return;
    final resolvedController = controller ?? KLineController.shared;
    if (lineColors.isEmpty) {
      lineColors = resolvedController.indicatorColors;
    }
    Color macdColor = _lineColor(lineColors, 0, Colors.orange);
    Color signalColor = _lineColor(lineColors, 1, Colors.purple);
    double? histogramValue = infoValue(dataList[2], selectedIndex);
    List<String> infoList = [
      'MACD(${periods[0]},${periods[1]},${periods[2]})',
      'DIF: ${infoValueText(dataList[0], selectedIndex, period: periods[0], controller: resolvedController)}',
      'DEA: ${infoValueText(dataList[1], selectedIndex, period: periods[2], controller: resolvedController)}',
      'MACD: ${infoValueText(dataList[2], selectedIndex, controller: resolvedController)}',
    ];
    List<Color> colors = [
      const Color(0xff666666),
      macdColor,
      signalColor,
      histogramValue == null
          ? const Color(0xff666666)
          : histogramValue >= 0
              ? Colors.green
              : Colors.red,
    ];

    final painter = _infoTextPainter;
    double lastWidth = 0.0;
    for (int i = 0; i < infoList.length; ++i) {
      painter.text = TextSpan(
        text: infoList[i],
        style: TextStyle(
          color: colors[i],
          fontSize: 13.0,
          height: 0.0,
        ),
      );
      painter.layout(maxWidth: size.width);
      double offsetX = lastWidth + (i == 0 ? 5 : i * 10);
      painter.paint(canvas, Offset(offsetX, top));
      lastWidth += painter.width;
    }
  }

  static Color _lineColor(List<Color> lineColors, int index, Color fallback) {
    if (index < lineColors.length) {
      return lineColors[index];
    }
    return fallback;
  }

  bool _isInvalidValue(double value) => value == -1.0;

  static String infoValueText(List<double> values, int? selectedIndex,
      {int? period, KLineController? controller}) {
    double? value = infoValue(values, selectedIndex);
    return value == null
        ? 'NaN'
        : (controller ?? KLineController.shared)
            .formatIndicator(value, IndicatorType.macd, period: period);
  }

  static double? infoValue(List<double> values, int? selectedIndex) {
    if (values.isEmpty) {
      return null;
    }

    if (selectedIndex != null) {
      if (selectedIndex < 0 || selectedIndex >= values.length) {
        return null;
      }
      double value = values[selectedIndex];
      return _isInvalidInfoValue(value) ? null : value;
    }

    for (int i = values.length - 1; i >= 0; --i) {
      double value = values[i];
      if (!_isInvalidInfoValue(value)) {
        return value;
      }
    }
    return null;
  }

  static bool _isInvalidInfoValue(double value) => value == -1.0;

  static bool isSolidHistogramBar(double value, double previousValue) {
    if (value >= 0) {
      return value >= previousValue;
    }
    return value <= previousValue;
  }
}
