import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_chart/kline_chart.dart';
import 'package:kline_chart/src/indicators/indicator_data_handler.dart';
import 'package:kline_chart/src/kline_info_widget.dart';
import 'package:kline_chart/src/kline_long_press_widget.dart';
import 'package:kline_chart/src/kline_painter.dart';

void main() {
  setUp(() {
    KLineController.shared.data = [];
    KLineController.shared.itemCount = 30;
    KLineController.shared.spacing = 2.0;
    KLineController.shared.itemWidth = 0.0;
    KLineController.shared.showMainIndicators = [IndicatorType.ma];
    KLineController.shared.showSubIndicators = [
      IndicatorType.vol,
      IndicatorType.kdj
    ];
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
