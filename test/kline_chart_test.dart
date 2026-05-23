import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_chart/kline_chart.dart';
import 'package:kline_chart/src/indicators/indicator_data_cache.dart';
import 'package:kline_chart/src/indicators/indicator_data_handler.dart';
import 'package:kline_chart/src/indicators/indicator_line_painter.dart';
import 'package:kline_chart/src/indicators/macd_painter.dart';
import 'package:kline_chart/src/indicators/indicator_info_painter.dart';
import 'package:kline_chart/src/indicators/sar_painter.dart';
import 'package:kline_chart/src/indicators/vol_painter.dart';
import 'package:kline_chart/src/kline_info_widget.dart';
import 'package:kline_chart/src/kline_long_press_widget.dart';
import 'package:kline_chart/src/kline_painter.dart';

void main() {
  setUp(() {
    KLineController.shared.data = [];
    KLineController.shared.itemCount = 30;
    KLineController.shared.spacing = 2.0;
    KLineController.shared.itemWidth = 0.0;
    KLineController.shared.klineMargin = const EdgeInsets.all(0);
    KLineController.shared.mainIndicatorInfoMargin = 5.0;
    KLineController.shared.subIndicatorInfoMargin = 5.0;
    KLineController.shared.indicatorSpacing = 10.0;
    KLineController.shared.subIndicatorHeight = 50.0;
    KLineController.shared.indicatorInfoHeight = 15.0;
    KLineController.shared.showMainIndicators = [IndicatorType.ma];
    KLineController.shared.showSubIndicators = [
      IndicatorType.vol,
      IndicatorType.kdj
    ];
    KLineController.shared.chartStyle = const KLineChartStyle();
    KLineController.shared.candleStyle = const KLineCandleStyle();
    KLineController.shared.volumeStyle = const KLineVolumeStyle();
    KLineController.shared.crosshairStyle = const KLineCrosshairStyle();
    KLineController.shared.infoStyle = const KLineInfoStyle();
    KLineController.shared.sarStart = 0.02;
    KLineController.shared.sarIncrement = 0.02;
    KLineController.shared.sarMax = 0.2;
    KLineController.shared.sarColor = Colors.orange;
    KLineController.shared.showTimeChart = false;
    KLineController.shared.longPressOffset.update(Offset.zero);
  });

  group('KLineController.beginIndexForScrollOffset', () {
    test('clamps trailing overscroll to the last fully visible candle', () {
      const dataLength = 100;
      const itemCount = 30.0;
      const itemExtent = 12.0;
      const maxBeginIndex = dataLength - itemCount;
      const trailingOverscrollOffset = (maxBeginIndex + 0.75) * itemExtent;

      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: trailingOverscrollOffset,
        itemExtent: itemExtent,
        itemCount: itemCount,
        dataLength: dataLength,
      );

      expect(beginIndex, maxBeginIndex);
    });

    test('clamps leading overscroll to zero', () {
      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: -18,
        itemExtent: 12,
        itemCount: 30,
        dataLength: 100,
      );

      expect(beginIndex, 0);
    });

    test('returns zero when the data is shorter than the viewport', () {
      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: 120,
        itemExtent: 12,
        itemCount: 30,
        dataLength: 20,
      );

      expect(beginIndex, 0);
    });
  });

  group('KLineController.zoomForScale', () {
    test('keeps the focal candle under the gesture focal point', () {
      final result = KLineController.zoomForScale(
        startBeginIndex: 10,
        startItemCount: 30,
        scale: 2,
        startFocalDx: 100,
        currentFocalDx: 100,
        viewportWidth: 300,
        dataLength: 100,
        minItemCount: 7,
        maxItemCount: 39,
      );

      final focalIndexAfterZoom =
          result.beginIndex + result.itemCount * 100 / 300;

      expect(result.itemCount, 15);
      expect(focalIndexAfterZoom, closeTo(20, 0.000001));
    });

    test('tracks the focal point when it moves during a pinch gesture', () {
      final result = KLineController.zoomForScale(
        startBeginIndex: 10,
        startItemCount: 30,
        scale: 2,
        startFocalDx: 100,
        currentFocalDx: 150,
        viewportWidth: 300,
        dataLength: 100,
        minItemCount: 7,
        maxItemCount: 39,
      );

      final focalIndexAfterZoom =
          result.beginIndex + result.itemCount * 150 / 300;

      expect(focalIndexAfterZoom, closeTo(20, 0.000001));
    });

    test('clamps zoom begin index at the data edges', () {
      final result = KLineController.zoomForScale(
        startBeginIndex: 80,
        startItemCount: 30,
        scale: 2,
        startFocalDx: 300,
        currentFocalDx: 300,
        viewportWidth: 300,
        dataLength: 100,
        minItemCount: 7,
        maxItemCount: 39,
      );

      expect(result.itemCount, 15);
      expect(result.beginIndex, 85);
    });
  });

  group('KLinePainter.shouldRepaint', () {
    test('repaints when begin index changes', () {
      final oldPainter = KLinePainter(const [], 10);
      final newPainter = KLinePainter(const [], 11);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('does not repaint the full chart when long press moves', () {
      final painter = KLinePainter(const [], 10);
      bool didRepaint = false;
      void listener() {
        didRepaint = true;
      }

      painter.addListener(listener);
      KLineController.shared.longPressOffset.update(const Offset(12, 24));
      painter.removeListener(listener);

      expect(didRepaint, isFalse);
    });

    test('repaints when SAR color changes', () {
      KLineController.shared.sarColor = Colors.orange;
      final oldPainter = KLinePainter(const [], 10);

      KLineController.shared.sarColor = Colors.cyan;
      final newPainter = KLinePainter(const [], 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints when chart style changes', () {
      KLineController.shared.chartStyle = const KLineChartStyle(
        backgroundColor: Color(0xff101820),
      );
      final oldPainter = KLinePainter(const [], 10);

      KLineController.shared.chartStyle = const KLineChartStyle(
        backgroundColor: Color(0xff202830),
      );
      final newPainter = KLinePainter(const [], 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('uses chart and candle styles while painting the main chart',
        () async {
      KLineController.shared.itemCount = 1;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.chartStyle = const KLineChartStyle(
        backgroundColor: Color(0xff102030),
        gridLineColor: Color(0xff405060),
        gridLineWidth: 3,
      );
      KLineController.shared.candleStyle = const KLineCandleStyle(
        riseColor: Color(0xff00aa55),
        fallColor: Color(0xffcc3344),
        riseWickColor: Color(0xff00aa55),
        fallWickColor: Color(0xffcc3344),
        wickLineWidth: 1,
      );

      final data = [
        KLineData(
          open: 10,
          high: 11,
          low: 9,
          close: 10.5,
          volume: 1,
          time: 0,
        )
      ];
      final bytes = await _paintToBytes(
        Size(100, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 13, 87, 100), const Color(0xff102030));
      expect(_pixelAt(bytes, 20, 13, 100), const Color(0xff405060));
      expect(_pixelAt(bytes, 50, 35, 100), const Color(0xff00aa55));
    });

    testWidgets('renders fractional trailing zoom window without overflow',
        (tester) async {
      final data = _buildKLineData(100);
      const itemCount = 17.647058823529413;
      KLineController.shared.itemCount = itemCount;

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 300,
          height: 240,
          child: CustomPaint(
            painter: KLinePainter(data, data.length - itemCount),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('KLineView stability', () {
    testWidgets('can be disposed before scroll controller is initialized',
        (tester) async {
      KLineController.shared.data = [];

      await tester.pumpWidget(MaterialApp(home: KLineView()));
      await tester.pumpWidget(const SizedBox.shrink());

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders when data is shorter than the visible item count',
        (tester) async {
      KLineController.shared.data = _buildKLineData(5);

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders flat price and zero volume data without invalid canvas values',
        (tester) async {
      KLineController.shared.data = _buildKLineData(40, flat: true);

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders time chart when data starts at the first item',
        (tester) async {
      KLineController.shared.data = _buildKLineData(5);
      KLineController.shared.showTimeChart = true;

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('IndicatorDataHandler visible windows', () {
    test('clamps calculations when item count exceeds data length', () {
      final data = _buildKLineData(5);

      expect(
        () => IndicatorDataHandler.ema(data, [2], 0),
        returnsNormally,
      );
      expect(
        () => IndicatorDataHandler.boll(data, 2, 2, 0),
        returnsNormally,
      );
      expect(
        () => IndicatorDataHandler.wr(data, [2], 0),
        returnsNormally,
      );
    });

    test('calculates visible MA values without changing window alignment', () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([1, 2, 3, 4, 5, 6, 7, 8]);

      final result = IndicatorDataHandler.ma(data, [3], 3);

      expect(result.data.single, [2, 3, 4, 5, 6, 7]);
      expect(result.maxValue, 7);
      expect(result.minValue, 2);
    });

    test('calculates BOLL values and bounds with existing sentinel behavior',
        () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([1, 2, 3, 4, 5]);

      final result = IndicatorDataHandler.boll(data, 3, 2, 0);
      final mb = result.data[0];
      final up = result.data[1];
      final dn = result.data[2];

      expect(mb, [-1, -1, 2, 3, 4]);
      expect(up[0], -1);
      expect(up[1], -1);
      expect(up[2], closeTo(3.632993161855452, 0.000001));
      expect(up[3], closeTo(4.6329931618554525, 0.000001));
      expect(up[4], closeTo(5.6329931618554525, 0.000001));
      expect(dn[0], -1);
      expect(dn[1], -1);
      expect(dn[2], closeTo(0.367006838144548, 0.000001));
      expect(dn[3], closeTo(1.367006838144548, 0.000001));
      expect(dn[4], closeTo(2.367006838144548, 0.000001));
      expect(result.maxValue, closeTo(5.6329931618554525, 0.000001));
      expect(result.minValue, -1);
    });

    test('calculates KDJ values without changing the visible result', () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15]);

      final result = IndicatorDataHandler.kdj(data, [3, 3, 3], 0);
      final k = result.data[0];
      final d = result.data[1];
      final j = result.data[2];

      expect(k[0], closeTo(83.33333333333333, 0.000001));
      expect(d[0], closeTo(61.11111111111111, 0.000001));
      expect(j[0], closeTo(127.77777777777777, 0.000001));
      expect(k.last, closeTo(69.87654320987653, 0.000001));
      expect(d.last, closeTo(68.72427983539094, 0.000001));
      expect(j.last, closeTo(72.18106995884772, 0.000001));
      expect(result.maxValue, closeTo(127.77777777777777, 0.000001));
      expect(result.minValue, closeTo(61.11111111111111, 0.000001));
    });

    test('calculates WR values without changing the visible result', () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13]);

      final result = IndicatorDataHandler.wr(data, [3], 0);

      expect(result.data.single[0], closeTo(50, 0.000001));
      expect(result.data.single[1], closeTo(25, 0.000001));
      expect(result.data.single[2], closeTo(50, 0.000001));
      expect(result.data.single[3], closeTo(16.666666666666664, 0.000001));
      expect(result.data.single[4], closeTo(40, 0.000001));
      expect(result.maxValue, closeTo(50, 0.000001));
      expect(result.minValue, closeTo(16.666666666666664, 0.000001));
    });
  });

  group('IndicatorDataHandler.rsi', () {
    test(
        'calculates Wilder-smoothed RSI values for the visible close-price window',
        () {
      KLineController.shared.itemCount = 6;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15]);

      final result = IndicatorDataHandler.rsi(data, [3], 0);
      final rsi = result.data.single;

      expect(rsi[0], -1);
      expect(rsi[1], -1);
      expect(rsi[2], -1);
      expect(rsi[3], closeTo(83.333333, 0.000001));
      expect(rsi[4], closeTo(66.666667, 0.000001));
      expect(rsi[5], closeTo(79.166667, 0.000001));
    });

    test('uses rounded visible RSI bounds for rendering', () {
      KLineController.shared.itemCount = 6;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15]);

      final result = IndicatorDataHandler.rsi(data, [3], 0);

      expect(result.maxValue, 84);
      expect(result.minValue, 66);
    });

    test(
        'falls back to the full RSI scale before the first valid value is visible',
        () {
      KLineController.shared.itemCount = 3;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15]);

      final result = IndicatorDataHandler.rsi(data, [6], 0);

      expect(result.data.single, [-1, -1, -1]);
      expect(result.maxValue, 100);
      expect(result.minValue, 0);
    });
  });

  group('KLineIndicatorDataCache', () {
    test('reuses the same result for repeated indicator requests', () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([1, 2, 3, 4, 5, 6, 7, 8]);
      final cache = KLineIndicatorDataCache(data, 0);

      final first = cache.result(IndicatorType.ma);
      final second = cache.result(IndicatorType.ma);
      final expected = IndicatorDataHandler.ma(data, const [7, 30], 0);

      expect(second, same(first));
      expect(first.data, expected.data);
      expect(first.maxValue, expected.maxValue);
      expect(first.minValue, expected.minValue);
    });

    test('uses configured volume MA periods', () {
      KLineController.shared.itemCount = 5;
      KLineController.shared.volMaPeriods = [2];
      final data = _buildKLineDataFromCloses([1, 2, 3, 4, 5]);
      final cache = KLineIndicatorDataCache(data, 0);

      final result = cache.result(IndicatorType.maVol);
      final expected = IndicatorDataHandler.ma(data, [2], 0, isVol: true);

      expect(result.data, expected.data);
      expect(result.maxValue, expected.maxValue);
      expect(result.minValue, expected.minValue);
    });
  });

  group('IndicatorDataHandler.macd', () {
    test('calculates Binance-style MACD values for the visible window', () {
      KLineController.shared.itemCount = 10;
      final data =
          _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15, 16, 14, 17, 18]);

      final result = IndicatorDataHandler.macd(data, [3, 6, 3], 0);
      final macdLine = result.data[0];
      final signalLine = result.data[1];
      final histogram = result.data[2];

      expect(macdLine.sublist(0, 5), [-1, -1, -1, -1, -1]);
      expect(signalLine.sublist(0, 5), [-1, -1, -1, -1, -1]);
      expect(histogram.sublist(0, 5), [-1, -1, -1, -1, -1]);
      expect(macdLine[5], closeTo(1.375, 0.000001));
      expect(signalLine[5], closeTo(1.375, 0.000001));
      expect(histogram[5], closeTo(0, 0.000001));
      expect(macdLine[7], closeTo(0.825893, 0.000001));
      expect(signalLine[7], closeTo(1.116071, 0.000001));
      expect(histogram[7], closeTo(-0.290179, 0.000001));
      expect(macdLine[9], closeTo(1.294301, 0.000001));
      expect(signalLine[9], closeTo(1.209252, 0.000001));
      expect(histogram[9], closeTo(0.085049, 0.000001));
      expect(result.maxValue, closeTo(1.4375, 0.000001));
      expect(result.minValue, closeTo(-0.290179, 0.000001));
    });

    test('classifies MACD histogram bars as solid or hollow', () {
      expect(MACDPainter.isSolidHistogramBar(0.3, 0.2), isTrue);
      expect(MACDPainter.isSolidHistogramBar(0.2, 0.3), isFalse);
      expect(MACDPainter.isSolidHistogramBar(-0.3, -0.2), isTrue);
      expect(MACDPainter.isSolidHistogramBar(-0.2, -0.3), isFalse);
    });
  });

  group('IndicatorDataHandler.sar', () {
    test('calculates parabolic SAR values with default acceleration factors',
        () {
      KLineController.shared.itemCount = 10;
      final data = _buildKLineDataFromOhlc([
        [9, 10, 8, 9],
        [10, 11, 9, 10],
        [11, 12, 10, 11],
        [12, 13, 11, 12],
        [13, 14, 12, 13],
        [14, 15, 13, 14],
        [13, 14, 10, 11],
        [10, 13, 9, 10],
        [9, 12, 8, 9],
        [8, 11, 7, 8],
      ]);

      final result = IndicatorDataHandler.sar(data, 0);
      final sar = result.data.single;

      expect(sar[0], -1);
      expect(sar[1], closeTo(8, 0.000001));
      expect(sar[2], closeTo(8, 0.000001));
      expect(sar[3], closeTo(8.16, 0.000001));
      expect(sar[4], closeTo(8.4504, 0.000001));
      expect(sar[5], closeTo(8.894368, 0.000001));
      expect(sar[6], closeTo(9.5049312, 0.000001));
      expect(sar[7], closeTo(15, 0.000001));
      expect(sar[8], closeTo(14.88, 0.000001));
      expect(sar[9], closeTo(14.6048, 0.000001));
      expect(result.maxValue, closeTo(15, 0.000001));
      expect(result.minValue, closeTo(8, 0.000001));
    });
  });

  group('MACD sub indicator rendering', () {
    testWidgets('renders MACD as histogram with signal lines', (tester) async {
      KLineController.shared.data = _buildKLineData(40);
      KLineController.shared.showSubIndicators = [IndicatorType.macd];

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('RSI sub indicator rendering', () {
    testWidgets('renders RSI as a line sub indicator', (tester) async {
      KLineController.shared.data = _buildKLineData(40);
      KLineController.shared.showSubIndicators = [IndicatorType.rsi];

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('SAR main indicator rendering', () {
    testWidgets('renders SAR as a main chart indicator', (tester) async {
      KLineController.shared.data = _buildKLineData(40);
      KLineController.shared.showMainIndicators = [IndicatorType.sar];

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('uses the configured SAR point color', () async {
      KLineController.shared.itemCount = 10;
      KLineController.shared.sarColor = Colors.cyan;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      SARPainter([
        [10]
      ]).paint(
        canvas,
        const Size(100, 100),
        80,
        0,
        10,
        0,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      picture.dispose();
      image.dispose();

      expect(_pixelAt(data!, 4, 20, 100), const Color(0xff00bcd4));
    });
  });

  group('Phase one visual customization', () {
    test('uses configured volume colors for volume bars', () async {
      KLineController.shared.itemCount = 1;
      KLineController.shared.spacing = 0;
      KLineController.shared.subIndicatorHeight = 100;
      KLineController.shared.showSubIndicators = [IndicatorType.vol];
      KLineController.shared.volumeStyle = const KLineVolumeStyle(
        riseColor: Color(0xff22cc88),
        fallColor: Color(0xffdd4455),
      );

      final data = [
        KLineData(
          open: 10,
          high: 11,
          low: 9,
          close: 10.5,
          volume: 1,
          time: 0,
        )
      ];
      final bytes = await _paintToBytes(
        Size(100, 100),
        (canvas, size) =>
            VolPainter(data, 0).paint(canvas, size, 1, 0, showInfo: false),
      );

      expect(_pixelAt(bytes, 50, 50, 100), const Color(0xff22cc88));
    });

    test('uses configured crosshair style', () async {
      KLineController.shared.crosshairStyle = const KLineCrosshairStyle(
        color: Color(0xff8866ff),
        strokeWidth: 3,
      );

      final bytes = await _paintToBytes(
        Size(100, 100),
        (canvas, size) => KLineLongPressPainter(
          _buildKLineData(1),
          0,
          const Offset(10, 20),
        ).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 10, 50, 100), const Color(0xff8866ff));
    });

    testWidgets('uses configured long press info background', (tester) async {
      final data = _buildKLineData(1);
      KLineController.shared.itemWidth = 10;
      KLineController.shared.spacing = 0;
      KLineController.shared.longPressOffset.update(const Offset(5, 20));
      KLineController.shared.infoStyle = const KLineInfoStyle(
        backgroundColor: Color(0xff182430),
        textStyle: TextStyle(
          color: Color(0xffddeeff),
          fontSize: 12,
          height: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KlineInfoWidget(data, 0),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, const Color(0xff182430));
    });

    test('repaints long press info when info style changes', () {
      final data = _buildKLineData(1).first;
      final oldPainter = KLineLongPressInfoPainter(
        data,
        0,
        const Offset(5, 20),
        const KLineInfoStyle(
          backgroundColor: Color(0xff182430),
        ),
      );
      final newPainter = KLineLongPressInfoPainter(
        data,
        0,
        const Offset(5, 20),
        const KLineInfoStyle(
          backgroundColor: Color(0xff283440),
        ),
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });
  });

  group('Long press indicator', () {
    testWidgets('snaps the vertical line to the touched candle center',
        (tester) async {
      final data = _buildKLineData(20);
      KLineController.shared.itemWidth = 8;
      KLineController.shared.spacing = 2;
      KLineController.shared.longPressOffset.update(const Offset(34, 80));

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 160,
          child: KlineLongPressWidget(data, 10),
        ),
      ));

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.foregroundPainter as KLineLongPressPainter;

      expect(painter.longPressOffset.dx, 34);
      expect(painter.longPressOffset.dy, 80);
    });

    testWidgets('shows info for the same candle selected by the vertical line',
        (tester) async {
      final data = _buildKLineData(20);
      KLineController.shared.itemWidth = 8;
      KLineController.shared.spacing = 2;
      KLineController.shared.longPressOffset.update(const Offset(34, 80));

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: KlineInfoWidget(data, 10),
      ));

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter as KLineLongPressInfoPainter;

      expect(painter.klineData, same(data[13]));
    });

    test('maps long press x to the selected visible indicator index', () {
      const itemWidth = 8.0;
      const spacing = 2.0;
      final selectedCenterX = KLineController.itemCenterXForDataIndex(
        dataIndex: 13,
        beginIndex: 10,
        itemWidth: itemWidth,
        spacing: spacing,
      );

      final selectedIndex = KLinePainter.selectedVisibleIndexForLongPress(
        longPressOffset: Offset(selectedCenterX, 80),
        beginIdx: 10,
        itemWidth: itemWidth,
        spacing: spacing,
        dataLength: 20,
      );

      expect(selectedIndex, 3);
    });

    test('uses the selected line indicator value while long press is active',
        () {
      final valueText = IndicatorLinePainter.infoValueText(
        IndicatorType.rsi,
        [10, 20, 30],
        1,
      );

      expect(valueText, '20.00');
    });

    test('uses the touched candle MA value when MA data has a leading point',
        () {
      KLineController.shared.itemCount = 5;
      const beginIdx = 3.0;
      const itemWidth = 8.0;
      const spacing = 2.0;
      final data = _buildKLineDataFromCloses([1, 2, 3, 4, 5, 6, 7, 8]);
      final result = IndicatorDataHandler.ma(data, [3], beginIdx);
      final selectedCenterX = KLineController.itemCenterXForDataIndex(
        dataIndex: 5,
        beginIndex: beginIdx,
        itemWidth: itemWidth,
        spacing: spacing,
      );
      final selectedIndex = KLinePainter.selectedVisibleIndexForLongPress(
        longPressOffset: Offset(selectedCenterX, 80),
        beginIdx: beginIdx,
        itemWidth: itemWidth,
        spacing: spacing,
        dataLength: data.length,
      );

      expect(selectedIndex, 2);
      expect(
        IndicatorLinePainter.infoValueText(
          IndicatorType.ma,
          result.data.single,
          selectedIndex,
        ),
        '5.00',
      );
    });

    test('shows NaN when the selected line indicator value is missing', () {
      expect(
        IndicatorLinePainter.infoValueText(IndicatorType.rsi, [-1, 20], 0),
        'NaN',
      );
      expect(
        IndicatorLinePainter.infoValueText(IndicatorType.rsi, [20], 3),
        'NaN',
      );
    });

    test('keeps negative KDJ values displayable', () {
      final valueText = IndicatorLinePainter.infoValueText(
        IndicatorType.kdj,
        [-1.25],
        0,
      );

      expect(valueText, '-1.25');
    });

    test('shows NaN for missing MACD values and keeps real negatives', () {
      expect(MACDPainter.infoValueText([-1, -0.25], 0), 'NaN');
      expect(MACDPainter.infoValueText([-1, -0.25], 1), '-0.25');
      expect(MACDPainter.infoValueText([-1, -0.25], 4), 'NaN');
    });

    test('shows the selected SAR value without a period label', () {
      final infoList = IndicatorLinePainter.indicatorInfoList(
        IndicatorType.sar,
        [
          [-1, 8.25]
        ],
        [0],
        1,
      );

      expect(infoList, ['SAR: 8.25']);
    });

    test('repaints the indicator info overlay when long press moves', () {
      final painter = KLineIndicatorInfoPainter(_buildKLineData(20), 10);
      bool didRepaint = false;
      void listener() {
        didRepaint = true;
      }

      painter.addListener(listener);
      KLineController.shared.longPressOffset.update(const Offset(34, 80));
      painter.removeListener(listener);

      expect(didRepaint, isTrue);
    });

    test('repaints the indicator info overlay when indicators change', () {
      final data = _buildKLineData(20);
      KLineController.shared.showSubIndicators = [IndicatorType.vol];
      final oldPainter = KLineIndicatorInfoPainter(data, 10);

      KLineController.shared.showSubIndicators = [IndicatorType.macd];
      final newPainter = KLineIndicatorInfoPainter(data, 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints the indicator info overlay when periods change', () {
      final data = _buildKLineData(20);
      KLineController.shared.showSubIndicators = [IndicatorType.rsi];
      KLineController.shared.rsiPeriods = [6, 12, 24];
      final oldPainter = KLineIndicatorInfoPainter(data, 10);

      KLineController.shared.rsiPeriods = [14, 28];
      final newPainter = KLineIndicatorInfoPainter(data, 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints the indicator info overlay when SAR parameters change', () {
      final data = _buildKLineData(20);
      KLineController.shared.showMainIndicators = [IndicatorType.sar];
      KLineController.shared.sarIncrement = 0.02;
      final oldPainter = KLineIndicatorInfoPainter(data, 10);

      KLineController.shared.sarIncrement = 0.04;
      final newPainter = KLineIndicatorInfoPainter(data, 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints the indicator info overlay when SAR color changes', () {
      final data = _buildKLineData(20);
      KLineController.shared.showMainIndicators = [IndicatorType.sar];
      KLineController.shared.sarColor = Colors.orange;
      final oldPainter = KLineIndicatorInfoPainter(data, 10);

      KLineController.shared.sarColor = Colors.cyan;
      final newPainter = KLineIndicatorInfoPainter(data, 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });
  });
}

List<KLineData> _buildKLineData(int count, {bool flat = false}) {
  return List.generate(count, (index) {
    final price = flat ? 10.0 : 10.0 + index;
    return KLineData(
      open: price,
      high: flat ? price : price + 1,
      low: flat ? price : price - 1,
      close: flat ? price : price + 0.5,
      volume: flat ? 0.0 : 100.0 + index,
      time: index,
    );
  });
}

List<KLineData> _buildKLineDataFromCloses(List<double> closes) {
  return List.generate(closes.length, (index) {
    final close = closes[index];
    return KLineData(
      open: close,
      high: close + 1,
      low: close - 1,
      close: close,
      volume: 100.0 + index,
      time: index,
    );
  });
}

List<KLineData> _buildKLineDataFromOhlc(List<List<double>> rows) {
  return List.generate(rows.length, (index) {
    final row = rows[index];
    return KLineData(
      open: row[0],
      high: row[1],
      low: row[2],
      close: row[3],
      volume: 100.0 + index,
      time: index,
    );
  });
}

Color _pixelAt(ByteData data, int x, int y, int width) {
  final offset = (y * width + x) * 4;
  return Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

Future<ByteData> _paintToBytes(
  Size size,
  void Function(Canvas canvas, Size size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  paint(canvas, size);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  picture.dispose();
  image.dispose();

  return data!;
}
