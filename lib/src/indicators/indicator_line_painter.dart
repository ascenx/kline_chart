import 'package:flutter/material.dart';
import '../kline_controller.dart';
import '../kline_data.dart';

class IndicatorLinePainter {
  static final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 1;
  static final Path _linePath = Path();
  static final TextPainter _infoTextPainter =
      TextPainter(textDirection: TextDirection.ltr);

  static void paint(
      Canvas canvas,
      Size size,
      double drawAreaHeight,
      IndicatorType type,
      List<List<double>> dataList,
      List<int> periods,
      double beginIdx,
      double slideOffset,
      double maxValue,
      double minValue,
      {double top = 0.0,
      List<Color> lineColors = const [],
      double infoTopOffset = 0.0,
      List<KLineData> debugData = const [],
      int? selectedIndex,
      int? leadingItemCount,
      bool showInfo = true,
      KLineController? controller}) {
    if (periods.isEmpty) return;
    final resolvedController = controller ?? KLineController.shared;
    if (lineColors.isEmpty) {
      lineColors = resolvedController.indicatorColors;
    }

    double width = size.width;

    double spacing = resolvedController.spacing;
    double itemW =
        KLineController.getItemWidth(width, controller: resolvedController);

    double valueOffset = maxValue - minValue;
    double indicatorX = -(spacing + itemW * 0.5);
    final linePaint = _linePaint;
    final linePath = _linePath;

    for (int idx = 0; idx < periods.length; ++idx) {
      List<double> values = idx < dataList.length ? dataList[idx] : [];
      int period = periods[idx];
      final effectiveLeadingItemCount =
          leadingItemCount ?? _defaultLeadingItemCountForType(type);

      Color color =
          (idx < lineColors.length) ? lineColors[idx] : const Color(0xff333333);
      linePaint.color = color;

      linePath.reset();
      var hasPoint = false;
      var hasLine = false;
      if (values.isNotEmpty) {
        for (int index = 0; index < values.length; ++index) {
          final dataIndex = beginIdx.ceil() + index - effectiveLeadingItemCount;
          if (dataIndex < period) continue;
          if (type != IndicatorType.obv) {
            if (type == IndicatorType.kdj) {
              int firstPeriod = periods.first;
              if (dataIndex < firstPeriod - 1) continue;
            } else {
              if (dataIndex < period - 1) continue;
            }
          }
          double value = values[index];
          if (_isInvalidLineValue(type, value)) continue;
          double indicatorY = valueOffset == 0.0
              ? drawAreaHeight * 0.5 + top
              : drawAreaHeight * (1 - (value - minValue) / valueOffset) + top;
          if (type.isMain) {
            indicatorY += resolvedController.mainIndicatorInfoMargin;
          }
          indicatorY += resolvedController.indicatorInfoHeight;

          indicatorX = (index - effectiveLeadingItemCount) * (itemW + spacing) +
              itemW * 0.5 +
              slideOffset;

          if (!hasPoint) {
            linePath.moveTo(indicatorX, indicatorY);
            hasPoint = true;
          } else {
            linePath.lineTo(indicatorX, indicatorY);
            hasLine = true;
          }
        }
      }
      if (hasLine) {
        canvas.drawPath(linePath, linePaint);
      }
    }

    // line debug area
    if (resolvedController.isDebug) {
      double originY = top + resolvedController.indicatorInfoHeight;
      if (type.isMain && resolvedController.showMainIndicators.isNotEmpty) {
        originY += resolvedController.mainIndicatorInfoMargin;
      }
      Rect rect = Rect.fromLTWH(0, originY, size.width, drawAreaHeight);
      resolvedController.drawDebugRect(
          canvas, rect, Colors.green.withAlpha(50));
    }

    if (showInfo) {
      paintInfo(canvas, size, type, dataList, periods, top,
          lineColors: lineColors,
          topOffset: infoTopOffset,
          selectedIndex: selectedIndex,
          leadingItemCount: leadingItemCount,
          controller: resolvedController);
    }
  }

  static int _defaultLeadingItemCountForType(IndicatorType type) {
    return type == IndicatorType.ma || type == IndicatorType.maVol ? 1 : 0;
  }

  static bool _isInvalidLineValue(IndicatorType type, double value) {
    if (type == IndicatorType.obv || type == IndicatorType.kdj) {
      return false;
    }
    return value < 0;
  }

