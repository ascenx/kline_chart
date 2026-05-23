import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './indicators/indicator_data_cache.dart';
import './indicators/indicator_result.dart';
import './kline_chart_style.dart';
import './kline_controller.dart';
import './indicators/indicator_line_painter.dart';
import './indicators/macd_painter.dart';
import './indicators/sar_painter.dart';
import './indicators/vol_painter.dart';
import './kline_data.dart';

class KLinePainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;
  final KLineChartStyle _chartStyle;
  final KLineCandleStyle _candleStyle;
  final KLineVolumeStyle _volumeStyle;
  final List<Color> _indicatorColors;
  final Color _sarColor;
  final KLineIndicatorDataCache _indicatorDataCache;

  KLinePainter(this.klineData, this.beginIdx,
      {KLineIndicatorDataCache? indicatorDataCache})
      : _chartStyle = KLineController.shared.chartStyle,
        _candleStyle = KLineController.shared.candleStyle,
        _volumeStyle = KLineController.shared.volumeStyle,
        _indicatorColors =
            List<Color>.of(KLineController.shared.indicatorColors),
        _sarColor = KLineController.shared.sarColor,
        _indicatorDataCache =
            indicatorDataCache ?? KLineIndicatorDataCache(klineData, beginIdx);

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
  final _backgroundPaint = Paint()..style = PaintingStyle.fill;
  final _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  final _macdPainter = MACDPainter();
  final _sarPainter = SARPainter();

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
  final _riseCandleBodyPath = Path();
  final _fallCandleBodyPath = Path();
  final _riseCandleWickPath = Path();
  final _fallCandleWickPath = Path();

  // draw kline

  @override
  void paint(Canvas canvas, Size size) {
    _configurePaints();
    canvas.drawRect(Offset.zero & size, _backgroundPaint);
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
        (KLineController.shared.subIndicatorHeight + indicatorSpacing) *
            subIndicatorCount -
        KLineController.shared.klineMargin.bottom;

    _timeLineAreaPaint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, mainHeight),
      <Color>[
        _chartStyle.timeLineFillColor,
        _chartStyle.timeLineFillColor.withValues(alpha: 0.0),
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
    final beginDataIndex =
        beginIdx.ceil().clamp(0, klineData.length - 1).toInt();
    KLineData beginData = klineData[beginDataIndex];
    double highest = beginData.high;
    double lowest = beginData.low;

    double maxVolume = beginData.volume;

    double highestIdx = beginIdx, lowestIdx = beginIdx;

    for (var i = beginIdx - 1; i < beginIdx + itemCount; ++i) {
      if (i >= klineData.length) break;
      int idx = i.ceil();
      idx = idx < 0 ? 0 : idx;
      if (idx >= klineData.length) break;
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
      if (volume > maxVolume) {
        maxVolume = volume;
      }
    }

    double mainHighest = highest, mainLowest = lowest;

    List<List<double>> mainIndicatorData = [];
    List<List<double>> sarIndicatorData = [];
    bool isShowMA =
        KLineController.shared.showMainIndicators.contains(IndicatorType.ma);
    bool isShowEMA =
        KLineController.shared.showMainIndicators.contains(IndicatorType.ema);
    if (isShowMA || isShowEMA) {
      var res = IndicatorResult.empty;
      if (isShowMA) {
        res = _indicatorDataCache.result(IndicatorType.ma);
      } else if (isShowEMA) {
        res = _indicatorDataCache.result(IndicatorType.ema);
      }

      mainIndicatorData = res.data;
      double mainIndicatorMax = res.maxValue;
      double mainIndicatorMin = res.minValue;
      if (mainIndicatorMax > highest) {
        highest = mainIndicatorMax;
      }
      if (mainIndicatorMin < lowest && mainIndicatorMin != 0.0) {
        lowest = mainIndicatorMin;
      }
    }

    bool isShowSAR =
        KLineController.shared.showMainIndicators.contains(IndicatorType.sar);
    if (isShowSAR) {
      final res = _indicatorDataCache.result(IndicatorType.sar);
      sarIndicatorData = res.data;
      final sarMax = res.maxValue;
      final sarMin = res.minValue;

      if (sarMax > highest) {
        highest = sarMax;
      }
      if (sarMin < lowest && sarMin != 0.0) {
        lowest = sarMin;
      }
    }

    bool isShowBOLL =
        KLineController.shared.showMainIndicators.contains(IndicatorType.boll);
    if (isShowBOLL) {
      final res = _indicatorDataCache.result(IndicatorType.boll);
      mainIndicatorData = res.data;
      double bollMax = res.maxValue;
      double bollMin = res.minValue;

      if (bollMax > highest) {
        highest = bollMax;
      }
      if (bollMin < lowest && bollMin != 0.0) {
        lowest = bollMin;
      }
    }

    _drawRulerLine(
        canvas,
        mainHeight,
        size.width,
        indicatorInfoHeight + KLineController.shared.mainIndicatorInfoMargin,
        highest,
        lowest,
        size);

    // KDJ, RSI, WR, MACD, OBV
    Map<IndicatorType, dynamic> subIndicatorData = {};
    Map<IndicatorType, double> subHighest = {}, subLowest = {};
    IndicatorType macdType = IndicatorType.macd;
    if (showSubIndicators.contains(macdType)) {
      final res = _indicatorDataCache.result(macdType);
      subIndicatorData[macdType] = res.data;
      subHighest[macdType] = res.maxValue;
      subLowest[macdType] = res.minValue;
    }
    IndicatorType kdjType = IndicatorType.kdj;
    if (showSubIndicators.contains(kdjType)) {
      final res = _indicatorDataCache.result(kdjType);
      subIndicatorData[kdjType] = res.data;
      subHighest[kdjType] = res.maxValue;
      subLowest[kdjType] = res.minValue;
    }
    IndicatorType rsiType = IndicatorType.rsi;
    if (showSubIndicators.contains(rsiType)) {
      final res = _indicatorDataCache.result(rsiType);
      subIndicatorData[rsiType] = res.data;
      subHighest[rsiType] = res.maxValue;
      subLowest[rsiType] = res.minValue;
    }
    IndicatorType wrType = IndicatorType.wr;
    if (showSubIndicators.contains(wrType)) {
      final res = _indicatorDataCache.result(wrType);
      subIndicatorData[wrType] = res.data;
      subHighest[wrType] = res.maxValue;
      subLowest[wrType] = res.minValue;
    }

    IndicatorType obvType = IndicatorType.obv;
    if (showSubIndicators.contains(obvType)) {
      final res = _indicatorDataCache.result(obvType);
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
    _riseCandleBodyPath.reset();
    _fallCandleBodyPath.reset();
    _riseCandleWickPath.reset();
    _fallCandleWickPath.reset();
    bool hasTimeLineStart = false;
    var hasRiseCandle = false;
    var hasFallCandle = false;

    for (var i = beginIdx - 1; i < beginIdx + itemCount; ++i) {
      if (i >= klineData.length) break;
      int idx = i.ceil();
      idx = idx < 0 ? 0 : idx;
      if (idx >= klineData.length) break;
      KLineData data = klineData[idx];

      double open = data.open;
      double high = data.high;
      double low = data.low;
      double close = data.close;

      double lineX = rectLeft + itemW * 0.5 + slideOffset;

      if (isTimeChart) {
        int previousIdx = idx > 0 ? idx - 1 : idx;
        double lastX = idx == 0
            ? lineX
            : rectLeft + itemW * 0.5 + slideOffset - itemW - spacing;
        double lastY = _valueToY(klineData[previousIdx].close, lowest,
            valueOffset, mainHeight, mainTopMargin);
        double timelineY =
            _valueToY(close, lowest, valueOffset, mainHeight, mainTopMargin);
        canvas.drawLine(
            Offset(lastX, lastY), Offset(lineX, timelineY), _timeLinePaint);

        if (!hasTimeLineStart) {
          _timeLinePath.moveTo(lineX, timelineY);
          hasTimeLineStart = true;
        } else {
          _timeLinePath.lineTo(lineX, timelineY);
        }
      } else {
        // draw candle chart
        double lineTop =
            _valueToY(high, lowest, valueOffset, mainHeight, mainTopMargin);
        double lineBtm =
            _valueToY(low, lowest, valueOffset, mainHeight, mainTopMargin);

        if (i == highestIdx) {
          highestX = lineX;
          highestY = lineTop;
        }
        if (i == lowestIdx) {
          lowestX = lineX;
          lowestY = lineBtm;
        }

        if (close > open) {
          double itemH = _valueHeight(close - open, valueOffset, mainHeight);
          double rectTop =
              _valueToY(open, lowest, valueOffset, mainHeight, mainTopMargin);
          rectTop -= itemH; // rise starts at the top
          _riseCandleBodyPath.addRect(
              Rect.fromLTWH(rectLeft + slideOffset, rectTop, itemW, itemH));
          _riseCandleWickPath
            ..moveTo(lineX, lineTop)
            ..lineTo(lineX, lineBtm);
          hasRiseCandle = true;
        } else {
          double itemH = _valueHeight(open - close, valueOffset, mainHeight);
          double rectTop =
              _valueToY(open, lowest, valueOffset, mainHeight, mainTopMargin);
          _fallCandleBodyPath.addRect(
              Rect.fromLTWH(rectLeft + slideOffset, rectTop, itemW, itemH));
          _fallCandleWickPath
            ..moveTo(lineX, lineTop)
            ..lineTo(lineX, lineBtm);
          hasFallCandle = true;
        }
      }

      rectLeft += (itemW + spacing);
    }

    if (isTimeChart) {
      _timeLinePath.lineTo(size.width - (itemW - slideOffset) + spacing,
          mainHeight + mainTopMargin);
      _timeLinePath.lineTo(
          itemW * 0.5 + slideOffset, mainHeight + mainTopMargin);
      _timeLinePath.close();

      canvas.drawPath(_timeLinePath, _timeLineAreaPaint);
    } else {
      if (hasRiseCandle) {
        canvas.drawPath(_riseCandleBodyPath, _riseRectPaint);
      }
      if (hasFallCandle) {
        canvas.drawPath(_fallCandleBodyPath, _fallRectPaint);
      }
      if (hasRiseCandle) {
        canvas.drawPath(_riseCandleWickPath, _riseLinePaint);
      }
      if (hasFallCandle) {
        canvas.drawPath(_fallCandleWickPath, _fallLinePaint);
      }
      _drawHighestLowestText(
          canvas, "$mainHighest", Offset(highestX, highestY), size);
      _drawHighestLowestText(
          canvas, "$mainLowest", Offset(lowestX, lowestY), size);
    }

    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      IndicatorLinePainter.paint(
          canvas,
          size,
          mainHeight,
          KLineController.shared.showMainIndicators.first,
          mainIndicatorData,
          indicatorPeriods,
          beginIdx,
          slideOffset,
          highest,
          lowest,
          top: KLineController.shared.klineMargin.top,
          lineColors: _indicatorColors,
          showInfo: false,
          debugData: klineData);
    }

    if (isShowBOLL) {
      // List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      final bollPeriods = _indicatorDataCache.periodsFor(IndicatorType.boll);
      IndicatorLinePainter.paint(
          canvas,
          size,
          mainHeight,
          KLineController.shared.showMainIndicators.first,
          mainIndicatorData,
          bollPeriods,
          beginIdx,
          slideOffset,
          highest,
          lowest,
          top: KLineController.shared.klineMargin.top,
          lineColors: _indicatorColors,
          showInfo: false);
    }

    if (isShowSAR) {
      _sarPainter.paintData(
        canvas,
        size,
        sarIndicatorData,
        mainHeight,
        slideOffset,
        highest,
        lowest,
        top: KLineController.shared.klineMargin.top,
        pointColor: _sarColor,
      );
    }

    // draw sub indicator
    double indicatorH = KLineController.shared.subIndicatorHeight;

    // if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.macd)) {
    //   MACDPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    // }

    for (var idx = subIndicatorCount - 1; idx >= 0; --idx) {
      var type = showSubIndicators[idx];
      int orderIdx = subIndicatorCount - idx;
      double subTop = size.height -
          orderIdx * (indicatorH + indicatorSpacing) +
          indicatorSpacing;

      double subHighestValue =
          type == IndicatorType.vol ? maxVolume : subHighest[type] ?? 0.0;
      double subLowestValue = subLowest[type] ?? 0.0;

      // draw ruler text
      _drawSubIndicatorRulerText(canvas, indicatorH, size.width, subTop,
          subHighestValue, subLowestValue, size);

      if (type == IndicatorType.vol) {
        VolPainter(klineData, beginIdx, indicatorDataCache: _indicatorDataCache)
            .paint(canvas, size, maxVolume, slideOffset, showInfo: false);
      } else if (type == IndicatorType.macd) {
        _macdPainter.paintData(
            canvas,
            size,
            subIndicatorData[type] ?? [],
            indicatorH - KLineController.shared.indicatorInfoHeight,
            _indicatorDataCache.periodsFor(type),
            slideOffset,
            subHighest[type] ?? 0.0,
            subLowest[type] ?? 0.0,
            top: subTop,
            lineColors: _indicatorColors,
            showInfo: false);
      }

      if (type.isLine) {
        IndicatorLinePainter.paint(
            canvas,
            size,
            indicatorH - KLineController.shared.indicatorInfoHeight,
            type,
            subIndicatorData[type],
            _indicatorDataCache.periodsFor(type),
            beginIdx,
            slideOffset,
            subHighest[type] ?? 0.0,
            subLowest[type] ?? 0.0,
            top: subTop,
            lineColors: _indicatorColors,
            showInfo: false);
      }
    }

    // draw current price
    double currentPrice = klineData.last.close;
    double currentPriceRate = highest == lowest
        ? 0.5
        : (1 - (currentPrice - lowest) / (highest - lowest));
    currentPriceRate = currentPriceRate > 1 ? 1 : currentPriceRate;
    currentPriceRate = currentPriceRate < 0 ? 0 : currentPriceRate;
    _drawCurrentPrice(canvas, currentPrice.toString(),
        Offset(size.width - 56, currentPriceRate * mainHeight + mainTopMargin));
  }

  double _valueToY(double value, double minValue, double valueOffset,
      double height, double top) {
    if (valueOffset == 0.0) {
      return top + height * 0.5;
    }
    return height * (1 - (value - minValue) / valueOffset) + top;
  }

  double _valueHeight(double valueOffset, double range, double height) {
    if (range == 0.0) {
      return 0.0;
    }
    return valueOffset / range * height;
  }

  void _configurePaints() {
    _riseRectPaint.color = _candleStyle.riseColor;
    _riseLinePaint
      ..color = _candleStyle.riseWickColor
      ..strokeWidth = _candleStyle.wickLineWidth;
    _fallRectPaint.color = _candleStyle.fallColor;
    _fallLinePaint
      ..color = _candleStyle.fallWickColor
      ..strokeWidth = _candleStyle.wickLineWidth;
    _minMaxLinePaint
      ..color = _chartStyle.highLowLineColor
      ..strokeWidth = _chartStyle.highLowLineWidth;
    _rulerPaint
      ..color = _chartStyle.gridLineColor
      ..strokeWidth = _chartStyle.gridLineWidth;
    _currentPricePaint
      ..color = _chartStyle.currentPriceLineColor
      ..strokeWidth = _chartStyle.currentPriceLineWidth;
    _currentPriceBgPaint.color = _chartStyle.currentPriceBackgroundColor;
    _backgroundPaint.color = _chartStyle.backgroundColor;
    _timeLinePaint
      ..color = _chartStyle.timeLineColor
      ..strokeWidth = _chartStyle.timeLineWidth;
  }

  void _drawSubIndicatorRulerText(Canvas canvas, double height, double width,
      double top, double highest, double lowest, Size canvasSize) {
    // draw highest text
    _drawText(canvas, highest.toStringAsFixed(2),
        Offset(width - 56, top + KLineController.shared.indicatorInfoHeight),
        width: 56);

    // draw lowest text
    _drawText(canvas, lowest.toStringAsFixed(2),
        Offset(width - 56, top + height - 14.0),
        width: 56);
  }

  /// draw Text in canvas
  void _drawText(Canvas canvas, String text, Offset offset,
      {double? width, TextStyle? style}) {
    _textPainter.text =
        TextSpan(text: text, style: style ?? _chartStyle.rulerTextStyle);
    _textPainter.layout();

    double textWidth = _textPainter.width;
    _textPainter.paint(
        canvas,
        Offset(width != null ? (offset.dx + width - textWidth) : offset.dx,
            offset.dy));
  }

  void _drawHighestLowestText(
      Canvas canvas, String text, Offset offset, Size canvasSize) {
    // draw line
    double tranOffsetX = offset.dx < canvasSize.width * 0.5 ? 20 : -20;
    canvas.drawLine(Offset(offset.dx + (tranOffsetX > 0.0 ? 2 : -2), offset.dy),
        Offset(offset.dx + tranOffsetX, offset.dy), _minMaxLinePaint);

    _textPainter.text =
        TextSpan(text: text, style: _chartStyle.highLowTextStyle);
    _textPainter.layout();

    double textHeight = 15.0;
    double offsetY = offset.dy - textHeight * 0.5;
    _textPainter.paint(
        canvas,
        Offset(
            offset.dx +
                tranOffsetX +
                (tranOffsetX > 0 ? 5 : -_textPainter.width - 5),
            offsetY));
  }

  void _drawRulerLine(Canvas canvas, double height, double width, double top,
      double highestPrice, double lowestPrice, Size canvasSize) {
    double priceOffset = highestPrice - lowestPrice;
    var ctr = KLineController.shared;
    double scaleTop = ctr.mainIndicatorInfoMargin +
        ctr.indicatorInfoHeight +
        ctr.klineMargin.top;
    double scaleHeight = height; // mainHeight - fontHeight
    // draw main ruler
    for (var i = 0; i < 5; ++i) {
      // draw vertical line
      canvas.drawLine(Offset(width * i / 5, 0),
          Offset(width * i / 5, canvasSize.height), _rulerPaint);
      // draw horizontal line
      if (i > 0) {
        canvas.drawLine(Offset(0, height * i / 4 + top),
            Offset(width, height * i / 4 + top), _rulerPaint);
      }
      // draw rule text
      _drawText(
          canvas,
          '${(highestPrice - priceOffset * i / 4).toStringAsFixed(2)}',
          Offset(width - 56, scaleHeight * i / 4 + scaleTop - 12),
          width: 56);
    }
  }

  void _drawCurrentPrice(Canvas canvas, String currentPrice, Offset offset) {
    canvas.drawRRect(
        RRect.fromLTRBR(offset.dx - 1, offset.dy - 9, offset.dx + 56,
            offset.dy + 9, const Radius.circular(4)),
        _currentPriceBgPaint);
    canvas.drawRRect(
        RRect.fromLTRBR(offset.dx - 1, offset.dy - 9, offset.dx + 56,
            offset.dy + 9, const Radius.circular(4)),
        _currentPricePaint);
    _drawText(canvas, currentPrice, Offset(offset.dx + 3, offset.dy - 6),
        style: _chartStyle.currentPriceTextStyle);

    // draw dotted line
    double startX = 0.0;
    double dashWidth = 3.0;
    while (startX < offset.dx - 2) {
      canvas.drawLine(Offset(startX, offset.dy),
          Offset(startX + dashWidth, offset.dy), _currentPricePaint);
      startX += 5.0;
    }
  }

  static int? selectedVisibleIndexForLongPress({
    required Offset longPressOffset,
    required double beginIdx,
    required double itemWidth,
    required double spacing,
    required int dataLength,
  }) {
    if (longPressOffset == Offset.zero || dataLength <= 0) {
      return null;
    }

    final dataIndex = KLineController.dataIndexForLocalX(
      localX: longPressOffset.dx,
      beginIndex: beginIdx,
      itemWidth: itemWidth,
      spacing: spacing,
      dataLength: dataLength,
    );
    final visibleStart = beginIdx.ceil().clamp(0, dataLength).toInt();
    return dataIndex - visibleStart;
  }

  @override
  bool shouldRepaint(covariant KLinePainter oldDelegate) {
    return oldDelegate.klineData != klineData ||
        oldDelegate.beginIdx != beginIdx ||
        oldDelegate._chartStyle != _chartStyle ||
        oldDelegate._candleStyle != _candleStyle ||
        oldDelegate._volumeStyle != _volumeStyle ||
        !listEquals(oldDelegate._indicatorColors, _indicatorColors) ||
        oldDelegate._sarColor != _sarColor;
  }
}
