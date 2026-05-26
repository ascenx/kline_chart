# KLine Chart Usage Wiki

This document covers the full usage surface of `kline_chart`: data setup, chart rendering, indicator configuration, overlays, styles, number formatting, trailing blank space, interactions, dynamic updates, edge cases, and public API references.

## Table Of Contents

- [Installation And Import](#installation-and-import)
- [Minimal Setup](#minimal-setup)
- [Data Model](#data-model)
- [Render KLineView](#render-klineview)
- [Global Controller](#global-controller)
- [Main And Sub Indicators](#main-and-sub-indicators)
- [Indicator Parameters](#indicator-parameters)
- [Visible Window, Scroll, And Zoom](#visible-window-scroll-and-zoom)
- [Trailing Blank Space](#trailing-blank-space)
- [Number Formatting](#number-formatting)
- [Overlays And Markers](#overlays-and-markers)
- [Style Customization](#style-customization)
- [Chart Layout](#chart-layout)
- [Long Press Crosshair And Info Overlay](#long-press-crosshair-and-info-overlay)
- [Time Chart Mode](#time-chart-mode)
- [Time Axis](#time-axis)
- [Dynamic Data And Config Updates](#dynamic-data-and-config-updates)
- [Short Data And Edge Cases](#short-data-and-edge-cases)
- [Common Configuration Examples](#common-configuration-examples)
- [API Reference](#api-reference)
- [FAQ](#faq)

## Installation And Import

Add the package to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  kline_chart: ^1.0.1
```

Import the main package:

```dart
import 'package:kline_chart/kline_chart.dart';
```

The main package exports these public APIs:

- `KLineView`
- `KLineController`
- `KLineData`
- `KLineChartStyle`
- `KLineCandleStyle`
- `KLineVolumeStyle`
- `KLineCrosshairStyle`
- `KLineInfoStyle`
- `KLineOverlayStyle`
- `KLineOverlay`
- `KLinePriceLine`
- `KLinePriceZone`
- `KLineMarker`
- `KLineVerticalLine`
- `KLineTimeLabelGranularity`
- `KLineTimeFormatter`

## Minimal Setup

The smallest integration has two steps:

1. Assign market data with `KLineController.shared.setData`.
2. Render `KLineView`.

```dart
class KLinePage extends StatefulWidget {
  const KLinePage({super.key});

  @override
  State<KLinePage> createState() => _KLinePageState();
}

class _KLinePageState extends State<KLinePage> {
  @override
  void initState() {
    super.initState();
    KLineController.shared.setData([
      KLineData(
        open: 100,
        high: 108,
        low: 96,
        close: 104,
        volume: 12000,
        time: 1710000000000,
      ),
    ]);
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

If data is loaded asynchronously, set it on the controller. `KLineView`
listens to controller data updates and refreshes automatically.

```dart
Future<void> loadData() async {
  final data = await fetchKLineData();
  KLineController.shared.setData(data);
}
```

## Data Model

Each candle is represented by `KLineData`:

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

Fields:

| Field | Type | Description |
| --- | --- | --- |
| `open` | `double` | Open price |
| `high` | `double` | Highest price |
| `low` | `double` | Lowest price |
| `close` | `double` | Close price |
| `volume` | `double` | Trading volume |
| `time` | `int` | Unix timestamp in milliseconds |

If your API returns a Binance-like array format, convert it manually:

```dart
final dataList = jsonList.map<KLineData>((item) {
  return KLineData(
    open: double.parse(item[1] ?? '0'),
    high: double.parse(item[2] ?? '0'),
    low: double.parse(item[3] ?? '0'),
    close: double.parse(item[4] ?? '0'),
    volume: double.parse(item[5] ?? '0'),
    time: item[6] ?? 0,
  );
}).toList();

KLineController.shared.data = dataList;
```

If your API returns object-shaped data, `KLineData.fromJson` is available:

```dart
final data = KLineData.fromJson({
  'open': 100.0,
  'high': 110.0,
  'low': 95.0,
  'close': 105.0,
  'volume': 12345.0,
  'time': 1710000000000,
});
```

## Render KLineView

`KLineView` is the chart widget. By default it reads data and configuration
from `KLineController.shared`.

```dart
SizedBox(
  height: 400,
  child: KLineView(),
)
```

Give `KLineView` a clear height through `SizedBox`, `Container`, `Expanded`, or another constrained parent. Without a usable height, the chart cannot be painted correctly.

When `KLineController.shared.data` is empty, `KLineView` shows a loading
indicator. Data APIs such as `setData`, `append`, `updateLast`, and
`prependHistory` notify the view automatically.

To render an independent chart, pass a controller instance:

```dart
final controller = KLineController()
  ..data = dataList
  ..showMainIndicators = [IndicatorType.boll]
  ..showSubIndicators = [IndicatorType.vol, IndicatorType.macd];

SizedBox(
  height: 400,
  child: KLineView(controller: controller),
)
```

## Global Controller

`KLineController.shared` is the default shared configuration entry point. It
stores chart data, indicators, styles, formatters, layout options, and
interaction state for `KLineView()` when no controller is passed.

```dart
final controller = KLineController.shared;

controller.data = dataList;
controller.itemCount = 30;
controller.showMainIndicators = [IndicatorType.ma];
controller.showSubIndicators = [IndicatorType.vol, IndicatorType.macd];
```

`KLineController()` creates an independent controller instance:

```dart
final controller = KLineController();
```

Notes:

- `KLineView()` uses `KLineController.shared`.
- `KLineView(controller: controller)` uses the provided controller.
- `KLineController()` is appropriate when each chart needs separate data, indicators, style, formatters, scroll state, and long-press state.
- After changing `data` or configuration, trigger your state management rebuild if the page does not rebuild automatically.
- Multiple `KLineView()` instances without a controller still share `KLineController.shared`.

## Main And Sub Indicators

Indicators are represented by `IndicatorType`:

| Indicator | Area | Description |
| --- | --- | --- |
| `IndicatorType.ma` | Main chart | MA moving average |
| `IndicatorType.ema` | Main chart | EMA moving average |
| `IndicatorType.boll` | Main chart | BOLL bands |
| `IndicatorType.sar` | Main chart | SAR points |
| `IndicatorType.vol` | Sub chart | Volume bars |
| `IndicatorType.macd` | Sub chart | MACD bars and lines |
| `IndicatorType.kdj` | Sub chart | KDJ |
| `IndicatorType.rsi` | Sub chart | RSI |
| `IndicatorType.wr` | Sub chart | WR |
| `IndicatorType.obv` | Sub chart | OBV |
| `IndicatorType.maVol` | Internal sub value | Volume moving average, usually not configured directly |

Configure main indicators:

```dart
controller.showMainIndicators = [
  IndicatorType.ma,
];
```

Configure sub indicators:

```dart
controller.showSubIndicators = [
  IndicatorType.vol,
  IndicatorType.macd,
];
```

For a UI that toggles indicators, keep the selected indicators in state and write them back to the controller:

```dart
void toggleMainIndicator(IndicatorType type) {
  KLineController.shared.showMainIndicators = [type];
  setState(() {});
}

void toggleSubIndicator(IndicatorType type) {
  final indicators = [...KLineController.shared.showSubIndicators];
  if (indicators.contains(type)) {
    indicators.remove(type);
  } else {
    indicators.add(type);
  }
  KLineController.shared.showSubIndicators = indicators;
  setState(() {});
}
```

Convert a display name back to an enum value:

```dart
final type = IndicatorType.fromName('MACD');
```

## Indicator Parameters

Configurable indicator periods and parameters:

```dart
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

Parameters:

| Property | Default | Description |
| --- | --- | --- |
| `volMaPeriods` | `[7, 14]` | VOL moving-average periods |
| `macdPeriods` | `[12, 26, 9]` | MACD fast, slow, and signal periods |
| `kdjPeriods` | `[9, 3, 3]` | KDJ periods |
| `rsiPeriods` | `[6, 12, 24]` | RSI periods |
| `wrPeriods` | `[7, 14]` | WR periods |
| `bollPeriod` | `21` | BOLL period |
| `bollBandwidth` | `2` | BOLL bandwidth |
| `sarStart` | `0.02` | SAR acceleration factor start value |
| `sarIncrement` | `0.02` | SAR acceleration factor step value |
| `sarMax` | `0.2` | SAR maximum acceleration factor |
| `sarColor` | `Colors.orange` | SAR point color |

`indicatorColors` controls line indicator colors:

```dart
controller.indicatorColors = [
  Colors.orange,
  Colors.purple,
  Colors.blue,
];
```

## Visible Window, Scroll, And Zoom

The chart supports horizontal scrolling and pinch-to-zoom by default. The visible candle count is controlled by `itemCount`; the zoom range is controlled by `minCount` and `maxCount`.

```dart
controller.itemCount = 30;
controller.minCount = 7;
controller.maxCount = 39;
controller.spacing = 2.0;
```

Properties:

| Property | Default | Description |
| --- | --- | --- |
| `itemCount` | `30` | Number of visible candles on the current screen |
| `minCount` | `7` | Minimum visible candle count after zooming in |
| `maxCount` | `39` | Maximum visible candle count after zooming out |
| `spacing` | `2.0` | Spacing between candles |
| `itemWidth` | `0.0` | Current candle width, calculated by the chart |
| `klineMargin` | `EdgeInsets.zero` | Outer margin around the chart |

Smaller `itemCount` makes candles wider. Larger `itemCount` makes candles denser. Keep the values in a valid order:

```dart
controller.minCount <= controller.itemCount;
controller.itemCount <= controller.maxCount;
```

## Trailing Blank Space

Trading apps often keep some blank space to the right of the latest candle instead of placing it directly against the screen edge. These properties control that behavior:

```dart
controller.trailingBlankItemCount = 5;
controller.maxTrailingBlankItemCount = 20;
controller.minTrailingVisibleItemCount = 4;
```

Properties:

| Property | Default | Description |
| --- | --- | --- |
| `trailingBlankItemCount` | `5` | Empty candle slots shown after the latest data item at initial end alignment |
| `maxTrailingBlankItemCount` | `20` | Maximum empty candle slots that can be revealed by scrolling left |
| `minTrailingVisibleItemCount` | `4` | Minimum real candles kept visible at the trailing edge |

Behavior:

- On first render, the latest candle keeps 5 empty slots to its right.
- The user can scroll left to reveal up to 20 empty slots.
- At the far trailing edge, at least 4 real candles remain visible.

When the data set is short, the chart limits the effective blank space so real candles are not all scrolled out of view.

## Number Formatting

Prices, volumes, indicator values, and optional time axis labels can be
formatted independently.

```dart
controller.priceFormatter = (value) {
  return value.toStringAsFixed(4);
};

controller.volumeFormatter = (value) {
  if (value.abs() >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)}K';
  }
  return value.toStringAsFixed(2);
};

controller.indicatorFormatter = (value, type, period) {
  if (type == IndicatorType.macd) {
    return value.toStringAsFixed(6);
  }
  if (type == IndicatorType.rsi) {
    return value.toStringAsFixed(1);
  }
  return value.toStringAsFixed(2);
};

controller.timeFormatter = (time, granularity) {
  if (granularity == KLineTimeLabelGranularity.time) {
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.hour}:$minute';
  }
  return '${time.month}/${time.day}';
};
```

Formatting coverage:

| Property | Type | Applies To |
| --- | --- | --- |
| `priceFormatter` | `String Function(double value)?` | Open, high, low, close, price rulers, high/low labels, current price marker |
| `volumeFormatter` | `String Function(double value)?` | Candle volume, VOL rulers, MAVOL |
| `indicatorFormatter` | `String Function(double value, IndicatorType type, int? period)?` | MA, EMA, BOLL, SAR, MACD, KDJ, RSI, WR, OBV |
| `timeFormatter` | `String Function(DateTime time, KLineTimeLabelGranularity granularity)?` | Optional time axis labels |

Default formatting:

- Prices use `toStringAsFixed(2)`.
- The current price marker uses `toString()` unless `priceFormatter` is set.
- Volumes use compact `K`, `M`, and `B` suffixes.
- Indicator values use `toStringAsFixed(2)`.
- Time axis labels use `HH:mm`, `MM-dd`, `yyyy-MM`, or `yyyy` based on the visible time span.

## Overlays And Markers

Overlays are display-only annotations on the main chart. They are useful for
entry prices, stop-loss lines, support or resistance zones, trade markers, and
event lines. The first version does not support dragging or editing overlays,
and overlay prices do not expand the chart's price scale.

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
```

Overlay types:

| Type | Purpose |
| --- | --- |
| `KLinePriceLine` | Horizontal line at a fixed price |
| `KLinePriceZone` | Filled price range between two prices |
| `KLineMarker` | Buy, sell, or custom marker aligned to a candle time and price |
| `KLineVerticalLine` | Vertical event line aligned to a candle time |

Update overlays through the controller:

```dart
controller.overlays = overlays;
controller.setOverlays(overlays);
controller.clearOverlays();
```

`KLineMarker` and `KLineVerticalLine` match `time` to `KLineData.time`. If the
time does not exist in the data list or the marker is off-screen, the overlay is
skipped safely.

## Style Customization

Styles are grouped into separate style classes:

```dart
controller.chartStyle = const KLineChartStyle(
  backgroundColor: Color(0xff0b1016),
  gridLineColor: Color(0x223d4a5c),
  gridLineWidth: 1,
);

controller.candleStyle = const KLineCandleStyle(
  riseColor: Color(0xff22ab94),
  fallColor: Color(0xfff23645),
);

controller.volumeStyle = const KLineVolumeStyle(
  riseColor: Color(0x6622ab94),
  fallColor: Color(0x66f23645),
);

controller.crosshairStyle = const KLineCrosshairStyle(
  color: Color(0xff758696),
  strokeWidth: 1,
);

controller.infoStyle = const KLineInfoStyle(
  backgroundColor: Color(0xee111827),
  textStyle: TextStyle(color: Color(0xffd1d5db), fontSize: 12),
);

controller.overlayStyle = const KLineOverlayStyle(
  priceLineStrokeWidth: 1,
  zoneOpacity: 0.12,
  markerRadius: 6,
);
```

All style classes are immutable and support `copyWith`:

```dart
controller.chartStyle = controller.chartStyle.copyWith(
  backgroundColor: const Color(0xff101820),
);

controller.candleStyle = controller.candleStyle.copyWith(
  riseColor: const Color(0xff22ab94),
  fallColor: const Color(0xfff23645),
);
```

For every style field, see [Style API](style-api.md).

## Chart Layout

The main chart and sub-chart layout can be configured with:

```dart
controller.subIndicatorHeight = 50.0;
controller.indicatorSpacing = 10.0;
controller.indicatorInfoHeight = 15.0;
controller.mainIndicatorInfoMargin = 5.0;
controller.subIndicatorInfoMargin = 5.0;
```

Properties:

| Property | Default | Description |
| --- | --- | --- |
| `subIndicatorHeight` | `50.0` | Height of each sub-indicator area |
| `indicatorSpacing` | `10.0` | Spacing between the main chart and sub charts, and between sub charts |
| `indicatorInfoHeight` | `15.0` | Height of the indicator text area |
| `mainIndicatorInfoMargin` | `5.0` | Margin for main indicator info text |
| `subIndicatorInfoMargin` | `5.0` | Margin for sub indicator info text |

The main chart height is calculated from the widget height, margins, number of sub indicators, sub indicator height, and indicator spacing.

## Long Press Crosshair And Info Overlay

The chart includes built-in long-press interaction:

- Long press shows the crosshair.
- Moving the finger updates the selected candle.
- Tapping the chart clears the long-press position.
- Scrolling also clears the long-press position.

Crosshair style:

```dart
controller.crosshairStyle = const KLineCrosshairStyle(
  color: Color(0xff758696),
  strokeWidth: 1,
);
```

Info overlay style:

```dart
controller.infoStyle = const KLineInfoStyle(
  backgroundColor: Color(0xee111827),
  textStyle: TextStyle(color: Color(0xffd1d5db), fontSize: 12),
);
```

Info overlay size and border:

```dart
controller.infoWidgetMaxWidth = 130;
controller.infoWidgetMargin = const EdgeInsets.only(left: 8, top: 10);
controller.infoWidgetPadding = const EdgeInsets.all(4);
controller.infoWidgetBorderRadius = 4;
controller.infoWidgetBorder = Border.all(
  color: Colors.blueGrey.withValues(alpha: 0.5),
  width: 0.5,
);
```

To manually clear the long-press state, reset the offset:

```dart
controller.longPressOffset.update(Offset.zero);
```

## Time Chart Mode

Enable time chart mode:

```dart
controller.showTimeChart = true;
setState(() {});
```

Time chart colors are controlled by `KLineChartStyle`:

```dart
controller.chartStyle = controller.chartStyle.copyWith(
  timeLineColor: Colors.blue,
  timeLineWidth: 1,
  timeLineFillColor: const Color(0xff40c4ff),
);
```

Switch back to candlestick mode:

```dart
controller.showTimeChart = false;
setState(() {});
```

## Time Axis

The bottom time axis is optional and off by default to preserve existing chart
layout. When enabled, it reserves `timeAxisHeight` at the bottom, generates
sparse labels from visible candle timestamps, and chooses label granularity from
the current visible time span.

```dart
final controller = KLineController.shared;

controller.showTimeAxis = true;
controller.timeAxisHeight = 18;
controller.timeAxisMinLabelSpacing = 64;
controller.timeFormatter = (time, granularity) {
  if (granularity == KLineTimeLabelGranularity.time) {
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.hour}:$minute';
  }
  return '${time.month}-${time.day}';
};

setState(() {});
```

Price ruler ticks are adaptive by default. You can tune their density:

```dart
controller.priceAxisMaxTickCount = 5;
controller.priceAxisMinTickSpacing = 28;
```

## Dynamic Data And Config Updates

Set or replace the full data list:

```dart
final controller = KLineController.shared;

controller.setData(initialData);
```

Update the last candle from a real-time feed:

```dart
controller.updateLast(realtimeCandle);
```

If the controller has no data yet, `updateLast` appends the candle.

Append a newly closed period:

```dart
controller.append(nextPeriodCandle);
```

Prepend older history:

```dart
controller.prependHistory(olderCandles);
```

`prependHistory` keeps the current visible candles stable when used with
`KLineView`.

Clear data:

```dart
controller.clearData();
```

`controller.data = dataList` is still supported for backward compatibility and
also notifies `KLineView`, but it does not force the view back to the latest
candle. The named methods make real-time intent clearer.

Load older candles near the left edge:

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

Switch indicators:

```dart
controller.showMainIndicators = [IndicatorType.boll];
controller.showSubIndicators = [IndicatorType.vol, IndicatorType.rsi];
setState(() {});
```

Switch theme:

```dart
controller.chartStyle = const KLineChartStyle(
  backgroundColor: Color(0xff0b1016),
  gridLineColor: Color(0x223d4a5c),
  gridLineWidth: 1,
);
controller.candleStyle = const KLineCandleStyle(
  riseColor: Color(0xff22ab94),
  fallColor: Color(0xfff23645),
);
setState(() {});
```

## Short Data And Edge Cases

The chart includes guards for these cases:

- Empty data shows a loading indicator.
- Data shorter than `itemCount` has a limited scroll range.
- Trailing blank space cannot scroll all real candles out of view.
- Pinch zoom clamps the visible count by `minCount`, `maxCount`, and data length.
- Flat price data, zero volume data, and initial null indicator values are handled defensively.

Recommended data constraints:

- Sort candles by time from old to new.
- Ensure `high >= max(open, close)`.
- Ensure `low <= min(open, close)`.
- Use millisecond timestamps for `time`.
- Use positive values for `itemCount`, `minCount`, and `maxCount`.

## Common Configuration Examples

### Binance-Like Right Padding

```dart
final controller = KLineController.shared;

controller.itemCount = 60;
controller.trailingBlankItemCount = 5;
controller.maxTrailingBlankItemCount = 20;
controller.minTrailingVisibleItemCount = 4;
```

### Dark Trading Theme

```dart
final controller = KLineController.shared;

controller.chartStyle = const KLineChartStyle(
  backgroundColor: Color(0xff0b1016),
  gridLineColor: Color(0x223d4a5c),
  gridLineWidth: 1,
  rulerTextStyle: TextStyle(color: Color(0xff7f8ea3), fontSize: 12),
  highLowLineColor: Color(0xff7f8ea3),
  highLowTextStyle: TextStyle(color: Color(0xffc8d3e2), fontSize: 12),
  currentPriceLineColor: Color(0xffc8d3e2),
  currentPriceBackgroundColor: Color(0xff0b1016),
  currentPriceTextStyle: TextStyle(color: Color(0xffc8d3e2), fontSize: 12),
  timeLineColor: Color(0xff3b82f6),
  timeLineFillColor: Color(0xff1d4ed8),
);

controller.candleStyle = const KLineCandleStyle(
  riseColor: Color(0xff22ab94),
  fallColor: Color(0xfff23645),
  riseWickColor: Color(0xff22ab94),
  fallWickColor: Color(0xfff23645),
);

controller.volumeStyle = const KLineVolumeStyle(
  riseColor: Color(0x6622ab94),
  fallColor: Color(0x66f23645),
);
```

### Custom Price And Indicator Precision

```dart
controller.priceFormatter = (value) => value.toStringAsFixed(4);

controller.indicatorFormatter = (value, type, period) {
  switch (type) {
    case IndicatorType.macd:
      return value.toStringAsFixed(6);
    case IndicatorType.rsi:
    case IndicatorType.wr:
      return value.toStringAsFixed(1);
    default:
      return value.toStringAsFixed(2);
  }
};
```

### Volume K/M/B Formatting

```dart
controller.volumeFormatter = (value) {
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
};
```

## API Reference

### `KLineController`

| Property Or Method | Type | Default | Purpose |
| --- | --- | --- | --- |
| `data` | `List<KLineData>` | `[]` | Chart data |
| `setData(data)` | `void` | - | Replaces all chart data and notifies the view |
| `updateLast(data)` | `void` | - | Replaces the latest candle, or appends when data is empty |
| `append(data)` | `void` | - | Appends a newly closed candle and follows the latest candle when already aligned to the end |
| `prependHistory(data)` | `void` | - | Prepends older candles while keeping the current visible candles stable |
| `clearData()` | `void` | - | Clears all chart data and notifies the view |
| `lastDataChange` | `KLineDataChange?` | `null` | Metadata for the latest data update notification |
| `dataVersion` | `int` | `0` | Monotonic version incremented for each data update |
| `chartStyle` | `KLineChartStyle` | `const KLineChartStyle()` | Canvas, grid, price labels, and time chart style |
| `candleStyle` | `KLineCandleStyle` | `const KLineCandleStyle()` | Candlestick style |
| `volumeStyle` | `KLineVolumeStyle` | `const KLineVolumeStyle()` | Volume bar style |
| `crosshairStyle` | `KLineCrosshairStyle` | `const KLineCrosshairStyle()` | Long-press crosshair style |
| `infoStyle` | `KLineInfoStyle` | `const KLineInfoStyle()` | Long-press detail overlay style |
| `overlayStyle` | `KLineOverlayStyle` | `const KLineOverlayStyle()` | Display-only overlay style |
| `overlays` | `List<KLineOverlay>` | `[]` | Display-only overlays on the main chart |
| `setOverlays(overlays)` | `void` | - | Replaces overlays and notifies the view |
| `clearOverlays()` | `void` | - | Clears overlays and notifies the view |
| `overlayVersion` | `int` | `0` | Monotonic version incremented for each overlay update |
| `priceFormatter` | `KLineNumberFormatter?` | `null` | Price formatter |
| `volumeFormatter` | `KLineNumberFormatter?` | `null` | Volume formatter |
| `indicatorFormatter` | `KLineIndicatorFormatter?` | `null` | Indicator value formatter |
| `timeFormatter` | `KLineTimeFormatter?` | `null` | Time axis label formatter |
| `itemCount` | `double` | `30` | Current visible candle count |
| `trailingBlankItemCount` | `double` | `5` | Initial trailing blank candle slots |
| `maxTrailingBlankItemCount` | `double` | `20` | Maximum trailing blank candle slots |
| `minTrailingVisibleItemCount` | `double` | `4` | Minimum real candles kept visible at the trailing edge |
| `spacing` | `double` | `2.0` | Candle spacing |
| `itemWidth` | `double` | `0.0` | Current candle width, calculated internally |
| `klineMargin` | `EdgeInsets` | `EdgeInsets.zero` | Chart outer margin |
| `minCount` | `double` | `7` | Minimum visible count during zoom |
| `maxCount` | `double` | `39` | Maximum visible count during zoom |
| `mainIndicatorInfoMargin` | `double` | `5.0` | Main indicator info margin |
| `subIndicatorInfoMargin` | `double` | `5.0` | Sub indicator info margin |
| `priceAxisMaxTickCount` | `int` | `5` | Maximum generated price axis ticks |
| `priceAxisMinTickSpacing` | `double` | `28.0` | Minimum vertical spacing between price axis labels |
| `showTimeAxis` | `bool` | `false` | Whether to draw the bottom time axis |
| `timeAxisHeight` | `double` | `18.0` | Height reserved for the time axis when enabled |
| `timeAxisMinLabelSpacing` | `double` | `64.0` | Minimum horizontal spacing between time axis labels |
| `showTimeChart` | `bool` | `false` | Whether to render time chart mode |
| `infoWidgetMaxWidth` | `double?` | `130` | Max width of the long-press info overlay |
| `infoWidgetMargin` | `EdgeInsets` | `EdgeInsets.only(left: 8, top: 10)` | Long-press info overlay margin |
| `infoWidgetPadding` | `EdgeInsets` | `EdgeInsets.all(4)` | Long-press info overlay padding |
| `infoWidgetBorderRadius` | `double` | `4` | Long-press info overlay border radius |
| `infoWidgetBorder` | `Border` | semi-transparent blue-grey border | Long-press info overlay border |
| `longPressOffset` | `LongPressOffset` | `Offset.zero` | Current long-press position |
| `indicatorSpacing` | `double` | `10.0` | Indicator area spacing |
| `subIndicatorHeight` | `double` | `50.0` | Sub-indicator height |
| `indicatorInfoHeight` | `double` | `15.0` | Indicator info text height |
| `showMainIndicators` | `List<IndicatorType>` | `[ma]` | Main chart indicators |
| `showSubIndicators` | `List<IndicatorType>` | `[vol, kdj]` | Sub chart indicators |
| `bollPeriod` | `int` | `21` | BOLL period |
| `bollBandwidth` | `int` | `2` | BOLL bandwidth |
| `sarStart` | `double` | `0.02` | SAR acceleration factor start value |
| `sarIncrement` | `double` | `0.02` | SAR acceleration factor step value |
| `sarMax` | `double` | `0.2` | SAR maximum acceleration factor |
| `sarColor` | `Color` | `Colors.orange` | SAR point color |
| `volMaPeriods` | `List<int>` | `[7, 14]` | VOL moving-average periods |
| `macdPeriods` | `List<int>` | `[12, 26, 9]` | MACD periods |
| `kdjPeriods` | `List<int>` | `[9, 3, 3]` | KDJ periods |
| `rsiPeriods` | `List<int>` | `[6, 12, 24]` | RSI periods |
| `wrPeriods` | `List<int>` | `[7, 14]` | WR periods |
| `indicatorColors` | `List<Color>` | `[orange, purple, blue]` | Line indicator colors |
| `formatPrice(value)` | `String` | - | Runs price formatting |
| `formatCurrentPrice(value)` | `String` | - | Runs current price formatting |
| `formatVolume(value)` | `String` | - | Runs volume formatting |
| `formatIndicator(value, type, period)` | `String` | - | Runs indicator formatting |
| `formatTime(time, granularity)` | `String` | - | Runs time axis formatting |

### Formatter Types

| Type | Signature | Description |
| --- | --- | --- |
| `KLineNumberFormatter` | `String Function(double value)` | Formatter for price and volume values |
| `KLineIndicatorFormatter` | `String Function(double value, IndicatorType type, int? period)` | Formatter for indicator values, with access to indicator type and period |
| `KLineTimeFormatter` | `String Function(DateTime time, KLineTimeLabelGranularity granularity)` | Formatter for optional time axis labels |

### `KLineView`

| Constructor Argument | Type | Default | Purpose |
| --- | --- | --- | --- |
| `controller` | `KLineController?` | `KLineController.shared` | Data, configuration, interaction, and refresh source |
| `onLoadMore` | `Future<void> Function()?` | `null` | Called when scrolling near the leading edge |
| `loadMoreThreshold` | `int` | `3` | Leading-edge candle threshold for `onLoadMore` |

### Data Change Types

| Type | Description |
| --- | --- |
| `KLineDataChange` | Contains `type`, `previousLength`, `newLength`, `addedCount`, and `resetView` for the latest data update |
| `KLineDataChangeType.setData` | Full data replacement |
| `KLineDataChangeType.updateLast` | Latest candle replacement |
| `KLineDataChangeType.append` | New candle appended to the right |
| `KLineDataChangeType.prependHistory` | Older candles inserted at the left |
| `KLineDataChangeType.clear` | Data cleared |

### Overlay Types

| Type | Important Fields | Description |
| --- | --- | --- |
| `KLinePriceLine` | `price`, `label`, `color`, `strokeWidth` | Horizontal price line on the main chart |
| `KLinePriceZone` | `fromPrice`, `toPrice`, `label`, `color`, `opacity` | Filled price range on the main chart |
| `KLineMarker` | `time`, `price`, `type`, `label`, `color`, `radius` | Buy, sell, or custom marker aligned to a candle |
| `KLineVerticalLine` | `time`, `label`, `color`, `strokeWidth` | Vertical event line aligned to a candle |
| `KLineMarkerType.buy` | - | Buy marker type |
| `KLineMarkerType.sell` | - | Sell marker type |
| `KLineMarkerType.custom` | - | Custom marker type |

### `IndicatorType`

| Member Or Property | Description |
| --- | --- |
| `ma` | MA main chart indicator |
| `ema` | EMA main chart indicator |
| `boll` | BOLL main chart indicator |
| `sar` | SAR main chart indicator |
| `vol` | VOL sub chart indicator |
| `maVol` | Internal VOL moving-average indicator |
| `macd` | MACD sub chart indicator |
| `kdj` | KDJ sub chart indicator |
| `rsi` | RSI sub chart indicator |
| `wr` | WR sub chart indicator |
| `obv` | OBV sub chart indicator |
| `name` | Display name, such as `MACD` |
| `isMain` | Whether the indicator belongs to the main chart |
| `isLine` | Whether the indicator is drawn as a line |
| `IndicatorType.fromName(name)` | Converts a display name to an enum value, returning `IndicatorType.ma` if not found |

### Lower-Level Calculation Helpers

These methods are public but primarily used by chart internals, scrolling, zooming, drawing, and tests. Most app integrations do not need to call them directly.

| Method Or Type | Description |
| --- | --- |
| `KLineController.getItemWidth(totalWidth)` | Calculates candle width from container width and `itemCount` |
| `KLineController.dataIndexForLocalX(...)` | Converts a local x coordinate to a data index |
| `KLineController.itemCenterXForDataIndex(...)` | Calculates the candle center x coordinate for a data index |
| `KLineController.beginIndexForScrollOffset(...)` | Calculates the current begin index from scroll offset |
| `KLineController.maxBeginIndexFor(...)` | Calculates the maximum allowed begin index |
| `KLineController.effectiveTrailingBlankItemCountFor(...)` | Calculates effective trailing blank slots from visible count and minimum real visible count |
| `KLineController.zoomForScale(...)` | Calculates the next begin index and visible item count from pinch scale input |
| `KLineZoomResult` | Result of `zoomForScale`, containing `beginIndex` and `itemCount` |
| `LongPressOffset` | `ValueNotifier<Offset>` for long-press position, updated through `update(offset)` |

### Debug Helpers

These properties are mainly for drawing-area debugging. App integrations usually do not need them.

| Property Or Method | Type | Description |
| --- | --- | --- |
| `isDebug` | `bool` | Debug flag |
| `randomColor` | `Color` | Debug color |
| `drawDebugRect(canvas, rect, color)` | `void` | Draws a debug rectangle |

### `KLineChartStyle`

| Property | Description |
| --- | --- |
| `backgroundColor` | Chart background color |
| `gridLineColor` | Grid line color |
| `gridLineWidth` | Grid line width |
| `rulerTextStyle` | Price ruler text style |
| `highLowLineColor` | Highest and lowest price callout line color |
| `highLowLineWidth` | Highest and lowest price callout line width |
| `highLowTextStyle` | Highest and lowest price text style |
| `currentPriceLineColor` | Current price line and marker border color |
| `currentPriceLineWidth` | Current price line and marker border width |
| `currentPriceBackgroundColor` | Current price marker background color |
| `currentPriceTextStyle` | Current price text style |
| `timeLineColor` | Time chart line color |
| `timeLineWidth` | Time chart line width |
| `timeLineFillColor` | Time chart area fill color |

### `KLineCandleStyle`

| Property | Description |
| --- | --- |
| `riseColor` | Rising candle body color |
| `fallColor` | Falling or flat candle body color |
| `riseWickColor` | Rising candle wick color |
| `fallWickColor` | Falling or flat candle wick color |
| `wickLineWidth` | Wick line width |

### `KLineVolumeStyle`

| Property | Description |
| --- | --- |
| `riseColor` | Rising volume bar color |
| `fallColor` | Falling or flat volume bar color |

### `KLineCrosshairStyle`

| Property | Description |
| --- | --- |
| `color` | Crosshair color |
| `strokeWidth` | Crosshair line width |

### `KLineInfoStyle`

| Property | Description |
| --- | --- |
| `backgroundColor` | Long-press detail overlay background color |
| `textStyle` | Long-press detail overlay text style |

### `KLineOverlayStyle`

| Property | Description |
| --- | --- |
| `priceLineColor` | Default color for horizontal price lines |
| `priceLineStrokeWidth` | Default stroke width for horizontal price lines |
| `priceLineTextStyle` | Text style for price line labels |
| `priceLineLabelBackgroundColor` | Background color for price line labels |
| `priceLineLabelPadding` | Padding around price line label text |
| `priceLineLabelBorderRadius` | Border radius for price line labels |
| `zoneColor` | Default fill color for price zones |
| `zoneOpacity` | Default opacity for price zone fills |
| `zoneTextStyle` | Text style for price zone labels |
| `buyMarkerColor` | Default color for buy markers |
| `sellMarkerColor` | Default color for sell markers |
| `customMarkerColor` | Default color for custom markers |
| `markerTextColor` | Text color used inside markers |
| `markerRadius` | Default marker radius |
| `markerTextStyle` | Text style for marker labels |
| `verticalLineColor` | Default color for vertical event lines |
| `verticalLineStrokeWidth` | Default stroke width for vertical event lines |
| `verticalLineTextStyle` | Text style for vertical event line labels |

## FAQ

### Why does the chart still show loading after data is set?

Use `setData` when loading data asynchronously. `KLineView` listens to the
controller and refreshes automatically:

```dart
KLineController.shared.setData(dataList);
```

### Why do multiple charts affect each other's configuration?

Multiple `KLineView()` instances without an explicit controller use `KLineController.shared`. Pass a separate controller to each chart when they need independent state:

```dart
KLineView(controller: KLineController()..setData(dataList))
```

### Why is there blank space to the right of the latest candle?

This is controlled by `trailingBlankItemCount`, matching the common behavior of trading charts. Disable it if you do not need it:

```dart
controller.trailingBlankItemCount = 0;
controller.maxTrailingBlankItemCount = 0;
```

### How do I hide all sub charts?

```dart
controller.showSubIndicators = [];
setState(() {});
```

### How do I show only MACD as the sub chart?

```dart
controller.showSubIndicators = [IndicatorType.macd];
setState(() {});
```

### How do I set the SAR point color?

```dart
controller.sarColor = Colors.orange;
setState(() {});
```

### How do I customize volume units?

Set `volumeFormatter`:

```dart
controller.volumeFormatter = (value) {
  if (value >= 10000) {
    return '${(value / 10000).toStringAsFixed(2)}W';
  }
  return value.toStringAsFixed(2);
};
```

### How do I run the example app?

```bash
cd example
flutter run
```