  static String infoValueText(
      IndicatorType type, List<double> values, int? selectedIndex,
      {int? leadingItemCount, int? period, KLineController? controller}) {
    double? value = infoValue(type, values, selectedIndex,
        leadingItemCount: leadingItemCount);
    if (value == null) {
      return 'NaN';
    }
    if (type == IndicatorType.maVol) {
      return (controller ?? KLineController.shared).formatVolume(value);
    }
    return (controller ?? KLineController.shared)
        .formatIndicator(value, type, period: period);
  }

  static double? infoValue(
      IndicatorType type, List<double> values, int? selectedIndex,
      {int? leadingItemCount}) {
    if (values.isEmpty) {
      return null;
    }

    if (selectedIndex != null) {
      int valueIndex = selectedIndex +
          (leadingItemCount ?? _defaultLeadingItemCountForType(type));
      if (valueIndex < 0 || valueIndex >= values.length) {
        return null;
      }
      double value = values[valueIndex];
      return _isInvalidInfoValue(type, value) ? null : value;
    }

    for (int i = values.length - 1; i >= 0; --i) {
      double value = values[i];
      if (!_isInvalidInfoValue(type, value)) {
        return value;
      }
    }
    return null;
  }

  static bool _isInvalidInfoValue(IndicatorType type, double value) {
    if (type == IndicatorType.obv || type == IndicatorType.kdj) {
      return false;
    }
    return value < 0;
  }

  static List<String> indicatorInfoList(IndicatorType type,
      List<List<double>> dataList, List<int> periods, int? selectedIndex,
      {int? leadingItemCount, KLineController? controller}) {
    List<String> infoList = [];
    for (int idx = 0; idx < periods.length; ++idx) {
      List<double> values = idx < dataList.length ? dataList[idx] : [];
      int period = periods[idx];
      String valueText = infoValueText(type, values, selectedIndex,
          leadingItemCount: leadingItemCount,
          period: period,
          controller: controller);

      if (type == IndicatorType.kdj) {
        if (periods.length < 3) {
          break;
        }
        if (idx == 0) {
          infoList.add("${type.name}($period, ${periods[1]}, ${periods[2]})");
          infoList.add("K $valueText");
        } else if (idx == 1) {
          infoList.add("D $valueText");
        } else if (idx == 2) {
          infoList.add("J $valueText");
        }
      } else {
        if (type == IndicatorType.obv || type == IndicatorType.sar) {
          infoList.add("${type.name}: $valueText");
        } else {
          infoList.add("${type.name}($period): $valueText");
        }
      }
    }
    return infoList;
  }

  static void paintInfo(Canvas canvas, Size size, IndicatorType type,
      List<List<double>> dataList, List<int> periods, double top,
      {List<Color> lineColors = const [],
      double topOffset = 0.0,
      int? selectedIndex,
      int? leadingItemCount,
      KLineController? controller}) {
    if (periods.isEmpty) return;
    final resolvedController = controller ?? KLineController.shared;
    if (lineColors.isEmpty) {
      lineColors = resolvedController.indicatorColors;
    }
    showIndicatorInfo(
      canvas,
      size,
      type,
      indicatorInfoList(type, dataList, periods, selectedIndex,
          leadingItemCount: leadingItemCount, controller: resolvedController),
      top,
      lineColors: lineColors,
      topOffset: topOffset,
      controller: resolvedController,
    );
  }

  static void showIndicatorInfo(Canvas canvas, Size size, IndicatorType type,
      List<String> infoList, double top,
      {List<Color> lineColors = const [],
      double topOffset = 0.0,
      KLineController? controller}) {
    final resolvedController = controller ?? KLineController.shared;
    final painter = _infoTextPainter;

    double lastWidth = 0.0;
    for (var i = 0; i < infoList.length; ++i) {
      String info = infoList[i];
      Color color = const Color(0xff666666);

      if (type == IndicatorType.kdj) {
        color = i == 0 ? color : lineColors[i - 1];
      } else if (i < lineColors.length) {
        color = lineColors[i];
      }

      painter.text = TextSpan(
          text: info,
          style: TextStyle(
            color: color,
            fontSize: 13.0,
            height: 0.0,
            // backgroundColor: Colors.pink
          ));
      painter.layout(maxWidth: size.width);

      double offsetX = lastWidth + (i == 0 ? 5 : i * 10);
      double originY = top + topOffset;
      // originY = type.isMain ? originY  : originY;
      painter.paint(canvas, Offset(offsetX, originY));
      lastWidth += painter.width;
    }

    if (resolvedController.isDebug) {
      double originY = top + topOffset;
      double rectH = resolvedController.indicatorInfoHeight;
      Rect rect = Rect.fromLTWH(0, originY, size.width, rectH);
      resolvedController.drawDebugRect(canvas, rect, Colors.blue.withAlpha(50));
    }
  }
}
