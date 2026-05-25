import 'dart:math';

import 'package:flutter/material.dart';

import '../kline_controller.dart';

class SARPainter {
  final List<List<double>> dataList;
  final Paint _pointPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  final Path _pointPath = Path();

  SARPainter([this.dataList = const []]);

  void paint(
    Canvas canvas,
    Size size,
    double drawAreaHeight,
    double slideOffset,
    double maxValue,
    double minValue, {
    double top = 0.0,
    Color? pointColor,
    List<Color> lineColors = const [],
    KLineController? controller,
  }) {
    paintData(
      canvas,
      size,
      dataList,
      drawAreaHeight,
      slideOffset,
      maxValue,
      minValue,
      top: top,
      pointColor: pointColor,
      lineColors: lineColors,
      controller: controller,
    );
  }

  void paintData(
    Canvas canvas,
    Size size,
    List<List<double>> dataList,
    double drawAreaHeight,
    double slideOffset,
    double maxValue,
    double minValue, {
    double top = 0.0,
    Color? pointColor,
    List<Color> lineColors = const [],
    KLineController? controller,
  }) {
    if (dataList.isEmpty || dataList.first.isEmpty) {
      return;
    }
    final resolvedController = controller ?? KLineController.shared;

    final values = dataList.first;
    final spacing = resolvedController.spacing;
    final itemW = KLineController.getItemWidth(size.width,
        controller: resolvedController);
    final itemExtent = itemW + spacing;
    final valueOffset = maxValue - minValue;
    final contentTop = top +
        resolvedController.indicatorInfoHeight +
        resolvedController.mainIndicatorInfoMargin;
    final radius = max(1.5, min(4.0, itemW * 0.25));
    final resolvedPointColor = pointColor ??
        (lineColors.isNotEmpty
            ? lineColors.first
            : resolvedController.sarColor);
    _pointPaint.color = resolvedPointColor;
    _pointPath.reset();
    var hasPoint = false;

    for (int i = 0; i < values.length; ++i) {
      final value = values[i];
      if (value < 0) {
        continue;
      }
      final x = i * itemExtent + itemW * 0.5 + slideOffset;
      final y = valueOffset == 0.0
          ? drawAreaHeight * 0.5 + contentTop
          : drawAreaHeight * (1 - (value - minValue) / valueOffset) +
              contentTop;
      _pointPath.addOval(
          Rect.fromLTWH(x - radius, y - radius, radius * 2, radius * 2));
      hasPoint = true;
    }

    if (hasPoint) {
      canvas.drawPath(_pointPath, _pointPaint);
    }
  }
}
