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
      bool showInfo = true}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) {
      lineColors = KLineController.shared.indicatorColors;
    }

    double width = size.width;

    final controller = KLineController.shared;
    double spacing = controller.spacing;
    double itemW = KLineController.getItemWidth(width);

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
            indicatorY += controller.mainIndicatorInfoMargin;
          }
          indicatorY += controller.indicatorInfoHeight;

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
    if (controller.isDebug) {
      double originY = top + controller.indicatorInfoHeight;
      if (type.isMain && controller.showMainIndicators.isNotEmpty) {
        originY += controller.mainIndicatorInfoMargin;
      }
      Rect rect = Rect.fromLTWH(0, originY, size.width, drawAreaHeight);
      controller.drawDebugRect(canvas, rect, Colors.green.withAlpha(50));
    }

    if (showInfo) {
      paintInfo(canvas, size, type, dataList, periods, top,
          lineColors: lineColors,
          topOffset: infoTopOffset,
          selectedIndex: selectedIndex,
          leadingItemCount: leadingItemCount);
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
      {int? leadingItemCount}) {
    double? value = infoValue(type, values, selectedIndex,
        leadingItemCount: leadingItemCount);
    return value == null ? 'NaN' : value.toStringAsFixed(2);
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
      {int? leadingItemCount}) {
    List<String> infoList = [];
    for (int idx = 0; idx < periods.length; ++idx) {
      List<double> values = idx < dataList.length ? dataList[idx] : [];
      int period = periods[idx];
      String valueText = infoValueText(type, values, selectedIndex,
          leadingItemCount: leadingItemCount);

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
      int? leadingItemCount}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) {
      lineColors = KLineController.shared.indicatorColors;
    }
    showIndicatorInfo(
      canvas,
      size,
      type,
      indicatorInfoList(type, dataList, periods, selectedIndex,
          leadingItemCount: leadingItemCount),
      top,
      lineColors: lineColors,
      topOffset: topOffset,
    );
  }

  static void showIndicatorInfo(Canvas canvas, Size size, IndicatorType type,
      List<String> infoList, double top,
      {List<Color> lineColors = const [], double topOffset = 0.0}) {
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

    if (KLineController.shared.isDebug) {
      double originY = top + topOffset;
      double rectH = KLineController.shared.indicatorInfoHeight;
      Rect rect = Rect.fromLTWH(0, originY, size.width, rectH);
      KLineController.shared
          .drawDebugRect(canvas, rect, Colors.blue.withAlpha(50));
    }
  }
}
