import 'dart:math';
import 'package:flutter/material.dart';
import './kline_chart_style.dart';
import './kline_data.dart';

enum IndicatorType {
  // main
  ma(name: "MA"),
  ema(name: "EMA"),
  boll(name: "BOLL"),
  sar(name: 'SAR', isLine: false),

  // sub
  vol(name: "VOL", isLine: false),
  maVol(name: "MAVOL"), // same as ma, use for volume's ma
  macd(name: "MACD", isLine: false),
  kdj(name: "KDJ"),
  rsi(name: "RSI"),
  wr(name: "WR"),
  obv(name: 'OBV');

  bool get isMain => index < IndicatorType.vol.index;

  final String name;
  final bool isLine; // just need draw a line
  const IndicatorType({required this.name, this.isLine = true});

  factory IndicatorType.fromName(String name) {
    for (final value in IndicatorType.values) {
      if (value.name == name) {
        return value;
      }
    }
    return IndicatorType.ma;
  }
}

class LongPressOffset extends ValueNotifier<Offset> {
  LongPressOffset(Offset value) : super(value);

  void update(Offset offset) {
    value = offset;
  }
}

class KLineZoomResult {
  final double beginIndex;
  final double itemCount;

  const KLineZoomResult({
    required this.beginIndex,
    required this.itemCount,
  });
}

class KLineController {
  List<KLineData> data = [];

  KLineChartStyle chartStyle = const KLineChartStyle();
  KLineCandleStyle candleStyle = const KLineCandleStyle();
  KLineVolumeStyle volumeStyle = const KLineVolumeStyle();
  KLineCrosshairStyle crosshairStyle = const KLineCrosshairStyle();
  KLineInfoStyle infoStyle = const KLineInfoStyle();

  bool isDebug = false;
  Color randomColor = Color.fromARGB(
      100, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
  void drawDebugRect(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color);
  }

  /// current display item count (candle count)
  double itemCount = 30;

  /// spacing between candle
  double spacing = 2.0;

  /// current item width (candle width)
  double itemWidth = 0.0;

