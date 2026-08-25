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
import 'package:kline_chart/src/kline_axis.dart';
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
    KLineController.shared.overlayStyle = const KLineOverlayStyle();
    KLineController.shared.clearOverlays();
    KLineController.shared.sarStart = 0.02;
    KLineController.shared.sarIncrement = 0.02;
    KLineController.shared.sarMax = 0.2;
    KLineController.shared.sarColor = Colors.orange;
    KLineController.shared.trailingBlankItemCount = 0;
    KLineController.shared.maxTrailingBlankItemCount = 0;
    KLineController.shared.minTrailingVisibleItemCount = 3;
    KLineController.shared.priceFormatter = null;
    KLineController.shared.volumeFormatter = null;
    KLineController.shared.indicatorFormatter = null;
    KLineController.shared.timeFormatter = null;
    KLineController.shared.priceAxisMaxTickCount = 5;
    KLineController.shared.priceAxisMinTickSpacing = 28.0;
    KLineController.shared.showTimeAxis = false;
    KLineController.shared.timeAxisHeight = 18.0;
    KLineController.shared.timeAxisMinLabelSpacing = 64.0;
    KLineController.shared.showTimeChart = false;
    KLineController.shared.longPressOffset.update(Offset.zero);
  });

  group('KLineController number formatters', () {
    test('keeps default price volume and indicator formatting', () {
      expect(KLineController.shared.formatPrice(12.345), '12.35');
      expect(KLineController.shared.formatCurrentPrice(12.345), '12.345');
      expect(KLineController.shared.formatVolume(123.456), '123.46');
      expect(KLineController.shared.formatVolume(1234.567), '1.23K');
      expect(
        KLineController.shared.formatIndicator(
          12.345,
          IndicatorType.rsi,
          period: 6,
        ),
        '12.35',
      );
    });

    test('uses K M and B suffixes for default volume formatting', () {
      expect(KLineController.shared.formatVolume(999.999), '1000.00');
      expect(KLineController.shared.formatVolume(1000), '1.00K');
      expect(KLineController.shared.formatVolume(1250000), '1.25M');
      expect(KLineController.shared.formatVolume(2500000000), '2.50B');
    });

    test('uses separate custom formatters for price volume and indicators', () {
      KLineController.shared.priceFormatter = (value) => 'P$value';
      KLineController.shared.volumeFormatter = (value) => 'V$value';
      KLineController.shared.indicatorFormatter = (value, type, period) {
        return '${type.name}:${period ?? 0}:$value';
      };

      expect(KLineController.shared.formatPrice(12.3), 'P12.3');
      expect(KLineController.shared.formatCurrentPrice(12.3), 'P12.3');
      expect(KLineController.shared.formatVolume(45.6), 'V45.6');
      expect(
        KLineController.shared.formatIndicator(
          7.89,
          IndicatorType.macd,
          period: 12,
        ),
        'MACD:12:7.89',
      );
    });

    test('formats time labels and supports a custom time formatter', () {
      final time = DateTime(2024, 1, 2, 3, 4);

      expect(
        KLineController.shared.formatTime(
          time,
          KLineTimeLabelGranularity.time,
        ),
        '03:04',
      );

      KLineController.shared.timeFormatter = (time, granularity) {
        return '${granularity.name}:${time.year}';
      };

      expect(
        KLineController.shared.formatTime(
          time,
          KLineTimeLabelGranularity.month,
        ),
        'month:2024',
      );
    });
  });

  group('KLineData.fromJson', () {
    test('normalizes integer JSON numbers to the declared field types', () {
      final data = KLineData.fromJson({
        'open': 1,
        'high': 2,
        'low': 0,
        'close': 1,
        'volume': 3,
        'time': 4,
      });

      expect(data.open, 1.0);
      expect(data.high, 2.0);
      expect(data.low, 0.0);
      expect(data.close, 1.0);
      expect(data.volume, 3.0);
      expect(data.time, 4);
    });

    test('parses numeric strings and falls back for invalid values', () {
      final data = KLineData.fromJson({
        'open': '1.25',
        'high': '2.5',
        'low': 'invalid',
        'close': '1.75',
        'volume': '30.5',
        'time': '1710000000000',
      });

      expect(data.open, 1.25);
      expect(data.high, 2.5);
      expect(data.low, 0.0);
      expect(data.close, 1.75);
      expect(data.volume, 30.5);
      expect(data.time, 1710000000000);
    });
  });

  group('KLineAxis', () {
    test('generates nice price ticks within the visible price range', () {
      final ticks = KLineAxis.priceTicks(
        minValue: 101,
        maxValue: 199,
        top: 10,
        height: 200,
        maxTickCount: 5,
        minTickSpacing: 40,
      );

      expect(ticks.map((tick) => tick.value), [120, 140, 160, 180]);
      expect(ticks.first.y, closeTo(171.224489, 0.000001));
      expect(ticks.last.y, closeTo(48.775510, 0.000001));
    });

    test('returns a centered price tick when the visible range is flat', () {
      final ticks = KLineAxis.priceTicks(
        minValue: 10,
        maxValue: 10,
        top: 4,
        height: 80,
      );

      expect(ticks, hasLength(1));
      expect(ticks.single.value, 10);
      expect(ticks.single.y, 44);
    });

    test('selects time label granularity from the visible span', () {
      final start = DateTime(2024, 1, 1).millisecondsSinceEpoch;

      expect(
        KLineAxis.timeGranularityForSpan(
          start,
          start + const Duration(hours: 6).inMilliseconds,
        ),
        KLineTimeLabelGranularity.time,
      );
      expect(
        KLineAxis.timeGranularityForSpan(
          start,
          start + const Duration(days: 30).inMilliseconds,
        ),
        KLineTimeLabelGranularity.day,
      );
      expect(
        KLineAxis.timeGranularityForSpan(
          start,
          start + const Duration(days: 365).inMilliseconds,
        ),
        KLineTimeLabelGranularity.month,
      );
      expect(
        KLineAxis.timeGranularityForSpan(
          start,
          start + const Duration(days: 900).inMilliseconds,
        ),
        KLineTimeLabelGranularity.year,
      );
    });

    test('generates sparse time ticks aligned to visible candle centers', () {
      final start = DateTime(2024, 1, 1, 9, 30).millisecondsSinceEpoch;
      final times = List.generate(
        20,
        (index) => start + Duration(minutes: index).inMilliseconds,
      );

      final ticks = KLineAxis.timeTicks(
        times: times,
        beginIndex: 2.5,
        itemWidth: 8,
        spacing: 2,
        itemCount: 10,
        viewportWidth: 100,
        minLabelSpacing: 35,
      );

      expect(ticks.map((tick) => tick.dataIndex), [4, 8, 12]);
      expect(ticks.map((tick) => tick.x), [19, 59, 99]);
      expect(
        ticks.map((tick) => tick.granularity).toSet(),
        {KLineTimeLabelGranularity.time},
      );
    });

    test('generates time ticks from indexed access without requiring a copy',
        () {
      final start = DateTime(2024, 1, 1, 9, 30).millisecondsSinceEpoch;
      var accessCount = 0;

      final ticks = KLineAxis.timeTicksForIndexedData(
        dataLength: 20,
        timeAt: (index) {
          accessCount += 1;
          return start + Duration(minutes: index).inMilliseconds;
        },
        beginIndex: 2.5,
        itemWidth: 8,
        spacing: 2,
        itemCount: 10,
        viewportWidth: 100,
        minLabelSpacing: 35,
      );

      expect(ticks.map((tick) => tick.dataIndex), [4, 8, 12]);
      expect(accessCount, lessThan(20));
    });
  });

  group('KLineController instances', () {
    test('creates independent instances while keeping shared available', () {
      final first = KLineController();
      final second = KLineController();

      expect(first, isNot(same(KLineController.shared)));
      expect(second, isNot(same(KLineController.shared)));
      expect(first, isNot(same(second)));

      first.data = _buildKLineData(1);

      expect(first.data, hasLength(1));
      expect(second.data, isEmpty);
      expect(KLineController.shared.data, isEmpty);
    });

    testWidgets('KLineView renders from the provided controller',
        (tester) async {
      KLineController.shared.data = [];
      final controller = KLineController()
        ..data = _buildKLineData(5)
        ..itemCount = 5
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 300,
          height: 240,
          child: KLineView(controller: controller),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('KLineController data updates', () {
    test('data lifecycle methods update data and notify listeners', () {
      final controller = KLineController();
      final changes = <KLineDataChange>[];
      controller.addListener(() {
        final change = controller.lastDataChange;
        if (change != null) {
          changes.add(change);
        }
      });

      final initialData = _buildKLineData(2);
      controller.setData(initialData);

      final updatedLast = KLineData(close: 99, time: 1);
      controller.updateLast(updatedLast);

      final appended = KLineData(close: 100, time: 2);
      controller.append(appended);

      final history = [
        KLineData(close: 1, time: -2),
        KLineData(close: 2, time: -1),
      ];
      controller.prependHistory(history);

      controller.clearData();

      expect(
        changes.map((change) => change.type),
        [
          KLineDataChangeType.setData,
          KLineDataChangeType.updateLast,
          KLineDataChangeType.append,
          KLineDataChangeType.prependHistory,
          KLineDataChangeType.clear,
        ],
      );
      expect(changes[0].previousLength, 0);
      expect(changes[0].newLength, 2);
      expect(changes[0].resetView, isTrue);
      expect(changes[1].previousLength, 2);
      expect(changes[1].newLength, 2);
      expect(changes[2].addedCount, 1);
      expect(changes[3].addedCount, 2);
      expect(controller.data, isEmpty);
    });

    test('data setter keeps the old assignment API and notifies listeners', () {
      final controller = KLineController();
      KLineDataChange? change;
      controller.addListener(() {
        change = controller.lastDataChange;
      });

      controller.data = _buildKLineData(3);

      expect(controller.data, hasLength(3));
      expect(change?.type, KLineDataChangeType.setData);
      expect(change?.newLength, 3);
      expect(change?.resetView, isFalse);
    });

    test('updateLast appends when the controller has no data', () {
      final controller = KLineController();
      final candle = KLineData(close: 12, time: 1);

      controller.updateLast(candle);

      expect(controller.data, [same(candle)]);
      expect(controller.lastDataChange?.type, KLineDataChangeType.append);
    });

    test('owns a growable copy of data supplied by the caller', () {
      final source = <KLineData>[KLineData(close: 1)];
      final controller = KLineController()..setData(source);

      source.clear();
      controller.append(KLineData(close: 2));

      expect(controller.data.map((item) => item.close), [1, 2]);
    });

    test('accepts unmodifiable input and exposes read-only data', () {
      final controller = KLineController()
        ..setData(List<KLineData>.unmodifiable([KLineData(close: 1)]));

      controller.prependHistory([KLineData(close: 0)]);
      controller.append(KLineData(close: 2));

      expect(controller.data.map((item) => item.close), [0, 1, 2]);
      expect(
        () => controller.data.add(KLineData(close: 3)),
        throwsUnsupportedError,
      );
    });

    test('overlay updates notify listeners without changing data version', () {
      final controller = KLineController();
      controller.setData(_buildKLineData(2));
      final dataVersion = controller.dataVersion;

      var notifyCount = 0;
      controller.addListener(() {
        notifyCount += 1;
      });

      final overlay = KLinePriceLine(
        price: 12,
        label: 'Entry',
        color: Colors.blue,
      );

      controller.setOverlays([overlay]);

      expect(controller.overlays, [overlay]);
      expect(controller.overlayVersion, 1);
      expect(controller.dataVersion, dataVersion);
      expect(notifyCount, 1);

      controller.clearOverlays();

      expect(controller.overlays, isEmpty);
      expect(controller.overlayVersion, 2);
      expect(controller.dataVersion, dataVersion);
      expect(notifyCount, 2);
    });
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

    test('allows configured trailing blank slots after the latest candle', () {
      const dataLength = 100;
      const itemCount = 30.0;
      const itemExtent = 12.0;
      const maxBeginIndex = dataLength - itemCount + 10;
      const trailingBlankOffset = (maxBeginIndex + 0.75) * itemExtent;

      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: trailingBlankOffset,
        itemExtent: itemExtent,
        itemCount: itemCount,
        dataLength: dataLength,
        trailingBlankItemCount: 10,
        minTrailingVisibleItemCount: 3,
      );

      expect(beginIndex, maxBeginIndex);
    });

    test('keeps the configured minimum real candles visible at the end', () {
      const dataLength = 100;
      const itemCount = 30.0;
      const itemExtent = 12.0;
      const maxBeginIndex = dataLength - 3;
      const trailingBlankOffset = (maxBeginIndex + 10) * itemExtent;

      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: trailingBlankOffset,
        itemExtent: itemExtent,
        itemCount: itemCount,
        dataLength: dataLength,
        trailingBlankItemCount: 100,
        minTrailingVisibleItemCount: 3,
      );

      expect(beginIndex, maxBeginIndex);
    });

    test('does not overscroll when data is shorter than trailing blank config',
        () {
      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: 240,
        itemExtent: 12,
        itemCount: 30,
        dataLength: 5,
        trailingBlankItemCount: 20,
        minTrailingVisibleItemCount: 4,
      );

      expect(beginIndex, 0);
    });

    test('keeps all available real candles visible when data is below minimum',
        () {
      final beginIndex = KLineController.beginIndexForScrollOffset(
        offset: 240,
        itemExtent: 12,
        itemCount: 7,
        dataLength: 3,
        trailingBlankItemCount: 20,
        minTrailingVisibleItemCount: 4,
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

    test('allows zoom results inside the configured trailing blank range', () {
      final result = KLineController.zoomForScale(
        startBeginIndex: 90,
        startItemCount: 30,
        scale: 1,
        startFocalDx: 300,
        currentFocalDx: 300,
        viewportWidth: 300,
        dataLength: 100,
        minItemCount: 7,
        maxItemCount: 39,
        trailingBlankItemCount: 20,
        minTrailingVisibleItemCount: 3,
      );

      expect(result.itemCount, 30);
      expect(result.beginIndex, 90);
    });
  });

  group('KLinePainter.shouldRepaint', () {
    test('repaints when begin index changes', () {
      final oldPainter = KLinePainter(const [], 10);
      final newPainter = KLinePainter(const [], 11);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints when updateLast changes the data version', () {
      final controller = KLineController()
        ..showMainIndicators = []
        ..showSubIndicators = []
        ..setData(_buildKLineData(2));
      final oldPainter = KLinePainter(
        controller.data,
        0,
        controller: controller,
      );

      controller.updateLast(KLineData(
        open: 100,
        high: 101,
        low: 99,
        close: 100,
        volume: 10,
        time: 1,
      ));
      final newPainter = KLinePainter(
        controller.data,
        0,
        controller: controller,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints when indicator selection changes', () {
      final controller = KLineController()
        ..showMainIndicators = [IndicatorType.ma]
        ..showSubIndicators = [IndicatorType.vol];
      final oldPainter = KLinePainter(const [], 0, controller: controller);

      controller
        ..showMainIndicators = [IndicatorType.boll]
        ..showSubIndicators = [IndicatorType.macd];
      final newPainter = KLinePainter(const [], 0, controller: controller);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints when indicator periods change', () {
      final controller = KLineController()..macdPeriods = [12, 26, 9];
      final oldPainter = KLinePainter(const [], 0, controller: controller);

      controller.macdPeriods = [5, 10, 4];
      final newPainter = KLinePainter(const [], 0, controller: controller);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints for every chart geometry field used by the painter', () {
      final changes = <String, void Function(KLineController)>{
        'itemCount': (controller) => controller.itemCount = 20,
        'spacing': (controller) => controller.spacing = 4,
        'klineMargin': (controller) =>
            controller.klineMargin = const EdgeInsets.all(3),
        'mainIndicatorInfoMargin': (controller) =>
            controller.mainIndicatorInfoMargin = 8,
        'indicatorSpacing': (controller) => controller.indicatorSpacing = 12,
        'subIndicatorHeight': (controller) =>
            controller.subIndicatorHeight = 80,
        'indicatorInfoHeight': (controller) =>
            controller.indicatorInfoHeight = 20,
      };

      for (final change in changes.entries) {
        final controller = KLineController();
        final oldPainter = KLinePainter(const [], 0, controller: controller);

        change.value(controller);
        final newPainter = KLinePainter(const [], 0, controller: controller);

        expect(
          newPainter.shouldRepaint(oldPainter),
          isTrue,
          reason: change.key,
        );
      }
    });

    test('repaints indicator info when the data version changes', () {
      final controller = KLineController()..setData(_buildKLineData(2));
      final oldPainter = KLineIndicatorInfoPainter(
        controller.data,
        0,
        controller: controller,
      );

      controller.updateLast(KLineData(close: 100, time: 1));
      final newPainter = KLineIndicatorInfoPainter(
        controller.data,
        0,
        controller: controller,
      );

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

    test('repaints when overlays change', () {
      KLineController.shared.clearOverlays();
      final oldPainter = KLinePainter(const [], 10);

      KLineController.shared.setOverlays([
        KLinePriceLine(
          price: 12,
          label: 'Entry',
          color: Colors.blue,
        )
      ]);
      final newPainter = KLinePainter(const [], 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints when overlay style changes', () {
      KLineController.shared.overlayStyle = const KLineOverlayStyle(
        priceLineColor: Colors.blue,
      );
      final oldPainter = KLinePainter(const [], 10);

      KLineController.shared.overlayStyle = const KLineOverlayStyle(
        priceLineColor: Colors.orange,
      );
      final newPainter = KLinePainter(const [], 10);

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('repaints when axis configuration changes', () {
      KLineController.shared.showTimeAxis = false;
      KLineController.shared.priceAxisMaxTickCount = 5;
      final oldPainter = KLinePainter(const [], 10);

      KLineController.shared.showTimeAxis = true;
      KLineController.shared.priceAxisMaxTickCount = 6;
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

  group('KLine overlay rendering', () {
    test('renders price line at the expected price y coordinate', () async {
      KLineController.shared.itemCount = 1;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.setOverlays([
        KLinePriceLine(
          price: 15,
          color: const Color(0xff3366ff),
          strokeWidth: 3,
        )
      ]);

      final data = [
        KLineData(
          open: 12,
          high: 20,
          low: 10,
          close: 14,
          volume: 1,
          time: 0,
        )
      ];
      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 10, 50, 100), const Color(0xff3366ff));
    });

    test('renders marker at the matching candle center x coordinate', () async {
      KLineController.shared.itemCount = 3;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.setOverlays([
        KLineMarker(
          time: 1,
          price: 15,
          color: const Color(0xff00aaff),
          radius: 6,
        )
      ]);

      final data = [
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 0),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 1),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 2),
      ];
      final bytes = await _paintToBytes(
        const Size(300, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 150, 50, 300), const Color(0xff00aaff));
    });

    test('keeps top-edge sell markers fully visible', () async {
      KLineController.shared.itemCount = 1;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.setOverlays([
        KLineMarker(
          time: 0,
          price: 20,
          type: KLineMarkerType.sell,
          color: const Color(0xffdd2222),
          radius: 6,
        )
      ]);

      final data = [
        KLineData(
          open: 12,
          high: 20,
          low: 10,
          close: 14,
          volume: 1,
          time: 0,
        )
      ];
      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      final markerPixel = _pixelAt(bytes, 44, 10, 100).toARGB32();
      expect((markerPixel >> 16) & 0xff, greaterThan(200));
      expect((markerPixel >> 8) & 0xff, lessThan(120));
      expect(markerPixel & 0xff, lessThan(120));
    });

    test('aligns time overlays to the first candle with a matching time',
        () async {
      KLineController.shared.itemCount = 3;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.setOverlays([
        KLineMarker(
          time: 1,
          price: 15,
          color: const Color(0xff00aaff),
          radius: 6,
        )
      ]);

      final data = [
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 1),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 1),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 2),
      ];
      final bytes = await _paintToBytes(
        const Size(300, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 50, 50, 300), const Color(0xff00aaff));
    });

    test('renders price zone and vertical line overlays', () async {
      KLineController.shared.itemCount = 3;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.overlayStyle = const KLineOverlayStyle(
        zoneOpacity: 1,
      );
      KLineController.shared.setOverlays([
        KLinePriceZone(
          fromPrice: 14,
          toPrice: 16,
          color: const Color(0xff22cc88),
        ),
        KLineVerticalLine(
          time: 1,
          color: const Color(0xffaa33ff),
          strokeWidth: 3,
        ),
      ]);

      final data = [
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 0),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 1),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 2),
      ];
      final bytes = await _paintToBytes(
        const Size(300, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 10, 50, 300), const Color(0xff22cc88));
      expect(_pixelAt(bytes, 150, 10, 300), const Color(0xffaa33ff));
    });

    test('skips unmatched time overlays without throwing', () async {
      KLineController.shared.itemCount = 3;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [];
      KLineController.shared.setOverlays([
        KLineMarker(time: 999, price: 15),
        KLineVerticalLine(time: 999),
      ]);

      final data = [
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 0),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 1),
        KLineData(open: 12, high: 20, low: 10, close: 12, volume: 1, time: 2),
      ];

      await _paintToBytes(
        const Size(300, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );
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

    testWidgets('renders optional time axis without invalid canvas values',
        (tester) async {
      final start = DateTime(2024, 1, 1, 9, 30).millisecondsSinceEpoch;
      KLineController.shared.data = List.generate(40, (index) {
        return KLineData(
          open: 10.0 + index,
          high: 11.0 + index,
          low: 9.0 + index,
          close: 10.5 + index,
          volume: 100.0 + index,
          time: start + Duration(minutes: index).inMilliseconds,
        );
      });
      KLineController.shared.showTimeAxis = true;

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 300, height: 240, child: KLineView()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('keeps volume bars above the reserved time axis area', () async {
      KLineController.shared.itemCount = 1;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [IndicatorType.vol];
      KLineController.shared.indicatorSpacing = 0;
      KLineController.shared.indicatorInfoHeight = 0;
      KLineController.shared.subIndicatorHeight = 50;
      KLineController.shared.showTimeAxis = true;
      KLineController.shared.timeAxisHeight = 20;
      KLineController.shared.chartStyle = const KLineChartStyle(
        gridLineColor: Color(0x00000000),
        rulerTextStyle: TextStyle(color: Color(0x00000000)),
        highLowLineColor: Color(0x00000000),
        highLowTextStyle: TextStyle(color: Color(0x00000000)),
        currentPriceLineColor: Color(0x00000000),
        currentPriceBackgroundColor: Color(0x00000000),
        currentPriceTextStyle: TextStyle(color: Color(0x00000000)),
      );
      KLineController.shared.candleStyle = const KLineCandleStyle(
        riseColor: Color(0x00000000),
        fallColor: Color(0x00000000),
        riseWickColor: Color(0x00000000),
        fallWickColor: Color(0x00000000),
      );
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
        const Size(100, 100),
        (canvas, size) => KLinePainter(data, 0).paint(canvas, size),
      );

      expect(_pixelAt(bytes, 50, 35, 100), const Color(0xff22cc88));
      expect(_pixelAt(bytes, 50, 90, 100), const Color(0x00000000));
    });

    test('positions sub indicator info above the reserved time axis area',
        () async {
      KLineController.shared.itemCount = 10;
      KLineController.shared.spacing = 0;
      KLineController.shared.showMainIndicators = [];
      KLineController.shared.showSubIndicators = [IndicatorType.vol];
      KLineController.shared.indicatorSpacing = 0;
      KLineController.shared.subIndicatorHeight = 50;
      KLineController.shared.showTimeAxis = true;
      KLineController.shared.timeAxisHeight = 20;
      KLineController.shared.indicatorColors = const [
        Color(0xffff0000),
        Color(0xffff0000),
        Color(0xffff0000),
      ];
      KLineController.shared.volumeFormatter = (_) => 'V';
      final data = _buildKLineData(20);

      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) =>
            KLineIndicatorInfoPainter(data, 0).paint(canvas, size),
      );
      final firstRedY = _firstColorLikeY(
        bytes,
        width: 100,
        xStart: 0,
        xEnd: 100,
        yStart: 0,
        yEnd: 100,
        matches: _isMostlyRed,
      );

      expect(
        _containsColorLike(
          bytes,
          width: 100,
          xStart: 0,
          xEnd: 100,
          yStart: 28,
          yEnd: 48,
          matches: _isMostlyRed,
        ),
        isTrue,
      );
      expect(firstRedY, isNotNull);
      expect(firstRedY!, lessThan(50));
    });

    testWidgets(
        'initializes at the latest candle when trailing blank is disabled',
        (tester) async {
      KLineController.shared.data = _buildKLineData(40);
      KLineController.shared.itemCount = 10;

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(width: 300, height: 240, child: KLineView()),
        ),
      ));
      await tester.pump();

      final scrollView = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));

      expect(scrollView.controller?.offset, closeTo(900, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('initializes with configured trailing blank space',
        (tester) async {
      KLineController.shared.data = _buildKLineData(40);
      KLineController.shared.itemCount = 10;
      KLineController.shared.trailingBlankItemCount = 4;
      KLineController.shared.maxTrailingBlankItemCount = 8;

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(width: 300, height: 240, child: KLineView()),
        ),
      ));
      await tester.pump();

      final scrollView = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));

      expect(scrollView.controller?.offset, closeTo(1020, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the visible candle range stable when width changes',
        (tester) async {
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..trailingBlankItemCount = 0
        ..maxTrailingBlankItemCount = 0
        ..showMainIndicators = []
        ..showSubIndicators = [];
      var chartWidth = 300.0;
      late StateSetter updateHost;

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Center(
              child: SizedBox(
                width: chartWidth,
                height: 240,
                child: KLineView(controller: controller),
              ),
            );
          },
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scrollController.jumpTo(300);
      await tester.pump();

      updateHost(() => chartWidth = 600);
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(600, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders short data with trailing blank defaults',
        (tester) async {
      KLineController.shared.data = _buildKLineData(3);
      KLineController.shared.itemCount = 7;
      KLineController.shared.trailingBlankItemCount = 5;
      KLineController.shared.maxTrailingBlankItemCount = 20;
      KLineController.shared.minTrailingVisibleItemCount = 4;

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(width: 280, height: 240, child: KLineView()),
        ),
      ));
      await tester.pump();

      final scrollView = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));

      expect(scrollView.controller?.offset, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilds automatically when controller data changes',
        (tester) async {
      final controller = KLineController()
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(controller: controller),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.setData(_buildKLineData(5));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the visible candles stable when history is prepended',
        (tester) async {
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..trailingBlankItemCount = 0
        ..maxTrailingBlankItemCount = 0
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(controller: controller),
          ),
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scrollController.jumpTo(300);
      await tester.pump();

      controller.prependHistory(_buildKLineData(5));
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(450, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('overlay updates do not replay the last data lifecycle change',
        (tester) async {
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..trailingBlankItemCount = 0
        ..maxTrailingBlankItemCount = 0
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(controller: controller),
          ),
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scrollController.jumpTo(300);
      await tester.pump();

      controller.prependHistory(_buildKLineData(5));
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(450, 0.000001));

      controller.setOverlays([
        KLinePriceLine(
          price: 12,
          label: 'Entry',
          color: Colors.blue,
        )
      ]);
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(450, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps following the latest candle when new candles append',
        (tester) async {
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..trailingBlankItemCount = 0
        ..maxTrailingBlankItemCount = 0
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(controller: controller),
          ),
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;

      expect(scrollController.offset, closeTo(900, 0.000001));

      controller.append(KLineData(close: 99, time: 40));
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(930, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not jump when appending away from the latest candle',
        (tester) async {
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(controller: controller),
          ),
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scrollController.jumpTo(300);
      await tester.pump();

      controller.append(KLineData(close: 99, time: 40));
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(300, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the old data setter from forcing a latest reset',
        (tester) async {
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..trailingBlankItemCount = 0
        ..maxTrailingBlankItemCount = 0
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(controller: controller),
          ),
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scrollController.jumpTo(300);
      await tester.pump();

      controller.data = [
        ...controller.data,
        KLineData(close: 99, time: 40),
      ];
      await tester.pump();

      expect(scrollController.offset, closeTo(300, 0.000001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('calls onLoadMore when scrolling near the leading edge',
        (tester) async {
      var loadMoreCount = 0;
      final controller = KLineController()
        ..data = _buildKLineData(40)
        ..itemCount = 10
        ..showMainIndicators = []
        ..showSubIndicators = [];

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 240,
            child: KLineView(
              controller: controller,
              loadMoreThreshold: 2,
              onLoadMore: () async {
                loadMoreCount += 1;
              },
            ),
          ),
        ),
      ));
      await tester.pump();

      final scrollController = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scrollController.jumpTo(30);
      await tester.pump();

      expect(loadMoreCount, 1);
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

    test('calculates BOLL values without including warm-up sentinels in bounds',
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
      expect(result.minValue, closeTo(0.367006838144548, 0.000001));
    });

    test('keeps neutral BOLL bounds while every value is warming up', () {
      KLineController.shared.itemCount = 2;
      final data = _buildKLineDataFromCloses([1, 2]);

      final result = IndicatorDataHandler.boll(data, 3, 2, 0);

      expect(result.data, [
        [-1, -1],
        [-1, -1],
        [-1, -1],
      ]);
      expect(result.maxValue, 0);
      expect(result.minValue, 0);
    });

    test('calculates KDJ values without changing the visible result', () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15]);

      final result = IndicatorDataHandler.kdj(data, [3, 3, 3], 0);
      final k = result.data[0];
      final d = result.data[1];
      final j = result.data[2];

      expect(k, hasLength(5));
      expect(k.first, closeTo(50, 0.000001));
      expect(d.first, closeTo(50, 0.000001));
      expect(j.first, closeTo(50, 0.000001));
      expect(k[1], closeTo(58.333333333333336, 0.000001));
      expect(d[1], closeTo(52.77777777777778, 0.000001));
      expect(j[1], closeTo(69.44444444444446, 0.000001));
      expect(k.last, closeTo(62.46913580246913, 0.000001));
      expect(d.last, closeTo(58.8477366255144, 0.000001));
      expect(j.last, closeTo(69.71193415637859, 0.000001));
      expect(result.maxValue, closeTo(77.03703703703704, 0.000001));
      expect(result.minValue, closeTo(50, 0.000001));
    });

    test('uses a neutral KDJ RSV after a non-flat trend becomes flat', () {
      KLineController.shared.itemCount = 5;
      final data = [
        KLineData(open: 1, high: 2, low: 1, close: 2),
        KLineData(open: 2, high: 3, low: 1, close: 3),
        KLineData(open: 2, high: 2, low: 2, close: 2),
        KLineData(open: 2, high: 2, low: 2, close: 2),
        KLineData(open: 2, high: 2, low: 2, close: 2),
      ];

      final result = IndicatorDataHandler.kdj(data, [3, 3, 3], 0);

      expect(result.data, hasLength(3));
      expect(result.data.every((values) => values.length == 5), isTrue);
      expect(
        result.data.expand((values) => values).every((value) => value.isFinite),
        isTrue,
      );
      expect(result.data[0].last, closeTo(64.81481481481481, 0.000001));
      expect(result.data[1].last, closeTo(79.62962962962963, 0.000001));
      expect(result.data[2].last, closeTo(35.185185185185176, 0.000001));
      expect(result.maxValue, 100);
      expect(result.minValue, closeTo(35.185185185185176, 0.000001));
    });

    test('calculates WR values without changing the visible result', () {
      KLineController.shared.itemCount = 5;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13]);

      final result = IndicatorDataHandler.wr(data, [3], 0);

      expect(result.data.single[0], closeTo(50, 0.000001));
      expect(result.data.single[1], closeTo(25, 0.000001));
      expect(result.data.single[2], closeTo(50, 0.000001));
      expect(result.data.single[3], closeTo(20, 0.000001));
      expect(result.data.single[4], closeTo(40, 0.000001));
      expect(result.maxValue, closeTo(50, 0.000001));
      expect(result.minValue, closeTo(20, 0.000001));
    });

    test('keeps OBV values stable for overlapping candles while scrolling', () {
      final controller = KLineController()..itemCount = 2;
      final data = List.generate(
        5,
        (index) => KLineData(close: index + 1.0, volume: 10),
      );

      final fromOne =
          IndicatorDataHandler.obv(data, 1, controller: controller).data.single;
      final fromTwo =
          IndicatorDataHandler.obv(data, 2, controller: controller).data.single;

      expect(fromOne, [0, 10, 20]);
      expect(fromTwo, [10, 20, 30]);
      expect(fromOne.sublist(1), fromTwo.sublist(0, 2));
    });

    test('line indicators include one leading value during fractional scroll',
        () {
      KLineController.shared.itemCount = 3;
      const beginIdx = 1.5;
      final data = _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15]);

      expect(
          IndicatorDataHandler.ema(data, [1], beginIdx).data.single.length, 4);
      expect(
          IndicatorDataHandler.boll(data, 1, 2, beginIdx).data.first.length, 4);
      expect(
          IndicatorDataHandler.kdj(data, [3, 3, 3], beginIdx).data.first.length,
          4);
      expect(
          IndicatorDataHandler.rsi(data, [1], beginIdx).data.single.length, 4);
      expect(
          IndicatorDataHandler.wr(data, [1], beginIdx).data.single.length, 4);
      expect(IndicatorDataHandler.obv(data, beginIdx).data.single.length, 4);
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

    test('includes leading values for fractional scroll alignment', () {
      final data =
          _buildKLineDataFromCloses([10, 12, 11, 14, 13, 15, 16, 14, 17, 18]);

      KLineController.shared.itemCount = 10;
      final full = IndicatorDataHandler.macd(data, [3, 6, 3], 0);

      KLineController.shared.itemCount = 3;
      final fractional = IndicatorDataHandler.macd(data, [3, 6, 3], 5.5);

      expect(fractional.data[0].length, 5);
      expect(fractional.data[0][0], closeTo(full.data[0][4], 0.000001));
      expect(fractional.data[0][1], closeTo(full.data[0][5], 0.000001));
      expect(fractional.data[1][0], closeTo(full.data[1][4], 0.000001));
      expect(fractional.data[1][1], closeTo(full.data[1][5], 0.000001));
      expect(fractional.data[2][0], closeTo(full.data[2][4], 0.000001));
      expect(fractional.data[2][1], closeTo(full.data[2][5], 0.000001));
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

    test('keeps the leading histogram bar visible during fractional scroll',
        () async {
      KLineController.shared.itemCount = 2;
      KLineController.shared.spacing = 0;
      KLineController.shared.indicatorInfoHeight = 0;

      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) => MACDPainter().paintData(
          canvas,
          size,
          const [
            [-1, -1, -1],
            [-1, -1, -1],
            [1, 1, 1],
          ],
          100,
          const [12, 26, 9],
          25,
          1,
          0,
          leadingItemCount: 1,
          showInfo: false,
        ),
      );

      expect(_pixelAt(bytes, 10, 50, 100), const Color(0xff4caf50));
    });

    test('keeps the leading histogram hollow when it decreases', () async {
      KLineController.shared.itemCount = 2;
      KLineController.shared.spacing = 0;
      KLineController.shared.indicatorInfoHeight = 0;

      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) => MACDPainter().paintData(
          canvas,
          size,
          const [
            [-1, -1, -1],
            [-1, -1, -1],
            [2, 1, 1],
          ],
          100,
          const [12, 26, 9],
          25,
          2,
          0,
          leadingItemCount: 2,
          showInfo: false,
        ),
      );

      expect(_pixelAt(bytes, 10, 75, 100), const Color(0x00000000));
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

    test('draws the latest non-MA line value at the latest candle center',
        () async {
      KLineController.shared.itemCount = 3;
      KLineController.shared.spacing = 0;
      KLineController.shared.indicatorInfoHeight = 0;

      final bytes = await _paintToBytes(
        const Size(30, 30),
        (canvas, size) => IndicatorLinePainter.paint(
          canvas,
          size,
          30,
          IndicatorType.rsi,
          const [
            [50, 50, 50]
          ],
          const [1],
          0,
          0,
          100,
          0,
          lineColors: const [Color(0xffff0000)],
          showInfo: false,
        ),
      );

      expect(_pixelAt(bytes, 24, 15, 30), isNot(const Color(0x00000000)));
    });

    test('keeps the leading non-MA line value visible during fractional scroll',
        () async {
      KLineController.shared.itemCount = 2;
      KLineController.shared.spacing = 0;
      KLineController.shared.indicatorInfoHeight = 0;

      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) => IndicatorLinePainter.paint(
          canvas,
          size,
          100,
          IndicatorType.rsi,
          const [
            [50, 50, 50]
          ],
          const [1],
          1.5,
          25,
          100,
          0,
          leadingItemCount: 1,
          lineColors: const [Color(0xffff0000)],
          showInfo: false,
        ),
      );

      expect(_pixelAt(bytes, 2, 50, 100), isNot(const Color(0x00000000)));
      expect(_pixelAt(bytes, 98, 50, 100), isNot(const Color(0x00000000)));
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

    test('keeps the leading volume bar visible during fractional scroll',
        () async {
      KLineController.shared.itemCount = 2;
      KLineController.shared.spacing = 0;
      KLineController.shared.indicatorInfoHeight = 0;
      KLineController.shared.subIndicatorHeight = 100;
      KLineController.shared.showSubIndicators = [IndicatorType.vol];
      KLineController.shared.volumeStyle = const KLineVolumeStyle(
        riseColor: Color(0xff22cc88),
        fallColor: Color(0xffdd4455),
      );

      final data = _buildKLineData(4);
      final bytes = await _paintToBytes(
        const Size(100, 100),
        (canvas, size) =>
            VolPainter(data, 1.5).paint(canvas, size, 1, 25, showInfo: false),
      );

      expect(_pixelAt(bytes, 10, 50, 100), const Color(0xff22cc88));
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
        infoStyle: const KLineInfoStyle(
          backgroundColor: Color(0xff182430),
        ),
      );
      final newPainter = KLineLongPressInfoPainter(
        data,
        0,
        const Offset(5, 20),
        infoStyle: const KLineInfoStyle(
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

    test('uses the selected line indicator value when data has a leading point',
        () {
      final valueText = IndicatorLinePainter.infoValueText(
        IndicatorType.rsi,
        [5, 10, 20, 30],
        2,
        leadingItemCount: 1,
      );

      expect(valueText, '30.00');
    });

    test('formats line indicator values with the indicator formatter', () {
      KLineController.shared.indicatorFormatter = (value, type, period) {
        return '${type.name}:${period ?? 0}:${value.toStringAsFixed(1)}';
      };

      final valueText = IndicatorLinePainter.infoValueText(
        IndicatorType.rsi,
        [10.25, 20.25],
        1,
        period: 6,
      );

      expect(valueText, 'RSI:6:20.3');
    });

    test('formats volume MA values with the volume formatter', () {
      KLineController.shared.volumeFormatter = (value) => 'VOL:$value';

      final valueText = IndicatorLinePainter.infoValueText(
        IndicatorType.maVol,
        [10, 12.5],
        0,
      );

      expect(valueText, 'VOL:12.5');
    });

    test('formats MACD values with the indicator formatter', () {
      KLineController.shared.indicatorFormatter = (value, type, period) {
        return '${type.name}:${period ?? 0}:${value.toStringAsFixed(3)}';
      };

      expect(MACDPainter.infoValueText([-1, -0.25], 1), 'MACD:0:-0.250');
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

    test('repaints the indicator info overlay when time axis layout changes',
        () {
      final data = _buildKLineData(20);
      KLineController.shared.showTimeAxis = false;
      final oldPainter = KLineIndicatorInfoPainter(data, 10);

      KLineController.shared.showTimeAxis = true;
      KLineController.shared.timeAxisHeight = 20;
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

bool _containsColorLike(
  ByteData data, {
  required int width,
  required int xStart,
  required int xEnd,
  required int yStart,
  required int yEnd,
  required bool Function(Color color) matches,
}) {
  for (var y = yStart; y < yEnd; y += 1) {
    for (var x = xStart; x < xEnd; x += 1) {
      if (matches(_pixelAt(data, x, y, width))) {
        return true;
      }
    }
  }
  return false;
}

int? _firstColorLikeY(
  ByteData data, {
  required int width,
  required int xStart,
  required int xEnd,
  required int yStart,
  required int yEnd,
  required bool Function(Color color) matches,
}) {
  for (var y = yStart; y < yEnd; y += 1) {
    for (var x = xStart; x < xEnd; x += 1) {
      if (matches(_pixelAt(data, x, y, width))) {
        return y;
      }
    }
  }
  return null;
}

bool _isMostlyRed(Color color) {
  // The integer channels are the Color API available in Flutter 3.0.
  // ignore: deprecated_member_use
  final alpha = color.alpha;
  // ignore: deprecated_member_use
  final red = color.red;
  // ignore: deprecated_member_use
  final green = color.green;
  // ignore: deprecated_member_use
  final blue = color.blue;
  return alpha > 25 && red > 153 && green < 64 && blue < 64;
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
