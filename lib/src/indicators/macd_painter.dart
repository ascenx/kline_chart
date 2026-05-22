import 'package:flutter/material.dart';

import '../kline_controller.dart';

class MACDPainter {
  final List<List<double>> dataList;

  MACDPainter(this.dataList);

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
    ..color = Colors.blueGrey.withValues(alpha: 0.3);

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
    bool showInfo = true,
  }) {
    if (dataList.length < 3 || periods.length != 3) return;
    if (dataList[0].isEmpty || dataList[1].isEmpty || dataList[2].isEmpty) {
      return;
    }
    if (lineColors.isEmpty) lineColors = KLineController.shared.indicatorColors;
    Color macdColor = _lineColor(lineColors, 0, Colors.orange);
    Color signalColor = _lineColor(lineColors, 1, Colors.purple);

    double spacing = KLineController.shared.spacing;
    double itemW = KLineController.getItemWidth(size.width);
    double itemExtent = itemW + spacing;
    double valueOffset = maxValue - minValue;
    double contentTop = top + KLineController.shared.indicatorInfoHeight;
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
        slideOffset, valueOffset, maxValue, minValue);
    _drawLine(canvas, drawAreaHeight, contentTop, itemW, itemExtent,
        slideOffset, valueOffset, maxValue, minValue, dataList[0], macdColor);
    _drawLine(canvas, drawAreaHeight, contentTop, itemW, itemExtent,
        slideOffset, valueOffset, maxValue, minValue, dataList[1], signalColor);
    if (showInfo) {
      paintInfo(canvas, size, periods, top,
          lineColors: lineColors, selectedIndex: selectedIndex);
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
  ) {
    double zeroY = _valueToY(
      0.0,
      drawAreaHeight,
      contentTop,
      valueOffset,
      maxValue,
      minValue,
    );
    double barWidth = itemW * 0.7;
    List<double> histogram = dataList[2];

    for (int i = 0; i < histogram.length; ++i) {
      double value = histogram[i];
      if (_isInvalidValue(value)) continue;
      double centerX = i * itemExtent + itemW * 0.5 + slideOffset;
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
      if (height == 0.0) height = 1.0;
      double previousValue = _previousValidValue(histogram, i);
      bool isSolid = isSolidHistogramBar(value, previousValue);
      canvas.drawRect(
        Rect.fromLTWH(centerX - barWidth * 0.5, topY, barWidth, height),
        _histogramPaint(value, isSolid),
      );
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
  ) {
    Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1;

    double? lastX;
    double? lastY;
    for (int i = 0; i < values.length; ++i) {
      if (_isInvalidValue(values[i])) {
        lastX = null;
        lastY = null;
        continue;
      }
      double x = i * itemExtent + itemW * 0.5 + slideOffset;
      double y = _valueToY(
        values[i],
        drawAreaHeight,
        contentTop,
        valueOffset,
        maxValue,
        minValue,
      );
      if (lastX != null && lastY != null) {
        canvas.drawLine(Offset(lastX, lastY), Offset(x, y), linePaint);
      }
      lastX = x;
      lastY = y;
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
    if (valueOffset == 0.0) return top + height * 0.5;
    return height * (1 - (value - minValue) / valueOffset) + top;
  }

  void paintInfo(
    Canvas canvas,
    Size size,
    List<int> periods,
    double top, {
    List<Color> lineColors = const [],
    int? selectedIndex,
  }) {
    if (dataList.length < 3 || periods.length != 3) return;
    if (lineColors.isEmpty) lineColors = KLineController.shared.indicatorColors;
    Color macdColor = _lineColor(lineColors, 0, Colors.orange);
    Color signalColor = _lineColor(lineColors, 1, Colors.purple);
    double? histogramValue = infoValue(dataList[2], selectedIndex);
    List<String> infoList = [
      'MACD(${periods[0]},${periods[1]},${periods[2]})',
      'DIF: ${infoValueText(dataList[0], selectedIndex)}',
      'DEA: ${infoValueText(dataList[1], selectedIndex)}',
      'MACD: ${infoValueText(dataList[2], selectedIndex)}',
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

    final painter = TextPainter(textDirection: TextDirection.ltr);
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

  Color _lineColor(List<Color> lineColors, int index, Color fallback) {
    if (index < lineColors.length) return lineColors[index];
    return fallback;
  }

  Paint _histogramPaint(double value, bool isSolid) {
    if (value >= 0) return isSolid ? _positivePaint : _positiveStrokePaint;
    return isSolid ? _negativePaint : _negativeStrokePaint;
  }

  double _previousValidValue(List<double> values, int index) {
    for (int i = index - 1; i >= 0; --i) {
      if (!_isInvalidValue(values[i])) return values[i];
    }
    return 0.0;
  }

  bool _isInvalidValue(double value) => value == -1.0;

  static String infoValueText(List<double> values, int? selectedIndex) {
    double? value = infoValue(values, selectedIndex);
    return value == null ? 'NaN' : value.toStringAsFixed(2);
  }

  static double? infoValue(List<double> values, int? selectedIndex) {
    if (values.isEmpty) return null;

    if (selectedIndex != null) {
      if (selectedIndex < 0 || selectedIndex >= values.length) return null;
      double value = values[selectedIndex];
      return _isInvalidInfoValue(value) ? null : value;
    }

    for (int i = values.length - 1; i >= 0; --i) {
      double value = values[i];
      if (!_isInvalidInfoValue(value)) return value;
    }
    return null;
  }

  static bool _isInvalidInfoValue(double value) => value == -1.0;

  static bool isSolidHistogramBar(double value, double previousValue) {
    if (value >= 0) return value >= previousValue;
    return value <= previousValue;
  }
}
