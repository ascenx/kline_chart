// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_chart/kline_chart.dart';
import 'package:kline_chart_example/main.dart';
import 'package:kline_chart_example/orientation_demo_page.dart';

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
    KLineController.shared.showTimeAxis = false;
  });

  testWidgets('loads overlay marker demo in the original demo',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Overlay / Marker'), findsOneWidget);
    expect(find.text('Time Axis'), findsOneWidget);
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

  testWidgets('toggles the optional time axis in the original demo',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(KLineController.shared.showTimeAxis, isFalse);

    await tester.tap(find.text('Time Axis'));
    await tester.pump();

    expect(KLineController.shared.showTimeAxis, isTrue);
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

  testWidgets('orientation demo switches between portrait and landscape',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final orientationRequests = <List<String>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientationRequests.add(List<String>.from(call.arguments as List));
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.byKey(const Key('orientation_demo_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Portrait / Landscape Demo'), findsOneWidget);
    expect(
        find.byKey(const Key('portrait_orientation_layout')), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch_to_landscape_button')));
    await tester.pump();

    expect(
      orientationRequests.last,
      const [
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 500));
    await tester.pump();

    expect(
      find.byKey(const Key('landscape_orientation_layout')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('switch_to_portrait_button')));
    await tester.pump();

    expect(
      orientationRequests.last,
      const ['DeviceOrientation.portraitUp'],
    );

    await tester.tap(find.byKey(const Key('orientation_demo_back_button')));
    await tester.pump();

    expect(
      orientationRequests.last,
      const ['DeviceOrientation.portraitUp'],
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(
      orientationRequests.last,
      const ['DeviceOrientation.portraitUp'],
    );
  });

  testWidgets('orientation demo returns to the home page in portrait',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final orientationRequests = <List<String>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientationRequests.add(List<String>.from(call.arguments as List));
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(MaterialApp(
      routes: {
        '/': (_) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const Key('open_orientation_demo'),
                  onPressed: () => Navigator.of(context).pushNamed('/demo'),
                  child: const Text('Open'),
                ),
              ),
            ),
        '/demo': (_) => const OrientationDemoPage(initialData: []),
      },
    ));
    await tester.tap(find.byKey(const Key('open_orientation_demo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('switch_to_landscape_button')));
    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(900, 500));
    await tester.pump();

    await tester.tap(find.byKey(const Key('orientation_demo_back_button')));
    await tester.pump();

    expect(
      orientationRequests.last,
      const ['DeviceOrientation.portraitUp'],
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('open_orientation_demo')), findsOneWidget);
    expect(
      orientationRequests.last,
      const ['DeviceOrientation.portraitUp'],
    );
  });

  testWidgets('orientation demo keeps the chart state while rotating',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final data = List.generate(
      100,
      (index) => KLineData(
        open: 100 + index.toDouble(),
        high: 102 + index.toDouble(),
        low: 99 + index.toDouble(),
        close: 101 + index.toDouble(),
        volume: 10 + index.toDouble(),
        time: index,
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: OrientationDemoPage(initialData: data),
    ));
    final pageFinder = find.byType(OrientationDemoPage);
    final chartFinder = find.descendant(
      of: pageFinder,
      matching: find.byType(KLineView),
    );
    await tester.pump();

    final portraitWidth = tester.getSize(chartFinder).width;
    final portraitScrollController = tester
        .widget<SingleChildScrollView>(find.descendant(
          of: chartFinder,
          matching: find.byType(SingleChildScrollView),
        ))
        .controller!;
    portraitScrollController.jumpTo(portraitWidth * 2);
    await tester.pump();

    await tester.binding.setSurfaceSize(const Size(900, 500));
    await tester.pump();
    await tester.pump();

    final landscapeWidth = tester.getSize(chartFinder).width;
    final landscapeScrollController = tester
        .widget<SingleChildScrollView>(find.descendant(
          of: chartFinder,
          matching: find.byType(SingleChildScrollView),
        ))
        .controller!;

    expect(landscapeScrollController, same(portraitScrollController));
    expect(
      landscapeScrollController.offset,
      closeTo(landscapeWidth * 2, 0.000001),
    );
  });

  testWidgets('orientation demo explains platform orientation limitations',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: OrientationDemoPage()),
    );
    await tester.pump();

    final notice = find.descendant(
      of: find.byType(OrientationDemoPage),
      matching: find.byKey(const Key('orientation_limitations_notice')),
    );
    expect(notice, findsOneWidget);
    final noticeWidget = tester.widget<Text>(notice);
    final noticeText = noticeWidget.data ?? '';
    expect(
      noticeText,
      contains('iPad'),
    );
    expect(
      noticeText,
      contains('Android 16'),
    );
  });

  testWidgets('orientation controls fit compact landscape with large text',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await tester.pumpWidget(
      const MaterialApp(home: OrientationDemoPage(initialData: [])),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('orientation_controls_scroll_view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home demo launchers fit on narrow screens',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byKey(const Key('demo_navigation_wrap')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home page scrolls instead of overflowing in landscape',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byKey(const Key('home_scroll_view')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
