import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import './kline_axis.dart';
import './kline_chart_style.dart';
import './kline_data.dart';
import './kline_overlay.dart';

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

/// Formats a price or volume value for display.
typedef KLineNumberFormatter = String Function(double value);

/// Formats an indicator value for display.
typedef KLineIndicatorFormatter = String Function(
  double value,
  IndicatorType type,
  int? period,
);

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

enum KLineDataChangeType {
  setData,
  updateLast,
  append,
  prependHistory,
  clear,
}

class KLineDataChange {
  final KLineDataChangeType type;
  final int previousLength;
  final int newLength;
  final int addedCount;
  final bool resetView;

  const KLineDataChange({
    required this.type,
    required this.previousLength,
    required this.newLength,
    this.addedCount = 0,
    this.resetView = false,
  });
}

class KLineController extends ChangeNotifier {
  List<KLineData> _data = [];
  late UnmodifiableListView<KLineData> _dataView =
      UnmodifiableListView<KLineData>(_data);
  List<KLineOverlay> _overlays = const [];

  /// Read-only view of the current chart data.
  ///
  /// Use [setData], [updateLast], [append], [prependHistory], or [clearData]
  /// to mutate data and notify chart listeners.
  List<KLineData> get data => _dataView;

  set data(List<KLineData> value) => setData(value, resetView: false);

  List<KLineOverlay> get overlays => _overlays;

  set overlays(List<KLineOverlay> value) => setOverlays(value);

  KLineDataChange? _lastDataChange;

  KLineDataChange? get lastDataChange => _lastDataChange;

  int _dataVersion = 0;

  int get dataVersion => _dataVersion;

  int _overlayVersion = 0;

  int get overlayVersion => _overlayVersion;

  void setData(List<KLineData> value, {bool resetView = true}) {
    final previousLength = _data.length;
    _replaceData(value);
    _notifyDataChanged(KLineDataChange(
      type: KLineDataChangeType.setData,
      previousLength: previousLength,
      newLength: _data.length,
      resetView: resetView,
    ));
  }

  void updateLast(KLineData value) {
    if (_data.isEmpty) {
      append(value);
      return;
    }

    final previousLength = _data.length;
    _data[_data.length - 1] = value;
    _notifyDataChanged(KLineDataChange(
      type: KLineDataChangeType.updateLast,
      previousLength: previousLength,
      newLength: _data.length,
    ));
  }

  void append(KLineData value) {
    final previousLength = _data.length;
    _data.add(value);
    _notifyDataChanged(KLineDataChange(
      type: KLineDataChangeType.append,
      previousLength: previousLength,
      newLength: _data.length,
      addedCount: 1,
    ));
  }

  void prependHistory(List<KLineData> values) {
    if (values.isEmpty) return;

    final previousLength = _data.length;
    _data.insertAll(0, values);
    _notifyDataChanged(KLineDataChange(
      type: KLineDataChangeType.prependHistory,
      previousLength: previousLength,
      newLength: _data.length,
      addedCount: values.length,
    ));
  }

  void clearData() {
    final previousLength = _data.length;
    _replaceData(const []);
    _notifyDataChanged(KLineDataChange(
      type: KLineDataChangeType.clear,
      previousLength: previousLength,
      newLength: 0,
    ));
  }

  void _notifyDataChanged(KLineDataChange change) {
    _lastDataChange = change;
    _dataVersion += 1;
    notifyListeners();
  }

  void _replaceData(Iterable<KLineData> value) {
    _data = List<KLineData>.of(value);
    _dataView = UnmodifiableListView<KLineData>(_data);
  }

  void setOverlays(List<KLineOverlay> value) {
    _overlays = List<KLineOverlay>.unmodifiable(value);
    _overlayVersion += 1;
    notifyListeners();
  }

  void clearOverlays() {
    if (_overlays.isEmpty) return;
    setOverlays(const []);
  }

  KLineChartStyle chartStyle = const KLineChartStyle();
  KLineCandleStyle candleStyle = const KLineCandleStyle();
  KLineVolumeStyle volumeStyle = const KLineVolumeStyle();
  KLineCrosshairStyle crosshairStyle = const KLineCrosshairStyle();
  KLineInfoStyle infoStyle = const KLineInfoStyle();
  KLineOverlayStyle overlayStyle = const KLineOverlayStyle();

  /// Formats price values such as open, high, low, close, rulers, and markers.
  KLineNumberFormatter? priceFormatter;

  /// Formats volume values such as candle volume and volume rulers.
  KLineNumberFormatter? volumeFormatter;

  /// Formats indicator values such as MA, MACD, RSI, KDJ, WR, and OBV.
  KLineIndicatorFormatter? indicatorFormatter;

  /// Formats bottom time axis labels.
  KLineTimeFormatter? timeFormatter;

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

  /// Empty candle slots shown after the latest data item when aligned to the end.
  double trailingBlankItemCount = 5;

  /// Maximum empty candle slots that can be revealed after the latest data item.
  double maxTrailingBlankItemCount = 20;

  /// Minimum real data items kept visible when scrolled to the trailing blank edge.
  double minTrailingVisibleItemCount = 4;

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

  /// Maximum price ticks drawn on the main price axis.
  int priceAxisMaxTickCount = 5;

