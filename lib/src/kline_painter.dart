import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import './indicators/indicator_data_handler.dart';
import './indicators/indicator_result.dart';
import './kline_controller.dart';
import './indicators/indicator_line_painter.dart';
import './indicators/vol_painter.dart';
import './kline_data.dart';

class KLinePainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;

  KLinePainter(this.klineData, this.beginIdx);

  final _riseRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.green
    ..isAntiAlias = true;
  final _riseLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

  final _fallRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red
    ..isAntiAlias = true;
  final _fallLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.red
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

  final _minMaxLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xff999999)
    ..isAntiAlias = true
    ..strokeWidth = 1.0;

  final _rulerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.blueGrey.withValues(alpha: 0.2);

  final _currentPricePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.black54
    ..isAntiAlias = true;

  final _currentPriceBgPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white
    ..isAntiAlias = true;

  final _timeLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.blue
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true
    ..strokeWidth = 1.0;

  final _timeLineAreaPaint = Paint()
        // ..style = PaintingStyle.fill
        // ..color = Colors.lightBlueAccent.withOpacity(0.3)
        ..isAntiAlias = true
        ..strokeWidth = 1.0
      // ..shader = ui.Gradient.linear(
      //   const Offset(0, 0),
      //   const Offset(0, 1),
      //   <Color>[
      //     Colors.lightBlueAccent.withOpacity(0.0),
      //     Colors.redAccent.withOpacity(1.0),
      //   ],
      // )
      ;

  final _timeLinePath = Path();

  // draw kline

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    // debugPrint('debug: kline painter repaint');

    bool isTimeChart = KLineController.shared.showTimeChart;

    List showSubIndicators = KLineController.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double spacing = KLineController.shared.spacing;
    double itemW = KLineController.getItemWidth(size.width);
    double itemCount = KLineController.shared.itemCount;

    double mainTopMargin = KLineController.shared.klineMargin.top;
    double mainInfoMargin = KLineController.shared.mainIndicatorInfoMargin;

    double indicatorInfoHeight = KLineController.shared.indicatorInfoHeight;
    double indicatorSpacing = KLineController.shared.indicatorSpacing;

    // main draw area height
    double mainHeight = size.height -
        (KLineController.shared.subIndicatorHeight + indicatorSpacing) * subIndicatorCount -
        KLineController.shared.klineMargin.bottom;

    _timeLineAreaPaint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, mainHeight),
      <Color>[
        Colors.lightBlueAccent,
        Colors.lightBlueAccent.withValues(alpha: 0.0),
      ],
    );

    if (KLineController.shared.showMainIndicators.isNotEmpty) {
      mainTopMargin += (indicatorInfoHeight + mainInfoMargin);
    }
    mainHeight -= mainTopMargin;

    // if (KLineConfig.shared.isDebug) {
    //   KLineConfig.shared.drawDebugRect(canvas, Rect.fromLTWH(0, mainTopMargin, size.width, mainHeight), Colors.red.withOpacity(0.4));
    // }

    // calculating the highest lowest point
    if (beginIdx >= klineData.length) {
      // debugPrint('debug: beginIdx($beginIdx) >= klineData.length(${klineData.length}) return');
      return;
    }
    KLineData beginData = klineData[beginIdx.ceil()];
    double highest = beginData.high;
    double lowest = beginData.low;

    double maxVolume = beginData.volume;

    double highestIdx = beginIdx, lowestIdx = beginIdx;

    for (var i = beginIdx - 1; i < beginIdx + itemCount; ++i) {
      if (i >= klineData.length) continue;
      int idx = i.ceil();
      idx = idx < 0 ? 0 : idx;
      final data = klineData[idx];
      double high = data.high;
      double low = data.low;
      if (high > highest) {
        highest = high;
        highestIdx = i;
      }
      if (low < lowest) {
        lowest = low;
        lowestIdx = i;
      }
      double volume = data.volume;
      if (volume > maxVolume) maxVolume = volume;
    }

    double mainHighest = highest, mainLowest = lowest;

    List<List<double>> mainIndicatorData = [];
    bool isShowMA = KLineController.shared.showMainIndicators.contains(IndicatorType.ma);
    bool isShowEMA = KLineController.shared.showMainIndicators.contains(IndicatorType.ema);
    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      var res = IndicatorResult.empty;
      if (isShowMA) {
        res = IndicatorDataHandler.ma(klineData, indicatorPeriods, beginIdx);
      } else if (isShowEMA) {
        res = IndicatorDataHandler.ema(klineData, indicatorPeriods, beginIdx);
      }

      mainIndicatorData = res.data;
      double mainIndicatorMax = res.maxValue;
      double mainIndicatorMin = res.minValue;
      if (mainIndicatorMax > highest) highest = mainIndicatorMax;
      if (mainIndicatorMin < lowest && mainIndicatorMin != 0.0) lowest = mainIndicatorMin;
    }

    bool isShowBOLL = KLineController.shared.showMainIndicators.contains(IndicatorType.boll);
    if (isShowBOLL) {
      int bollPeriod = KLineController.shared.bollPeriod;
      int bollBandwidth = KLineController.shared.bollBandwidth;

      var res = IndicatorDataHandler.boll(klineData, bollPeriod, bollBandwidth, beginIdx);
      mainIndicatorData = res.data;
      double bollMax = res.maxValue;
      double bollMin = res.minValue;

      if (bollMax > highest) highest = bollMax;
      if (bollMin < lowest && bollMin != 0.0) lowest = bollMin;
    }

    _drawRulerLine(canvas, mainHeight, size.width, indicatorInfoHeight + KLineController.shared.mainIndicatorInfoMargin,
        highest, lowest, size);

    // KDJ, WR
    Map<IndicatorType, dynamic> subIndicatorData = {};
    Map<IndicatorType, double> subHighest = {}, subLowest = {};
    IndicatorType kdjType = IndicatorType.kdj;
    if (showSubIndicators.contains(kdjType)) {
      var res = IndicatorDataHandler.kdj(klineData, KLineController.shared.kdjPeriods, beginIdx);
      subIndicatorData[kdjType] = res.data;
      subHighest[kdjType] = res.maxValue;
      subLowest[kdjType] = res.minValue;
    }
    IndicatorType wrType = IndicatorType.wr;
    if (showSubIndicators.contains(wrType)) {
      var res = IndicatorDataHandler.wr(klineData, KLineController.shared.wrPeriods, beginIdx);
      subIndicatorData[wrType] = res.data;
      subHighest[wrType] = res.maxValue;
      subLowest[wrType] = res.minValue;
    }

    IndicatorType obvType = IndicatorType.obv;
    if (showSubIndicators.contains(obvType)) {
      var res = IndicatorDataHandler.obv(klineData, beginIdx);
      subIndicatorData[obvType] = res.data;
      subHighest[obvType] = res.maxValue;
      subLowest[obvType] = res.minValue;
    }

    // offset between the highest and lowest
    double valueOffset = highest - lowest;

    double rectLeft = -(itemW + spacing);

    double highestX = 0.0, highestY = 0.0, lowestX = 0.0, lowestY = 0.0;

    double indexOffset = beginIdx - beginIdx.ceil();
    double slideOffset = -indexOffset * (itemW + spacing);

    _timeLinePath.reset();

    for (var i = beginIdx - 1; i < beginIdx + itemCount; ++i) {
      if (i >= klineData.length) continue;
      int idx = i.ceil();
      idx = idx < 0 ? 0 : idx;
      KLineData data = klineData[idx];

      double open = data.open;
      double high = data.high;
      double low = data.low;
      double close = data.close;

      double lineX = rectLeft + itemW * 0.5 + slideOffset;

      if (isTimeChart) {
        double lastX = i == beginIdx ? 0.0 : rectLeft + itemW * 0.5 + slideOffset - itemW - spacing;
        double lastY = mainHeight * (1 - (klineData[i.ceil() - 1].close - lowest) / valueOffset) + mainTopMargin;
        double timelineY = mainHeight * (1 - (close - lowest) / valueOffset) + mainTopMargin;
        canvas.drawLine(Offset(lastX, lastY), Offset(lineX, timelineY), _timeLinePaint);

        if (i == beginIdx) {
          _timeLinePath.moveTo(lineX, timelineY);
        } else if (i == beginIdx + itemCount - 1) {
          _timeLinePath.lineTo(lineX, timelineY);
          // _timeLinePath.lineTo(lineX, mainHeight + mainTopMargin);
        } else {
          _timeLinePath.lineTo(lineX, timelineY);
        }
      } else { // draw candle chart
        double lineTop = mainHeight * (1 - (high - lowest) / valueOffset) + mainTopMargin;
        double lineBtm = mainHeight * (1 - (low - lowest) / valueOffset) + mainTopMargin;

        if (i == highestIdx) {
          highestX = lineX;
          highestY = lineTop;
        }
        if (i == lowestIdx) {
          lowestX = lineX;
          lowestY = lineBtm;
        }

        if (close > open) {
          double itemH = (close - open) / valueOffset * mainHeight;
          double rectTop = mainHeight * (1 - (open - lowest) / valueOffset) + mainTopMargin;
          rectTop -= itemH; // rise starts at the top
          canvas.drawRect(Rect.fromLTWH(rectLeft + slideOffset, rectTop, itemW, itemH), _riseRectPaint);
          canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), _riseLinePaint);
        } else {
          double itemH = (open - close) / valueOffset * mainHeight;
          double rectTop = mainHeight * (1 - (open - lowest) / valueOffset) + mainTopMargin;
          canvas.drawRect(Rect.fromLTWH(rectLeft + slideOffset, rectTop, itemW, itemH), _fallRectPaint);
          canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), _fallLinePaint);
        }
      }

      rectLeft += (itemW + spacing);
    }

    if (isTimeChart) {
      _timeLinePath.lineTo(size.width - (itemW - slideOffset) + spacing, mainHeight + mainTopMargin);
      _timeLinePath.lineTo(itemW * 0.5 + slideOffset, mainHeight + mainTopMargin);
      _timeLinePath.close();

      canvas.drawPath(_timeLinePath, _timeLineAreaPaint);
    } else {
      _drawHighestLowestText(canvas, "$mainHighest", Offset(highestX, highestY), size);
      _drawHighestLowestText(canvas, "$mainLowest", Offset(lowestX, lowestY), size);
    }

    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineController.shared.showMainIndicators.first,
          mainIndicatorData, indicatorPeriods, beginIdx, slideOffset, highest, lowest,
          top: KLineController.shared.klineMargin.top, debugData: klineData);
    }

    if (isShowBOLL) {
      // List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      int bollPeriod = KLineController.shared.bollPeriod;
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineController.shared.showMainIndicators.first,
          mainIndicatorData, [bollPeriod, bollPeriod, bollPeriod], beginIdx, slideOffset, highest, lowest,
          top: KLineController.shared.klineMargin.top);
    }

    // draw sub indicator
    double indicatorH = KLineController.shared.subIndicatorHeight;

    // if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.macd)) {
    //   MACDPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    // }

    for (var idx = subIndicatorCount - 1; idx >= 0; --idx) {
      var type = showSubIndicators[idx];
      int orderIdx = subIndicatorCount - idx;
      double subTop = size.height - orderIdx * (indicatorH + indicatorSpacing) + indicatorSpacing;

      double subHighestValue = type == IndicatorType.vol ? maxVolume : subHighest[type] ?? 0.0;
      double subLowestValue = subLowest[type] ?? 0.0;

      // draw ruler text
      _drawSubIndicatorRulerText(canvas, indicatorH, size.width, subTop, subHighestValue, subLowestValue, size);

      if (type == IndicatorType.vol) {
        VolPainter(klineData, beginIdx).paint(canvas, size, maxVolume, slideOffset);
      }

      if (type.isLine) {
        IndicatorLinePainter.paint(
            canvas,
            size,
            indicatorH - KLineController.shared.indicatorInfoHeight,
            type,
            subIndicatorData[type],
            KLineController.shared.currentPeriods(type),
            beginIdx,
            slideOffset,
            subHighest[type] ?? 0.0,
            subLowest[type] ?? 0.0,
            top: subTop,
            lineColors: KLineController.shared.indicatorColors);
      }
    }

    // draw current price
    double currentPrice = klineData.last.close;
    double currentPriceRate = (1 - (currentPrice - lowest) / (highest - lowest));
    currentPriceRate = currentPriceRate > 1 ? 1 : currentPriceRate;
    currentPriceRate = currentPriceRate < 0 ? 0 : currentPriceRate;
    _drawCurrentPrice(
        canvas, currentPrice.toString(), Offset(size.width - 56, currentPriceRate * mainHeight + mainTopMargin));
  }

  void _drawSubIndicatorRulerText(
      Canvas canvas, double height, double width, double top, double highest, double lowest, Size canvasSize) {
    // draw highest text
    _drawText(canvas, highest.toStringAsFixed(2), Offset(width - 56, top + KLineController.shared.indicatorInfoHeight),
        width: 56);

    // draw lowest text
    _drawText(canvas, lowest.toStringAsFixed(2), Offset(width - 56, top + height - 14.0), width: 56);
  }

  /// draw Text in canvas
  void _drawText(Canvas canvas, String text, Offset offset, {double? width}) {
    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xff999999),
              fontSize: 12.0,
              height: 1.0,
            )))
      ..layout();

    double textWidth = painter.width;
    painter.paint(canvas, Offset(width != null ? (offset.dx + width - textWidth) : offset.dx, offset.dy));
  }

  void _drawHighestLowestText(Canvas canvas, String text, Offset offset, Size canvasSize) {
    // draw line
    double tranOffsetX = offset.dx < canvasSize.width * 0.5 ? 20 : -20;
    canvas.drawLine(Offset(offset.dx + (tranOffsetX > 0.0 ? 2 : -2), offset.dy),
        Offset(offset.dx + tranOffsetX, offset.dy), _minMaxLinePaint);

    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xff666666),
              fontSize: 13.0,
              height: 0.0,
            )))
      ..layout();

    double textHeight = 15.0;
    double offsetY = offset.dy - textHeight * 0.5;
    painter.paint(canvas, Offset(offset.dx + tranOffsetX + (tranOffsetX > 0 ? 5 : -painter.width - 5), offsetY));
  }

  void _drawRulerLine(Canvas canvas, double height, double width, double top, double highestPrice, double lowestPrice,
      Size canvasSize) {
    double priceOffset = highestPrice - lowestPrice;
    var ctr = KLineController.shared;
    double scaleTop = ctr.mainIndicatorInfoMargin + ctr.indicatorInfoHeight + ctr.klineMargin.top;
    double scaleHeight = height; // mainHeight - fontHeight
    // draw main ruler
    for (var i = 0; i < 5; ++i) {
      // draw vertical line
      canvas.drawLine(Offset(width * i / 5, 0), Offset(width * i / 5, canvasSize.height), _rulerPaint);
      // draw horizontal line
      if (i > 0) canvas.drawLine(Offset(0, height * i / 4 + top), Offset(width, height * i / 4 + top), _rulerPaint);
      // draw rule text
      _drawText(canvas, '${(highestPrice - priceOffset * i / 4).toStringAsFixed(2)}',
          Offset(width - 56, scaleHeight * i / 4 + scaleTop - 12),
          width: 56);
    }
  }

  void _drawCurrentPrice(Canvas canvas, String currentPrice, Offset offset) {
    canvas.drawRRect(
        RRect.fromLTRBR(offset.dx - 1, offset.dy - 9, offset.dx + 56, offset.dy + 9, const Radius.circular(4)),
        _currentPriceBgPaint);
    canvas.drawRRect(
        RRect.fromLTRBR(offset.dx - 1, offset.dy - 9, offset.dx + 56, offset.dy + 9, const Radius.circular(4)),
        _currentPricePaint);
    _drawText(canvas, currentPrice, Offset(offset.dx + 3, offset.dy - 6));

    // 画虚线
    double startX = 0.0;
    double dashWidth = 3.0;
    while (startX < offset.dx - 2) {
      canvas.drawLine(Offset(startX, offset.dy), Offset(startX + dashWidth, offset.dy), _currentPricePaint);
      startX += 5.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