  /// kline view margin
  var klineMargin = const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0);

  /// min candle count
  double minCount = 7;

  /// max candle count
  double maxCount = 39;

  double mainIndicatorInfoMargin = 5.0;
  double subIndicatorInfoMargin = 5.0;

  bool showTimeChart = false;

  // info
  /// set null to fix text's width
  double? infoWidgetMaxWidth = 130;
  EdgeInsets infoWidgetMargin = const EdgeInsets.only(left: 8, top: 10);
  EdgeInsets infoWidgetPadding = const EdgeInsets.all(4);
  double infoWidgetBorderRadius = 4;
  Border infoWidgetBorder =
      Border.all(color: Colors.blueGrey.withValues(alpha: 0.5), width: 0.5);

  var longPressOffset = LongPressOffset(Offset.zero);

  // /// main indicator information top margin
  // double mainIndicatorInfoTopMargin = 5.0;

  /// spacing between indicator
  double indicatorSpacing = 10.0;

  /// sub indicator height
  double subIndicatorHeight = 50.0;

  /// indicator information height
  double indicatorInfoHeight = 15.0;

  // Main indicator height = totalHeight - klineMargin.vertical - subIndicatorHeight - indicatorMargin

  /// show main indicator
  List<IndicatorType> showMainIndicators = [IndicatorType.ma];

  /// show sub indicator
  List<IndicatorType> showSubIndicators = [
    IndicatorType.vol,
    IndicatorType.kdj
  ];

  /// BOLL Calculating Period (N)
  int bollPeriod = 21;

  /// BOLL Bandwidth (P)
  int bollBandwidth = 2;

  /// SAR acceleration factor start value
  double sarStart = 0.02;

  /// SAR acceleration factor step value
  double sarIncrement = 0.02;

  /// SAR maximum acceleration factor
  double sarMax = 0.2;

  /// SAR point color
  Color sarColor = Colors.orange;

  /// VOL MA periods
  List<int> volMaPeriods = [7, 14];

  /// MACD periods
  List<int> macdPeriods = [12, 26, 9];

  /// KDJ periods
  List<int> kdjPeriods = [9, 3, 3];

  /// RSI periods
  List<int> rsiPeriods = [6, 12, 24];

  /// WR periods
  List<int> wrPeriods = [7, 14];

  List<int> currentPeriods(IndicatorType type) {
    KLineController config = KLineController.shared;
    if (type == IndicatorType.kdj) {
      return config.kdjPeriods;
    } else if (type == IndicatorType.macd) {
      return config.macdPeriods;
    } else if (type == IndicatorType.rsi) {
      return config.rsiPeriods;
    } else if (type == IndicatorType.wr) {
      return config.wrPeriods;
    } else if (type == IndicatorType.obv) {
      return [0];
    }
    return [];
  }

  List<Color> indicatorColors = [Colors.orange, Colors.purple, Colors.blue];

  static double getItemWidth(double totalWidth) {
    double spacing = KLineController.shared.spacing;
    double itemCount = KLineController.shared.itemCount;
    // item width = total width / item count - spacing
    double itemW = totalWidth / itemCount - spacing;
    KLineController.shared.itemWidth = itemW;
    return itemW;
  }

  static int dataIndexForLocalX({
    required double localX,
    required double beginIndex,
    required double itemWidth,
    required double spacing,
    required int dataLength,
  }) {
    double itemExtent = itemWidth + spacing;
    if (dataLength <= 0 || itemExtent <= 0) {
      return 0;
    }

    int index = ((localX - itemWidth * 0.5) / itemExtent + beginIndex).round();
    if (index < 0) {
      return 0;
    }
    if (index >= dataLength) {
      return dataLength - 1;
    }
    return index;
  }

  static double itemCenterXForDataIndex({
    required int dataIndex,
    required double beginIndex,
    required double itemWidth,
    required double spacing,
  }) {
    return (dataIndex - beginIndex) * (itemWidth + spacing) + itemWidth * 0.5;
  }

  static double beginIndexForScrollOffset({
    required double offset,
    required double itemExtent,
    required double itemCount,
    required int dataLength,
  }) {
    if (dataLength <= 0 || itemCount <= 0 || itemExtent <= 0) {
      return 0.0;
    }

    final rawBeginIndex = offset / itemExtent;
    if (rawBeginIndex.isNaN || rawBeginIndex.isInfinite) {
      return 0.0;
    }

    final maxBeginIndex = max(0.0, dataLength - itemCount);
    return rawBeginIndex.clamp(0.0, maxBeginIndex).toDouble();
  }

  static KLineZoomResult zoomForScale({
    required double startBeginIndex,
    required double startItemCount,
    required double scale,
    required double startFocalDx,
    required double currentFocalDx,
    required double viewportWidth,
    required int dataLength,
    required double minItemCount,
    required double maxItemCount,
  }) {
    if (dataLength <= 0 || startItemCount <= 0 || viewportWidth <= 0) {
      return const KLineZoomResult(beginIndex: 0.0, itemCount: 0.0);
    }

    final safeScale = scale > 0 ? scale : 1.0;
    final maxVisibleCount = min(maxItemCount, dataLength.toDouble());
    final minVisibleCount = min(minItemCount, maxVisibleCount);
    final nextItemCount = (startItemCount / safeScale)
        .clamp(minVisibleCount, maxVisibleCount)
        .toDouble();

    final startFocalRatio = (startFocalDx / viewportWidth).clamp(0.0, 1.0);
    final currentFocalRatio = (currentFocalDx / viewportWidth).clamp(0.0, 1.0);
    final focalDataIndex = startBeginIndex + startItemCount * startFocalRatio;
    final rawBeginIndex = focalDataIndex - nextItemCount * currentFocalRatio;
    final maxBeginIndex = max(0.0, dataLength - nextItemCount);

    return KLineZoomResult(
      beginIndex: rawBeginIndex.clamp(0.0, maxBeginIndex).toDouble(),
      itemCount: nextItemCount,
    );
  }

  // singleton
  KLineController._internal();
  static final KLineController shared = KLineController._internal();
  factory KLineController() => shared;
}
