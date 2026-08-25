import 'dart:math';

import 'package:flutter/material.dart';

import './kline_chart_style.dart';
import './kline_controller.dart';
import './kline_data.dart';
import './kline_overlay.dart';

class KLineOverlayPainter {
  static final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );

  static void paint({
    required Canvas canvas,
    required Size size,
    required List<KLineData> data,
    required List<KLineOverlay> overlays,
    required double beginIndex,
    required double itemWidth,
    required double spacing,
    required double highest,
    required double lowest,
    required double top,
    required double height,
    required KLineOverlayStyle style,
    required String Function(double value) formatPrice,
  }) {
    if (data.isEmpty || overlays.isEmpty || height <= 0) return;

    final mainRect = Rect.fromLTWH(0, top, size.width, height);
    Map<int, int>? indexByTime;

    int? dataIndexForTime(int time) {
      if (indexByTime == null) {
        indexByTime = <int, int>{};
        for (var i = 0; i < data.length; i++) {
          indexByTime!.putIfAbsent(data[i].time, () => i);
        }
      }
      return indexByTime![time];
    }

    canvas.save();
    canvas.clipRect(mainRect);

    for (final overlay in overlays) {
      if (overlay is KLinePriceZone) {
        _drawPriceZone(canvas, size, overlay, highest, lowest, top, height,
            style, mainRect);
      }
    }
    for (final overlay in overlays) {
      if (overlay is KLinePriceLine) {
        _drawPriceLine(canvas, size, overlay, highest, lowest, top, height,
            style, mainRect, formatPrice);
      }
    }
    for (final overlay in overlays) {
      if (overlay is KLineVerticalLine) {
        final dataIndex = dataIndexForTime(overlay.time);
        if (dataIndex == null) continue;
        final x = KLineController.itemCenterXForDataIndex(
          dataIndex: dataIndex,
          beginIndex: beginIndex,
          itemWidth: itemWidth,
          spacing: spacing,
        );
        _drawVerticalLine(canvas, size, overlay, x, style, mainRect);
      }
    }
    for (final overlay in overlays) {
      if (overlay is KLineMarker) {
        final dataIndex = dataIndexForTime(overlay.time);
        if (dataIndex == null) continue;
        final x = KLineController.itemCenterXForDataIndex(
          dataIndex: dataIndex,
          beginIndex: beginIndex,
          itemWidth: itemWidth,
          spacing: spacing,
        );
        final y = _priceToY(overlay.price, highest, lowest, top, height);
        _drawMarker(canvas, overlay, Offset(x, y), style, mainRect);
      }
    }

    canvas.restore();
  }

  static void _drawPriceLine(
    Canvas canvas,
    Size size,
    KLinePriceLine overlay,
    double highest,
    double lowest,
    double top,
    double height,
    KLineOverlayStyle style,
    Rect mainRect,
    String Function(double value) formatPrice,
  ) {
    final y = _priceToY(overlay.price, highest, lowest, top, height);
    if (!y.isFinite) return;

    final color = overlay.color ?? style.priceLineColor;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = overlay.strokeWidth ?? style.priceLineStrokeWidth
      ..color = color
      ..isAntiAlias = false;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final label = overlay.label ?? formatPrice(overlay.price);
    if (label.isEmpty) return;

    _textPainter.text = TextSpan(
      text: label,
      style: style.priceLineTextStyle,
    );
    _textPainter.layout(maxWidth: size.width);

    final padding = style.priceLineLabelPadding;
    final labelWidth = _textPainter.width + padding.horizontal;
    final labelHeight = _textPainter.height + padding.vertical;
    final labelLeft = max(0.0, size.width - labelWidth);
    final labelTop = _clampDouble(
      y - labelHeight * 0.5,
      mainRect.top,
      mainRect.bottom - labelHeight,
    );
    final labelRect = Rect.fromLTWH(
      labelLeft,
      labelTop,
      labelWidth,
      labelHeight,
    );
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = overlay.color ?? style.priceLineLabelBackgroundColor
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelRect,
        Radius.circular(style.priceLineLabelBorderRadius),
      ),
      backgroundPaint,
    );
    _textPainter.paint(
      canvas,
      Offset(labelRect.left + padding.left, labelRect.top + padding.top),
    );
  }

  static void _drawPriceZone(
    Canvas canvas,
    Size size,
    KLinePriceZone overlay,
    double highest,
    double lowest,
    double top,
    double height,
    KLineOverlayStyle style,
    Rect mainRect,
  ) {
    final fromY = _priceToY(overlay.fromPrice, highest, lowest, top, height);
    final toY = _priceToY(overlay.toPrice, highest, lowest, top, height);
    if (!fromY.isFinite || !toY.isFinite) return;

    final zoneTop = min(fromY, toY);
    final zoneBottom = max(fromY, toY);
    final opacity = _clampDouble(overlay.opacity ?? style.zoneOpacity, 0, 1);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color =
          (overlay.color ?? style.zoneColor).withAlpha((opacity * 255).round())
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTRB(0, zoneTop, size.width, zoneBottom), paint);

    final label = overlay.label;
    if (label == null || label.isEmpty) return;

    _textPainter.text = TextSpan(text: label, style: style.zoneTextStyle);
    _textPainter.layout(maxWidth: size.width);
    final labelX = max(0.0, size.width - _textPainter.width - 4);
    final labelY = _clampDouble(
      (zoneTop + zoneBottom - _textPainter.height) * 0.5,
      mainRect.top,
      mainRect.bottom - _textPainter.height,
    );
    _textPainter.paint(canvas, Offset(labelX, labelY));
  }

  static void _drawVerticalLine(
    Canvas canvas,
    Size size,
    KLineVerticalLine overlay,
    double x,
    KLineOverlayStyle style,
    Rect mainRect,
  ) {
    final strokeWidth = overlay.strokeWidth ?? style.verticalLineStrokeWidth;
    if (x < -strokeWidth || x > size.width + strokeWidth) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = overlay.color ?? style.verticalLineColor
      ..isAntiAlias = false;
    canvas.drawLine(
      Offset(x, mainRect.top),
      Offset(x, mainRect.bottom),
      paint,
    );

    final label = overlay.label;
    if (label == null || label.isEmpty) return;

    _textPainter.text =
        TextSpan(text: label, style: style.verticalLineTextStyle);
    _textPainter.layout(maxWidth: size.width);
    final labelX = _clampDouble(x + 4, 0, size.width - _textPainter.width);
    _textPainter.paint(canvas, Offset(labelX, mainRect.top + 2));
  }

  static void _drawMarker(
    Canvas canvas,
    KLineMarker overlay,
    Offset center,
    KLineOverlayStyle style,
    Rect mainRect,
  ) {
    final radius = overlay.radius ?? style.markerRadius;
    final color = overlay.color ?? _markerColorForType(overlay.type, style);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..isAntiAlias = false;
    final label = overlay.label ?? _defaultMarkerLabel(overlay.type);
    if (label.isEmpty) {
      if (center.dx < mainRect.left - radius ||
          center.dx > mainRect.right + radius ||
          center.dy < mainRect.top - radius ||
          center.dy > mainRect.bottom + radius) {
        return;
      }
      final visibleCenter = Offset(
        _clampDouble(
            center.dx, mainRect.left + radius, mainRect.right - radius),
        _clampDouble(
            center.dy, mainRect.top + radius, mainRect.bottom - radius),
      );
      canvas.drawCircle(visibleCenter, radius, paint);
      return;
    }

    _textPainter.text = TextSpan(
      text: label,
      style: style.markerTextStyle.copyWith(color: style.markerTextColor),
    );
    _textPainter.layout();
    final markerWidth = max(radius * 2, _textPainter.width + 8);
    final markerHeight = max(radius * 2, _textPainter.height + 4);
    final halfWidth = markerWidth * 0.5;
    final halfHeight = markerHeight * 0.5;
    if (center.dx < mainRect.left - halfWidth ||
        center.dx > mainRect.right + halfWidth ||
        center.dy < mainRect.top - halfHeight ||
        center.dy > mainRect.bottom + halfHeight) {
      return;
    }
    final visibleCenter = Offset(
      _clampDouble(
        center.dx,
        mainRect.left + halfWidth,
        mainRect.right - halfWidth,
      ),
      _clampDouble(
        center.dy,
        mainRect.top + halfHeight,
        mainRect.bottom - halfHeight,
      ),
    );
    final markerRect = Rect.fromCenter(
      center: visibleCenter,
      width: markerWidth,
      height: markerHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(markerRect, const Radius.circular(3)),
      paint,
    );
    _textPainter.paint(
      canvas,
      Offset(
        markerRect.left + (markerRect.width - _textPainter.width) * 0.5,
        markerRect.top + (markerRect.height - _textPainter.height) * 0.5,
      ),
    );
  }

  static Color _markerColorForType(
    KLineMarkerType type,
    KLineOverlayStyle style,
  ) {
    switch (type) {
      case KLineMarkerType.buy:
        return style.buyMarkerColor;
      case KLineMarkerType.sell:
        return style.sellMarkerColor;
      case KLineMarkerType.custom:
        return style.customMarkerColor;
    }
  }

  static String _defaultMarkerLabel(KLineMarkerType type) {
    switch (type) {
      case KLineMarkerType.buy:
        return 'B';
      case KLineMarkerType.sell:
        return 'S';
      case KLineMarkerType.custom:
        return '';
    }
  }

  static double _priceToY(
    double price,
    double highest,
    double lowest,
    double top,
    double height,
  ) {
    final range = highest - lowest;
    if (range == 0.0) {
      return top + height * 0.5;
    }
    return height * (1 - (price - lowest) / range) + top;
  }

  static double _clampDouble(double value, double minValue, double maxValue) {
    if (maxValue < minValue) return minValue;
    return value.clamp(minValue, maxValue).toDouble();
  }
}
