// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_chart/kline_chart.dart';
import 'package:kline_chart_example/main.dart';

void main() {
  setUp(() {
    KLineController.shared.data = [];
    KLineController.shared.clearOverlays();
    KLineController.shared.showMainIndicators = [IndicatorType.ma];
    KLineController.shared.showSubIndicators = [
      IndicatorType.vol,
      IndicatorType.kdj,
    ];
    KLineController.shared.showTimeChart = false;
  });

  testWidgets('loads overlay marker demo in the original demo',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Overlay / Marker'), findsOneWidget);
    expect(KLineController.shared.overlays, isNotEmpty);
    expect(
      KLineController.shared.overlays.whereType<KLinePriceLine>(),
      isNotEmpty,
    );
    expect(
      KLineController.shared.overlays.whereType<KLinePriceZone>(),
      isNotEmpty,
    );
    expect(
      KLineController.shared.overlays.whereType<KLineMarker>(),
      isNotEmpty,
    );
    expect(
      KLineController.shared.overlays.whereType<KLineVerticalLine>(),
      isNotEmpty,
    );
  });

  testWidgets('opens the multi controller demo from the original demo',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('flutter kline demo'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(const Key('multi_controller_demo_button')),
      ),
      findsNothing,
    );

    final demoButton = find.byKey(const Key('multi_controller_demo_button'));
    expect(
      find.descendant(
        of: demoButton,
        matching: find.text('Multi Controller Demo'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: demoButton,
        matching: find.byIcon(Icons.chevron_right),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(demoButton).dy,
      lessThan(tester.getTopLeft(find.text('Main Indicator')).dy),
    );

    await tester.tap(demoButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Multi Controller Demo'), findsOneWidget);
  });
}
