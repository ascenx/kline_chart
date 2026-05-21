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
      List<KLineData> debugData = const []}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) lineColors = KLineController.shared.indicatorColors;

    double width = size.width;

    double spacing = KLineController.shared.spacing;
    double itemW = KLineController.getItemWidth(width);
    double itemCount = KLineController.shared.itemCount;

    double valueOffset = maxValue - minValue;
    double indicatorX = -(spacing + itemW * 0.5);

    List<String> maInfoList = [];
    for (int idx = 0; idx < periods.length; ++idx) {
      if (dataList.isEmpty) return;
      if (dataList.length == idx) {
        continue;
      }
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
      double lastValue = 0.0;

      for (var i = beginIdx - 1; i < beginIdx + itemCount + 1; ++i) {
        if (dataList[idx].isEmpty) {
          return;
        }

        if ((i - beginIdx).ceil() >= dataList[idx].length) {
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
        double value = dataList[idx][index];
        if (_isInvalidLineValue(type, value)) continue;
        lastValue = value;
        double indicatorY = valueOffset == 0.0
            ? drawAreaHeight * 0.5 + top
            : drawAreaHeight * (1 - (value - minValue) / valueOffset) + top;
        if (type.isMain)
          indicatorY += KLineController.shared.mainIndicatorInfoMargin;
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

      if (type == IndicatorType.kdj) {
        if (idx == 0) {
          maInfoList.add("${type.name}($period, ${periods[1]}, ${periods[2]})");
          maInfoList.add("K ${lastValue.toStringAsFixed(2)}");
        } else if (idx == 1) {
          maInfoList.add("D ${lastValue.toStringAsFixed(2)}");
        } else if (idx == 2) {
          maInfoList.add("J ${lastValue.toStringAsFixed(2)}");
        }
      } else {
        if (type == IndicatorType.obv) {
          maInfoList.add("${type.name}: ${lastValue.toStringAsFixed(2)}");
        } else {
          maInfoList
              .add("${type.name}($period): ${lastValue.toStringAsFixed(2)}");
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

    showIndicatorInfo(canvas, size, type, maInfoList, top,
        lineColors: lineColors, topOffset: infoTopOffset);
  }

  static bool _isInvalidLineValue(IndicatorType type, double value) {
    if (type == IndicatorType.obv || type == IndicatorType.kdj) return false;
    return value < 0;
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
