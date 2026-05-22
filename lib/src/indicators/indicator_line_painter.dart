import 'package:flutter/material.dart';
import '../kline_controller.dart';
import '../kline_data.dart';

class IndicatorLinePainter {
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
      bool showInfo = true}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) lineColors = KLineController.shared.indicatorColors;

    double width = size.width;

    double spacing = KLineController.shared.spacing;
    double itemW = KLineController.getItemWidth(width);
    double itemCount = KLineController.shared.itemCount;

    double valueOffset = maxValue - minValue;
    double indicatorX = -(spacing + itemW * 0.5);

    for (int idx = 0; idx < periods.length; ++idx) {
      List<double> values = idx < dataList.length ? dataList[idx] : [];
      int period = periods[idx];

      Color color =
          (idx < lineColors.length) ? lineColors[idx] : const Color(0xff333333);
      var linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..isAntiAlias = true
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1;

      double lastY = 0.0;
      double lastX = 0.0;
      if (values.isNotEmpty) {
        for (var i = beginIdx - 1; i < beginIdx + itemCount + 1; ++i) {
          if ((i - beginIdx).ceil() >= values.length) {
            break;
          }
          if (i.ceil() < period) continue;
          if (type != IndicatorType.obv) {
            if (type == IndicatorType.kdj) {
              int firstPeriod = periods.first;
              if (i.ceil() < firstPeriod - 1) continue;
            } else {
              if (i.ceil() < period - 1) continue;
            }
          }
          int index = (i - beginIdx).ceil();
          index = index < 0 ? 0 : index;
          double value = values[index];
          if (_isInvalidLineValue(type, value)) continue;
          double indicatorY = valueOffset == 0.0
              ? drawAreaHeight * 0.5 + top
              : drawAreaHeight * (1 - (value - minValue) / valueOffset) + top;
          if (type.isMain) {
            indicatorY += KLineController.shared.mainIndicatorInfoMargin;
          }
          indicatorY += KLineController.shared.indicatorInfoHeight;

          indicatorX =
              index * (itemW + spacing) - itemW * 0.5 - spacing + slideOffset;

          if (lastX == 0.0 && lastY == 0.0) {
            lastX = indicatorX;
            lastY = indicatorY;
          }

          canvas.drawLine(
              Offset(lastX, lastY), Offset(indicatorX, indicatorY), linePaint);
          lastY = indicatorY;
          lastX = indicatorX;
        }
      }
    }

    // line debug area
    if (KLineController.shared.isDebug) {
      double originY = top + KLineController.shared.indicatorInfoHeight;
      if (type.isMain && KLineController.shared.showMainIndicators.isNotEmpty) {
        originY += KLineController.shared.mainIndicatorInfoMargin;
      }
      Rect rect = Rect.fromLTWH(0, originY, size.width, drawAreaHeight);
      KLineController.shared
          .drawDebugRect(canvas, rect, Colors.green.withAlpha(50));
    }

    if (showInfo) {
      paintInfo(canvas, size, type, dataList, periods, top,
          lineColors: lineColors,
          topOffset: infoTopOffset,
          selectedIndex: selectedIndex);
    }
  }

  static bool _isInvalidLineValue(IndicatorType type, double value) {
    if (type == IndicatorType.obv || type == IndicatorType.kdj) return false;
    return value < 0;
  }

  static String infoValueText(
      IndicatorType type, List<double> values, int? selectedIndex) {
    double? value = infoValue(type, values, selectedIndex);
    return value == null ? 'NaN' : value.toStringAsFixed(2);
  }

  static double? infoValue(
      IndicatorType type, List<double> values, int? selectedIndex) {
    if (values.isEmpty) return null;

    if (selectedIndex != null) {
      int valueIndex = selectedIndex;
      if (type == IndicatorType.ma || type == IndicatorType.maVol) {
        valueIndex += 1;
      }
      if (valueIndex < 0 || valueIndex >= values.length) return null;
      double value = values[valueIndex];
      return _isInvalidInfoValue(type, value) ? null : value;
    }

    for (int i = values.length - 1; i >= 0; --i) {
      double value = values[i];
      if (!_isInvalidInfoValue(type, value)) return value;
    }
    return null;
  }

  static bool _isInvalidInfoValue(IndicatorType type, double value) {
    if (type == IndicatorType.obv || type == IndicatorType.kdj) return false;
    return value < 0;
  }

  static List<String> indicatorInfoList(IndicatorType type,
      List<List<double>> dataList, List<int> periods, int? selectedIndex) {
    List<String> infoList = [];
    for (int idx = 0; idx < periods.length; ++idx) {
      List<double> values = idx < dataList.length ? dataList[idx] : [];
      int period = periods[idx];
      String valueText = infoValueText(type, values, selectedIndex);

      if (type == IndicatorType.kdj) {
        if (periods.length < 3) break;
        if (idx == 0) {
          infoList.add("${type.name}($period, ${periods[1]}, ${periods[2]})");
          infoList.add("K $valueText");
        } else if (idx == 1) {
          infoList.add("D $valueText");
        } else if (idx == 2) {
          infoList.add("J $valueText");
        }
      } else {
        if (type == IndicatorType.obv) {
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
      int? selectedIndex}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) lineColors = KLineController.shared.indicatorColors;
    showIndicatorInfo(
      canvas,
      size,
      type,
      indicatorInfoList(type, dataList, periods, selectedIndex),
      top,
      lineColors: lineColors,
      topOffset: topOffset,
    );
  }

  static void showIndicatorInfo(Canvas canvas, Size size, IndicatorType type,
      List<String> infoList, double top,
      {List<Color> lineColors = const [], double topOffset = 0.0}) {
    final painter = TextPainter(textDirection: TextDirection.ltr);

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
