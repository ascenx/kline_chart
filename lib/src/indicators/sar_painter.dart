import 'dart:math';

import 'package:flutter/material.dart';

import '../kline_controller.dart';

class SARPainter {
  final List<List<double>> dataList;

  SARPainter(this.dataList);

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
  }) {
    if (dataList.isEmpty || dataList.first.isEmpty) {
      return;
    }

    final values = dataList.first;
    final spacing = KLineController.shared.spacing;
    final itemW = KLineController.getItemWidth(size.width);
    final itemExtent = itemW + spacing;
    final valueOffset = maxValue - minValue;
    final contentTop = top +
        KLineController.shared.indicatorInfoHeight +
        KLineController.shared.mainIndicatorInfoMargin;
    final radius = max(1.5, min(4.0, itemW * 0.25));
    final resolvedPointColor = pointColor ??
        (lineColors.isNotEmpty
            ? lineColors.first
            : KLineController.shared.sarColor);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = resolvedPointColor
      ..isAntiAlias = true;

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
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
}