  /// Minimum vertical spacing between adjacent price axis labels.
  double priceAxisMinTickSpacing = 28.0;

  /// Whether to draw the bottom time axis.
  bool showTimeAxis = false;

  /// Height reserved for the bottom time axis when enabled.
  double timeAxisHeight = 18.0;

  /// Minimum horizontal spacing between adjacent time axis labels.
  double timeAxisMinLabelSpacing = 64.0;

  bool showTimeChart = false;

  // info
  /// set null to fix text's width
  double? infoWidgetMaxWidth = 130;
  EdgeInsets infoWidgetMargin = const EdgeInsets.only(left: 8, top: 10);
  EdgeInsets infoWidgetPadding = const EdgeInsets.all(4);
  double infoWidgetBorderRadius = 4;
  Border infoWidgetBorder =
      Border.all(color: Colors.blueGrey.withAlpha(128), width: 0.5);

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
    if (type == IndicatorType.kdj) {
      return kdjPeriods;
    } else if (type == IndicatorType.macd) {
      return macdPeriods;
    } else if (type == IndicatorType.rsi) {
      return rsiPeriods;
    } else if (type == IndicatorType.wr) {
      return wrPeriods;
    } else if (type == IndicatorType.obv) {
      return [0];
    }
    return [];
  }

  List<Color> indicatorColors = [Colors.orange, Colors.purple, Colors.blue];

  String formatPrice(double value) {
    return priceFormatter?.call(value) ?? value.toStringAsFixed(2);
  }

  String formatCurrentPrice(double value) {
    return priceFormatter?.call(value) ?? value.toString();
  }

  String formatVolume(double value) {
    return volumeFormatter?.call(value) ?? _formatCompactVolume(value);
  }

  String formatIndicator(double value, IndicatorType type, {int? period}) {
    return indicatorFormatter?.call(value, type, period) ??
        value.toStringAsFixed(2);
  }

  String formatTime(DateTime time, KLineTimeLabelGranularity granularity) {
    return timeFormatter?.call(time, granularity) ??
        KLineAxis.defaultTimeLabel(time, granularity);
  }

  static String _formatCompactVolume(double value) {
    final absValue = value.abs();
    if (absValue >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (absValue >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (absValue >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  double itemWidthFor(double totalWidth) {
    double spacing = this.spacing;
    double itemCount = this.itemCount;
    // item width = total width / item count - spacing
    double itemW = totalWidth / itemCount - spacing;
    itemWidth = itemW;
    return itemW;
  }

  static double getItemWidth(
    double totalWidth, {
    KLineController? controller,
  }) {
    return (controller ?? KLineController.shared).itemWidthFor(totalWidth);
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
    double trailingBlankItemCount = 0,
    double minTrailingVisibleItemCount = 3,
  }) {
    if (dataLength <= 0 || itemCount <= 0 || itemExtent <= 0) {
      return 0.0;
    }

    final rawBeginIndex = offset / itemExtent;
    if (rawBeginIndex.isNaN || rawBeginIndex.isInfinite) {
      return 0.0;
    }

    final maxBeginIndex = maxBeginIndexFor(
      dataLength: dataLength,
      itemCount: itemCount,
      trailingBlankItemCount: trailingBlankItemCount,
      minTrailingVisibleItemCount: minTrailingVisibleItemCount,
    );
    return rawBeginIndex.clamp(0.0, maxBeginIndex).toDouble();
  }

  static double maxBeginIndexFor({
    required int dataLength,
    required double itemCount,
    double trailingBlankItemCount = 0,
    double minTrailingVisibleItemCount = 3,
  }) {
    if (dataLength <= 0 || itemCount <= 0) {
      return 0.0;
    }

    final effectiveTrailingBlankItemCount = effectiveTrailingBlankItemCountFor(
      itemCount: itemCount,
      trailingBlankItemCount: trailingBlankItemCount,
      minTrailingVisibleItemCount: minTrailingVisibleItemCount,
    );
    return max(0.0, dataLength - itemCount + effectiveTrailingBlankItemCount);
  }

  static double effectiveTrailingBlankItemCountFor({
    required double itemCount,
    required double trailingBlankItemCount,
    required double minTrailingVisibleItemCount,
  }) {
    if (itemCount <= 0 || trailingBlankItemCount <= 0) {
      return 0.0;
    }

    final visibleItemFloor =
        minTrailingVisibleItemCount.clamp(1.0, itemCount).toDouble();
    final maxTrailingBlankItemCount = max(0.0, itemCount - visibleItemFloor);
    return trailingBlankItemCount
        .clamp(0.0, maxTrailingBlankItemCount)
        .toDouble();
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
    double trailingBlankItemCount = 0,
    double minTrailingVisibleItemCount = 3,
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
    final maxBeginIndex = maxBeginIndexFor(
      dataLength: dataLength,
      itemCount: nextItemCount,
      trailingBlankItemCount: trailingBlankItemCount,
      minTrailingVisibleItemCount: minTrailingVisibleItemCount,
    );

    return KLineZoomResult(
      beginIndex: rawBeginIndex.clamp(0.0, maxBeginIndex).toDouble(),
      itemCount: nextItemCount,
    );
  }

  KLineController();

  static final KLineController shared = KLineController();
}
