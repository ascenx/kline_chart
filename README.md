# KLine Chart

[English](README.md) | [简体中文](README.zh-CN.md) | [Usage Wiki](docs/wiki.md) | [中文 Wiki](docs/wiki.zh-CN.md) | [Style API](docs/style-api.md)

[![pub package](https://img.shields.io/pub/v/kline_chart?style=flat)](https://pub.dev/packages/kline_chart)
[![license](https://img.shields.io/github/license/AscenX/kline_chart?style=flat)](https://github.com/AscenX/kline_chart)

KLine Chart is a lightweight Flutter charting library for building interactive financial candlestick charts. It supports common technical indicators such as MA, EMA, BOLL, SAR, VOL, MACD, KDJ, RSI, WR, and OBV, along with smooth scrolling, zooming, long-press crosshair interaction, and detailed price/indicator overlays.

It is designed for crypto, stock, and trading-related apps that need a customizable, responsive K-line chart component.

## Demo

![KLine Chart demo](https://github.com/AscenX/kline_chart/blob/main/example/demo.gif?raw=true)

## Features

- Candlestick and time chart modes.
- Smooth horizontal scrolling and pinch-to-zoom.
- Long-press crosshair with candle detail overlay.
- Main indicators: MA, EMA, BOLL, SAR.
- Sub indicators: VOL, MACD, KDJ, RSI, WR, OBV.
- Configurable indicator periods, colors, spacing, and visible item count.
- Adaptive price axis ticks and optional bottom time axis labels.
- Data lifecycle APIs for initial data, real-time last-candle updates, appends,
  prepended history, and automatic chart refresh.
- Optional `onLoadMore` callback for loading older candles near the leading edge.
- Display-only overlays for price lines, price zones, candle markers, and event
  lines.
- Rendering stability for short data sets, flat price data, and zero volume data.

## Installation

Requires Dart 2.17 or later and Flutter 3.0 or later.

Add the package to your Flutter project:

```yaml
dependencies:
  kline_chart: ^1.0.2
```

Then import it:

```dart
import 'package:kline_chart/kline_chart.dart';
```

## Quick Start

Provide K-line data through `KLineController.shared.setData`, then render
`KLineView`.

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:kline_chart/kline_chart.dart';

class KLinePage extends StatefulWidget {
  const KLinePage({super.key});

  @override
  State<KLinePage> createState() => _KLinePageState();
}

class _KLinePageState extends State<KLinePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final jsonStr = await rootBundle.loadString('assets/kline.json');
    final jsonList = json.decode(jsonStr) as List;

    KLineController.shared.setData(jsonList.map((item) {
      return KLineData(
        open: double.parse(item[1] ?? '0'),
        high: double.parse(item[2] ?? '0'),
        low: double.parse(item[3] ?? '0'),
        close: double.parse(item[4] ?? '0'),
        volume: double.parse(item[5] ?? '0'),
        time: item[6] ?? 0,
      );
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: KLineView(),
    );
  }
}
```

## Independent Controllers

`KLineView()` uses `KLineController.shared` by default for backward
compatibility. To render multiple independent charts, create a controller
instance and pass it to the view.

```dart
final controller = KLineController()
  ..setData(dataList)
  ..showMainIndicators = [IndicatorType.boll]
  ..showSubIndicators = [IndicatorType.vol, IndicatorType.macd];

SizedBox(
  height: 400,
  child: KLineView(controller: controller),
)
```

Use `KLineController.shared` when you want one shared global chart
configuration. Use `KLineController()` when each chart needs separate data,
indicators, style, formatters, scroll state, and long-press state.

## Data Updates And Loading History

`KLineView` listens to its controller, so these data APIs refresh the chart
without requiring an outer `setState`.

```dart
final controller = KLineController.shared;

controller.setData(initialData);
controller.updateLast(realtimeCandle);
controller.append(nextPeriodCandle);
controller.prependHistory(olderCandles);
controller.clearData();
```

`controller.data` is a read-only view. Use the lifecycle methods above to
change chart data so listeners and indicator caches are updated correctly.

Use `onLoadMore` to request older candles when the user scrolls near the left
edge. After loading, call `prependHistory`; the chart keeps the current visible
candles stable.

```dart
KLineView(
  controller: controller,
  loadMoreThreshold: 2,
  onLoadMore: () async {
    final olderCandles = await fetchOlderCandles();
    controller.prependHistory(olderCandles);
  },
)
```

## Overlays And Markers

Use overlays to display business annotations such as entry prices, support
zones, buy or sell markers, and event lines. Overlays are display-only and do
not change the chart's price scale.

```dart
controller.setOverlays([
  KLinePriceLine(
    price: 64200,
    label: 'Entry',
    color: Colors.blue,
  ),
  KLinePriceZone(
    fromPrice: 60000,
    toPrice: 61000,
    label: 'Support',
    color: Colors.green,
  ),
  KLineMarker(
    time: 1710000000000,
    price: 63500,
    type: KLineMarkerType.buy,
  ),
  KLineVerticalLine(
    time: 1710000000000,
    label: 'Event',
    color: Colors.orange,
  ),
]);

controller.clearOverlays();
```

## Indicator Configuration

`KLineController.shared` is the default shared configuration object. For
independent charts, configure the controller instance passed to `KLineView`.

```dart
final controller = KLineController.shared;

controller.showMainIndicators = [IndicatorType.ma];
controller.showSubIndicators = [
  IndicatorType.vol,
  IndicatorType.macd,
];

controller.volMaPeriods = [7, 14];
controller.macdPeriods = [12, 26, 9];
controller.kdjPeriods = [9, 3, 3];
controller.rsiPeriods = [6, 12, 24];
controller.wrPeriods = [7, 14];
controller.bollPeriod = 21;
controller.bollBandwidth = 2;
controller.sarStart = 0.02;
controller.sarIncrement = 0.02;
controller.sarMax = 0.2;
controller.sarColor = Colors.orange;
```

Available indicator types:

| Area | Indicators |
| --- | --- |
| Main chart | `ma`, `ema`, `boll`, `sar` |
| Sub chart | `vol`, `macd`, `kdj`, `rsi`, `wr`, `obv` |

## Chart Configuration

```dart
final controller = KLineController.shared;

controller.itemCount = 30;
controller.minCount = 7;
controller.maxCount = 39;
controller.spacing = 2.0;
controller.showTimeChart = false;
controller.showTimeAxis = false;
controller.timeAxisHeight = 18.0;
controller.timeAxisMinLabelSpacing = 64.0;
controller.priceAxisMaxTickCount = 5;
controller.priceAxisMinTickSpacing = 28.0;

controller.klineMargin = const EdgeInsets.all(0);
controller.subIndicatorHeight = 50.0;
controller.indicatorSpacing = 10.0;
controller.indicatorColors = [
  Colors.orange,
  Colors.purple,
  Colors.blue,
];
controller.sarColor = Colors.orange;
```

For detailed style properties and examples, see [Style API](docs/style-api.md).

## Data Model

Each candle is represented by `KLineData`.

```dart
KLineData(
  open: 100.0,
  high: 110.0,
  low: 95.0,
  close: 105.0,
  volume: 12345.0,
  time: 1710000000000,
);
```

The `time` value is expected to be a Unix timestamp in milliseconds.

## Example

The repository includes a runnable example app under `example/`.

```bash
cd example
flutter run
```

## Roadmap

- Improved responsive behavior across screen sizes.
- Continued performance optimization.
