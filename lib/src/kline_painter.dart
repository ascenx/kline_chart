import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './indicators/indicator_data_cache.dart';
import './indicators/indicator_result.dart';
import './kline_axis.dart';
import './kline_chart_style.dart';
import './kline_controller.dart';
import './indicators/indicator_line_painter.dart';
import './indicators/macd_painter.dart';
import './indicators/sar_painter.dart';
import './indicators/vol_painter.dart';
import './kline_data.dart';
import './kline_overlay.dart';
import './kline_overlay_painter.dart';

class KLinePainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;
  final KLineController controller;
  final KLineChartStyle _chartStyle;
  final KLineCandleStyle _candleStyle;
  final KLineVolumeStyle _volumeStyle;
  final KLineOverlayStyle _overlayStyle;
  final KLineNumberFormatter? _priceFormatter;
  final KLineNumberFormatter? _volumeFormatter;
  final KLineIndicatorFormatter? _indicatorFormatter;
  final KLineTimeFormatter? _timeFormatter;
  final List<Color> _indicatorColors;
  final List<KLineOverlay> _overlays;
  final Color _sarColor;
  final bool _showTimeChart;
  final bool _showTimeAxis;
  final double _timeAxisHeight;
  final double _timeAxisMinLabelSpacing;
  final int _priceAxisMaxTickCount;
  final double _priceAxisMinTickSpacing;
  final int _dataVersion;
  final _KLinePainterConfig _config;
  final KLineIndicatorDataCache _indicatorDataCache;

  KLinePainter(this.klineData, this.beginIdx,
      {KLineController? controller,
      KLineIndicatorDataCache? indicatorDataCache})
      : controller = controller ?? KLineController.shared,
        _chartStyle = (controller ?? KLineController.shared).chartStyle,
        _candleStyle = (controller ?? KLineController.shared).candleStyle,
        _volumeStyle = (controller ?? KLineController.shared).volumeStyle,
        _overlayStyle = (controller ?? KLineController.shared).overlayStyle,
        _priceFormatter = (controller ?? KLineController.shared).priceFormatter,
        _volumeFormatter =
            (controller ?? KLineController.shared).volumeFormatter,
        _indicatorFormatter =
            (controller ?? KLineController.shared).indicatorFormatter,
        _timeFormatter = (controller ?? KLineController.shared).timeFormatter,
        _indicatorColors = List<Color>.of(
            (controller ?? KLineController.shared).indicatorColors),
        _overlays = List<KLineOverlay>.of(
            (controller ?? KLineController.shared).overlays),
        _sarColor = (controller ?? KLineController.shared).sarColor,
        _showTimeChart = (controller ?? KLineController.shared).showTimeChart,
        _showTimeAxis = (controller ?? KLineController.shared).showTimeAxis,
        _timeAxisHeight = (controller ?? KLineController.shared).timeAxisHeight,
        _timeAxisMinLabelSpacing =
            (controller ?? KLineController.shared).timeAxisMinLabelSpacing,
        _priceAxisMaxTickCount =
            (controller ?? KLineController.shared).priceAxisMaxTickCount,
        _priceAxisMinTickSpacing =
            (controller ?? KLineController.shared).priceAxisMinTickSpacing,
        _dataVersion = (controller ?? KLineController.shared).dataVersion,
        _config = _KLinePainterConfig.fromController(
            controller ?? KLineController.shared),
        _indicatorDataCache = indicatorDataCache ??
            KLineIndicatorDataCache(klineData, beginIdx,
                controller: controller ?? KLineController.shared);

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
    ..color = Colors.blueGrey.withAlpha(51);

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
  final _currentPriceDashPath = Path();

  // draw kline

  @override
  void paint(Canvas canvas, Size size) {
    _configurePaints();
    canvas.drawRect(Offset.zero & size, _backgroundPaint);
    if (klineData.isEmpty) return;

    // debugPrint('debug: kline painter repaint');

    bool isTimeChart = _showTimeChart;
    final timeAxisHeight = _showTimeAxis
        ? _timeAxisHeight.clamp(0.0, size.height).toDouble()
        : 0.0;

    final showSubIndicators = controller.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double spacing = controller.spacing;
    double itemW =
        KLineController.getItemWidth(size.width, controller: controller);
    double itemCount = controller.itemCount;

    double mainTopMargin = controller.klineMargin.top;
    double mainInfoMargin = controller.mainIndicatorInfoMargin;

    double indicatorInfoHeight = controller.indicatorInfoHeight;
    double indicatorSpacing = controller.indicatorSpacing;

    // main draw area height
    double mainHeight = size.height -
        (controller.subIndicatorHeight + indicatorSpacing) * subIndicatorCount -
        timeAxisHeight -
        controller.klineMargin.bottom;

    _timeLineAreaPaint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, mainHeight),
      <Color>[
        _chartStyle.timeLineFillColor,
        _chartStyle.timeLineFillColor.withAlpha(0),
      ],
    );

    if (controller.showMainIndicators.isNotEmpty) {
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
    bool isShowMA = controller.showMainIndicators.contains(IndicatorType.ma);
    bool isShowEMA = controller.showMainIndicators.contains(IndicatorType.ema);
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

    bool isShowSAR = controller.showMainIndicators.contains(IndicatorType.sar);
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
        controller.showMainIndicators.contains(IndicatorType.boll);
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

    _drawRulerLine(canvas, mainHeight, size.width, highest, lowest, size,
        drawVerticalGridLines: !_showTimeAxis);

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
    final lineLeadingItemCount = leadingLineDataCountForBeginIndex(beginIdx);

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
      _drawHighestLowestText(canvas, controller.formatPrice(mainHighest),
          Offset(highestX, highestY), size);
      _drawHighestLowestText(canvas, controller.formatPrice(mainLowest),
          Offset(lowestX, lowestY), size);
    }

    if (isShowMA || isShowEMA) {
      final indicatorType = isShowMA ? IndicatorType.ma : IndicatorType.ema;
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      IndicatorLinePainter.paint(
          canvas,
          size,
          mainHeight,
          indicatorType,
          mainIndicatorData,
          indicatorPeriods,
          beginIdx,
          slideOffset,
          highest,
          lowest,
          top: controller.klineMargin.top,
          controller: controller,
          lineColors: _indicatorColors,
          leadingItemCount: isShowMA ? 1 : lineLeadingItemCount,
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
          controller.showMainIndicators.first,
          mainIndicatorData,
          bollPeriods,
          beginIdx,
          slideOffset,
          highest,
          lowest,
          top: controller.klineMargin.top,
          controller: controller,
          lineColors: _indicatorColors,
          leadingItemCount: lineLeadingItemCount,
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
        top: controller.klineMargin.top,
        pointColor: _sarColor,
        controller: controller,
      );
    }

    KLineOverlayPainter.paint(
      canvas: canvas,
      size: size,
      data: klineData,
      overlays: _overlays,
      beginIndex: beginIdx,
      itemWidth: itemW,
      spacing: spacing,
      highest: highest,
      lowest: lowest,
      top: mainTopMargin,
      height: mainHeight,
      style: _overlayStyle,
      formatPrice: controller.formatPrice,
    );

    // draw sub indicator
    double indicatorH = controller.subIndicatorHeight;

    // if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.macd)) {
    //   MACDPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    // }

    for (var idx = subIndicatorCount - 1; idx >= 0; --idx) {
      var type = showSubIndicators[idx];
      int orderIdx = subIndicatorCount - idx;
      double subTop = size.height -
          timeAxisHeight -
          orderIdx * (indicatorH + indicatorSpacing) +
          indicatorSpacing;

      double subHighestValue =
          type == IndicatorType.vol ? maxVolume : subHighest[type] ?? 0.0;
      double subLowestValue = subLowest[type] ?? 0.0;

      // draw ruler text
      _drawSubIndicatorRulerText(canvas, indicatorH, size.width, subTop,
          subHighestValue, subLowestValue, size, type);

      if (type == IndicatorType.vol) {
        VolPainter(klineData, beginIdx,
                controller: controller, indicatorDataCache: _indicatorDataCache)
            .paint(canvas, size, maxVolume, slideOffset,
                showInfo: false, top: subTop);
      } else if (type == IndicatorType.macd) {
        _macdPainter.paintData(
            canvas,
            size,
            subIndicatorData[type] ?? [],
            indicatorH - controller.indicatorInfoHeight,
            _indicatorDataCache.periodsFor(type),
            slideOffset,
            subHighestValue,
            subLowestValue,
            top: subTop,
            controller: controller,
            lineColors: _indicatorColors,
            leadingItemCount: leadingDataCountForBeginIndex(beginIdx),
            showInfo: false);
      }

      if (type.isLine) {
        IndicatorLinePainter.paint(
            canvas,
            size,
            indicatorH - controller.indicatorInfoHeight,
            type,
            subIndicatorData[type],
            _indicatorDataCache.periodsFor(type),
            beginIdx,
            slideOffset,
            subHighestValue,
            subLowestValue,
            top: subTop,
            controller: controller,
            lineColors: _indicatorColors,
            leadingItemCount: lineLeadingItemCount,
            showInfo: false);
      }
    }

    _drawTimeAxis(
      canvas,
      width: size.width,
      axisTop: size.height - controller.klineMargin.bottom - timeAxisHeight,
      axisHeight: timeAxisHeight,
      itemWidth: itemW,
      spacing: spacing,
    );

    // draw current price
    double currentPrice = klineData.last.close;
    double currentPriceRate = highest == lowest
        ? 0.5
        : (1 - (currentPrice - lowest) / (highest - lowest));
    currentPriceRate = currentPriceRate > 1 ? 1 : currentPriceRate;
    currentPriceRate = currentPriceRate < 0 ? 0 : currentPriceRate;
    _drawCurrentPrice(canvas, controller.formatCurrentPrice(currentPrice),
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

  void _drawSubIndicatorRulerText(
      Canvas canvas,
      double height,
      double width,
      double top,
      double highest,
      double lowest,
      Size canvasSize,
      IndicatorType type) {
    final formatValue = type == IndicatorType.vol
        ? controller.formatVolume
        : (double value) => controller.formatIndicator(value, type);
    // draw highest text
    _drawText(canvas, formatValue(highest),
        Offset(width - 56, top + controller.indicatorInfoHeight),
        width: 56);

    // draw lowest text
    _drawText(
        canvas, formatValue(lowest), Offset(width - 56, top + height - 14.0),
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

  void _drawRulerLine(Canvas canvas, double height, double width,
      double highestPrice, double lowestPrice, Size canvasSize,
      {required bool drawVerticalGridLines}) {
    var ctr = controller;
    double scaleTop = ctr.mainIndicatorInfoMargin +
        ctr.indicatorInfoHeight +
        ctr.klineMargin.top;
    final ticks = KLineAxis.priceTicks(
      minValue: lowestPrice,
      maxValue: highestPrice,
      top: scaleTop,
      height: height,
      maxTickCount: _priceAxisMaxTickCount,
      minTickSpacing: _priceAxisMinTickSpacing,
    );

    // draw main ruler
    if (drawVerticalGridLines) {
      for (var i = 0; i < 5; ++i) {
        final x = width * i / 5;
        canvas.drawLine(
            Offset(x, 0), Offset(x, canvasSize.height), _rulerPaint);
      }
    }

    for (final tick in ticks) {
      if (tick.y > scaleTop && tick.y < scaleTop + height) {
        canvas.drawLine(Offset(0, tick.y), Offset(width, tick.y), _rulerPaint);
      }
      _drawText(
        canvas,
        controller.formatPrice(tick.value),
        Offset(width - 56, tick.y - 6),
        width: 56,
      );
    }
  }

  void _drawTimeAxis(
    Canvas canvas, {
    required double width,
    required double axisTop,
    required double axisHeight,
    required double itemWidth,
    required double spacing,
  }) {
    if (!_showTimeAxis || axisHeight <= 0 || klineData.isEmpty) {
      return;
    }

    final ticks = KLineAxis.timeTicksForIndexedData(
      dataLength: klineData.length,
      timeAt: (index) => klineData[index].time,
      beginIndex: beginIdx,
      itemWidth: itemWidth,
      spacing: spacing,
      itemCount: controller.itemCount,
      viewportWidth: width,
      minLabelSpacing: _timeAxisMinLabelSpacing,
    );
    if (ticks.isEmpty) {
      return;
    }

    canvas.drawLine(Offset(0, axisTop), Offset(width, axisTop), _rulerPaint);

    final style = _chartStyle.rulerTextStyle;
    var lastLabelRight = double.negativeInfinity;
    for (final tick in ticks) {
      canvas.drawLine(Offset(tick.x, 0), Offset(tick.x, axisTop), _rulerPaint);

      final time = DateTime.fromMillisecondsSinceEpoch(tick.time);
      final label = controller.formatTime(time, tick.granularity);
      _textPainter.text = TextSpan(text: label, style: style);
      _textPainter.layout();

      final maxLabelLeft =
          width > _textPainter.width ? width - _textPainter.width : 0.0;
      final labelLeft = (tick.x - _textPainter.width * 0.5)
          .clamp(0.0, maxLabelLeft)
          .toDouble();
      final labelRight = labelLeft + _textPainter.width;
      if (labelLeft < lastLabelRight + 4) {
        continue;
      }

      final labelTop = axisTop +
          (axisHeight - _textPainter.height).clamp(0.0, axisHeight).toDouble() *
              0.5;
      _textPainter.paint(canvas, Offset(labelLeft, labelTop));
      lastLabelRight = labelRight;
    }
  }

  void _drawCurrentPrice(Canvas canvas, String currentPrice, Offset offset) {
    _textPainter.text =
        TextSpan(text: currentPrice, style: _chartStyle.currentPriceTextStyle);
    _textPainter.layout();
    double markerWidth = _textPainter.width + 8;
    if (markerWidth < 56) {
      markerWidth = 56;
    }
    final markerRight = offset.dx + 56;
    final markerLeft = markerRight - markerWidth;

    canvas.drawRRect(
        RRect.fromLTRBR(markerLeft - 1, offset.dy - 9, markerRight,
            offset.dy + 9, const Radius.circular(4)),
        _currentPriceBgPaint);
    canvas.drawRRect(
        RRect.fromLTRBR(markerLeft - 1, offset.dy - 9, markerRight,
            offset.dy + 9, const Radius.circular(4)),
        _currentPricePaint);
    _drawText(canvas, currentPrice, Offset(markerLeft + 3, offset.dy - 6),
        style: _chartStyle.currentPriceTextStyle);

    // draw dotted line
    double startX = 0.0;
    double dashWidth = 3.0;
    _currentPriceDashPath.reset();
    while (startX < markerLeft - 2) {
      _currentPriceDashPath
        ..moveTo(startX, offset.dy)
        ..lineTo(startX + dashWidth, offset.dy);
      startX += 5.0;
    }
    canvas.drawPath(_currentPriceDashPath, _currentPricePaint);
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

  static int leadingDataCountForBeginIndex(double beginIdx) {
    return beginIdx.ceil().clamp(0, 2).toInt();
  }

  static int leadingLineDataCountForBeginIndex(double beginIdx) {
    return beginIdx.ceil().clamp(0, 1).toInt();
  }

  @override
  bool shouldRepaint(covariant KLinePainter oldDelegate) {
    return oldDelegate._dataVersion != _dataVersion ||
        oldDelegate.klineData != klineData ||
        oldDelegate.beginIdx != beginIdx ||
        oldDelegate._config != _config ||
        oldDelegate._chartStyle != _chartStyle ||
        oldDelegate._candleStyle != _candleStyle ||
        oldDelegate._volumeStyle != _volumeStyle ||
        oldDelegate._overlayStyle != _overlayStyle ||
        oldDelegate._priceFormatter != _priceFormatter ||
        oldDelegate._volumeFormatter != _volumeFormatter ||
        oldDelegate._indicatorFormatter != _indicatorFormatter ||
        oldDelegate._timeFormatter != _timeFormatter ||
        oldDelegate._showTimeChart != _showTimeChart ||
        oldDelegate._showTimeAxis != _showTimeAxis ||
        oldDelegate._timeAxisHeight != _timeAxisHeight ||
        oldDelegate._timeAxisMinLabelSpacing != _timeAxisMinLabelSpacing ||
        oldDelegate._priceAxisMaxTickCount != _priceAxisMaxTickCount ||
        oldDelegate._priceAxisMinTickSpacing != _priceAxisMinTickSpacing ||
        !listEquals(oldDelegate._indicatorColors, _indicatorColors) ||
        !listEquals(oldDelegate._overlays, _overlays) ||
        oldDelegate._sarColor != _sarColor;
  }
}

class _KLinePainterConfig {
  final List<IndicatorType> showMainIndicators;
  final List<IndicatorType> showSubIndicators;
  final List<int> volMaPeriods;
  final List<int> macdPeriods;
  final List<int> kdjPeriods;
  final List<int> rsiPeriods;
  final List<int> wrPeriods;
  final int bollPeriod;
  final int bollBandwidth;
  final double sarStart;
  final double sarIncrement;
  final double sarMax;
  final double itemCount;
  final double spacing;
  final EdgeInsets klineMargin;
  final double mainIndicatorInfoMargin;
  final double indicatorSpacing;
  final double subIndicatorHeight;
  final double indicatorInfoHeight;

  const _KLinePainterConfig({
    required this.showMainIndicators,
    required this.showSubIndicators,
    required this.volMaPeriods,
    required this.macdPeriods,
    required this.kdjPeriods,
    required this.rsiPeriods,
    required this.wrPeriods,
    required this.bollPeriod,
    required this.bollBandwidth,
    required this.sarStart,
    required this.sarIncrement,
    required this.sarMax,
    required this.itemCount,
    required this.spacing,
    required this.klineMargin,
    required this.mainIndicatorInfoMargin,
    required this.indicatorSpacing,
    required this.subIndicatorHeight,
    required this.indicatorInfoHeight,
  });

  factory _KLinePainterConfig.fromController(KLineController controller) {
    return _KLinePainterConfig(
      showMainIndicators: List<IndicatorType>.of(controller.showMainIndicators),
      showSubIndicators: List<IndicatorType>.of(controller.showSubIndicators),
      volMaPeriods: List<int>.of(controller.volMaPeriods),
      macdPeriods: List<int>.of(controller.macdPeriods),
      kdjPeriods: List<int>.of(controller.kdjPeriods),
      rsiPeriods: List<int>.of(controller.rsiPeriods),
      wrPeriods: List<int>.of(controller.wrPeriods),
      bollPeriod: controller.bollPeriod,
      bollBandwidth: controller.bollBandwidth,
      sarStart: controller.sarStart,
      sarIncrement: controller.sarIncrement,
      sarMax: controller.sarMax,
      itemCount: controller.itemCount,
      spacing: controller.spacing,
      klineMargin: controller.klineMargin,
      mainIndicatorInfoMargin: controller.mainIndicatorInfoMargin,
      indicatorSpacing: controller.indicatorSpacing,
      subIndicatorHeight: controller.subIndicatorHeight,
      indicatorInfoHeight: controller.indicatorInfoHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _KLinePainterConfig &&
            listEquals(other.showMainIndicators, showMainIndicators) &&
            listEquals(other.showSubIndicators, showSubIndicators) &&
            listEquals(other.volMaPeriods, volMaPeriods) &&
            listEquals(other.macdPeriods, macdPeriods) &&
            listEquals(other.kdjPeriods, kdjPeriods) &&
            listEquals(other.rsiPeriods, rsiPeriods) &&
            listEquals(other.wrPeriods, wrPeriods) &&
            other.bollPeriod == bollPeriod &&
            other.bollBandwidth == bollBandwidth &&
            other.sarStart == sarStart &&
            other.sarIncrement == sarIncrement &&
            other.sarMax == sarMax &&
            other.itemCount == itemCount &&
            other.spacing == spacing &&
            other.klineMargin == klineMargin &&
            other.mainIndicatorInfoMargin == mainIndicatorInfoMargin &&
            other.indicatorSpacing == indicatorSpacing &&
            other.subIndicatorHeight == subIndicatorHeight &&
            other.indicatorInfoHeight == indicatorInfoHeight;
  }

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(showMainIndicators),
        Object.hashAll(showSubIndicators),
        Object.hashAll(volMaPeriods),
        Object.hashAll(macdPeriods),
        Object.hashAll(kdjPeriods),
        Object.hashAll(rsiPeriods),
        Object.hashAll(wrPeriods),
        bollPeriod,
        bollBandwidth,
        sarStart,
        sarIncrement,
        sarMax,
        itemCount,
        spacing,
        klineMargin,
        mainIndicatorInfoMargin,
        indicatorSpacing,
        subIndicatorHeight,
        indicatorInfoHeight,
      ]);
}
