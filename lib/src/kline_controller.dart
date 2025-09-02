import 'dart:math';
import 'package:flutter/material.dart';
import './kline_data.dart';


enum IndicatorType {
  // main
  ma(name: "MA"),
  ema(name: "EMA"),
  boll(name: "BOLL"),
  // sar(name: 'SAR'),

  // sub
  vol(name: "VOL", isLine: false),
  maVol(name: "MAVOL"), // same as ma, use for volume's ma
  // macd(name: "MACD", isLine: false),
  kdj(name: "KDJ"),
  // rsi(name: "RSI"),
  wr(name: "WR"),
  obv(name: 'OBV');

  bool get isMain => index < IndicatorType.vol.index;

  final String name;
  final bool isLine; // just need draw a line
  const IndicatorType({required this.name, this.isLine = true});

  factory IndicatorType.fromName(String name) {
    if (!IndicatorType.values.map((e) => e.name).toList().contains(name)) {
      return IndicatorType.ma;
    }
    return IndicatorType.values.firstWhere((element) => element.name == name);
  }
}

class LongPressOffset extends ValueNotifier<Offset> {

  LongPressOffset(Offset value) : super(value);

  update(Offset offset) {
    value = offset;
  }
}

class KLineController {

  List<KLineData> data = [];

  bool isDebug = false;
  Color randomColor = Color.fromARGB(100, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
  void drawDebugRect(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()
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
  Border infoWidgetBorder = Border.all(color: Colors.blueGrey.withValues(alpha: 0.5), width: 0.5);

  var longPressOffset = LongPressOffset(Offset.zero);

  // /// main indicator information top margin
  // double mainIndicatorInfoTopMargin = 5.0;

  /// spacing between indicator
  double indicatorSpacing = 10.0;
  /// sub indicator height
  double subIndicatorHeight = 50.0;
  /// indicator information height
  double indicatorInfoHeight = 15.0;

  // 主指标的展示高度 = 总高度 - 上下间距(klineMargin.vertical) - 副指标的高度 - 指标之间的间距高度
  // 副指标的展示高度 = 副指标的高度 - 指标信息的高度


  /// show main indicator
  List<IndicatorType> showMainIndicators = [IndicatorType.ma];
  /// show sub indicator
  List<IndicatorType> showSubIndicators = [IndicatorType.vol, IndicatorType.kdj];

  /// BOLL Calculating Period (N)
  int bollPeriod = 21;
  /// BOLL Bandwidth (P)
  int bollBandwidth = 2;

  /// VOL MA periods
  List<int> volMaPeriods = [7, 14];

  /// KDJ periods
  List<int> kdjPeriods = [9,3,3];
  /// WR periods
  List<int> wrPeriods = [7,14];

  List<int> currentPeriods(IndicatorType type) {
    KLineController config = KLineController.shared;
    if (type == IndicatorType.kdj) {
      return config.kdjPeriods;
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

  // singleton
  KLineController._internal();
  static final KLineController shared = KLineController._internal();
  factory KLineController() => shared;
}