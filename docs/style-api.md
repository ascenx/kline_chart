# Style API

`KLineController.shared` exposes grouped style objects for chart appearance. Set these values before rebuilding `KLineView`.

```dart
final controller = KLineController.shared;

controller.chartStyle = const KLineChartStyle(
  backgroundColor: Color(0xff0b1016),
  gridLineColor: Color(0x223d4a5c),
  gridLineWidth: 1,
);

controller.candleStyle = const KLineCandleStyle(
  riseColor: Color(0xff22ab94),
  fallColor: Color(0xfff23645),
);
```

## Chart Style

`KLineChartStyle` controls the chart canvas, grid, labels, current price marker, and time chart line.

| Property | Type | Description |
| --- | --- | --- |
| `backgroundColor` | `Color` | Background color painted behind the entire chart. |
| `gridLineColor` | `Color` | Grid line color for vertical and horizontal ruler lines. |
| `gridLineWidth` | `double` | Grid line stroke width. |
| `rulerTextStyle` | `TextStyle` | Text style for price ruler labels. |
| `highLowLineColor` | `Color` | Line color for highest and lowest price callouts. |
| `highLowLineWidth` | `double` | Line stroke width for highest and lowest price callouts. |
| `highLowTextStyle` | `TextStyle` | Text style for highest and lowest price labels. |
| `currentPriceLineColor` | `Color` | Line and border color for the current price marker. |
| `currentPriceLineWidth` | `double` | Stroke width for the current price line and marker border. |
| `currentPriceBackgroundColor` | `Color` | Background color for the current price marker. |
| `currentPriceTextStyle` | `TextStyle` | Text style for the current price marker. |
| `timeLineColor` | `Color` | Line color for time chart mode. |
| `timeLineWidth` | `double` | Stroke width for time chart mode. |
| `timeLineFillColor` | `Color` | Fill color for the time chart area gradient. |

```dart
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
```

## Candle Style

`KLineCandleStyle` controls candlestick body and wick colors.

| Property | Type | Description |
| --- | --- | --- |
| `riseColor` | `Color` | Candle body color when close is greater than open. |
| `fallColor` | `Color` | Candle body color when close is less than or equal to open. |
| `riseWickColor` | `Color` | Candle wick color when close is greater than open. |
| `fallWickColor` | `Color` | Candle wick color when close is less than or equal to open. |
| `wickLineWidth` | `double` | Candle wick stroke width. |

```dart
controller.candleStyle = const KLineCandleStyle(
  riseColor: Color(0xff22ab94),
  fallColor: Color(0xfff23645),
  riseWickColor: Color(0xff22ab94),
  fallWickColor: Color(0xfff23645),
  wickLineWidth: 1.5,
);
```

## Volume Style

`KLineVolumeStyle` controls volume bar colors.

| Property | Type | Description |
| --- | --- | --- |
| `riseColor` | `Color` | Volume bar color when close is greater than open. |
| `fallColor` | `Color` | Volume bar color when close is less than or equal to open. |

```dart
controller.volumeStyle = const KLineVolumeStyle(
  riseColor: Color(0x6622ab94),
  fallColor: Color(0x66f23645),
);
```

## Crosshair Style

`KLineCrosshairStyle` controls the long-press crosshair.

| Property | Type | Description |
| --- | --- | --- |
| `color` | `Color` | Crosshair line color. |
| `strokeWidth` | `double` | Crosshair line stroke width. |

```dart
controller.crosshairStyle = const KLineCrosshairStyle(
  color: Color(0xff758696),
  strokeWidth: 1,
);
```

## Info Style

`KLineInfoStyle` controls the long-press candle detail overlay.

| Property | Type | Description |
| --- | --- | --- |
| `backgroundColor` | `Color` | Background color for the candle detail overlay. |
| `textStyle` | `TextStyle` | Text style for candle detail overlay rows. |

```dart
controller.infoStyle = const KLineInfoStyle(
  backgroundColor: Color(0xee111827),
  textStyle: TextStyle(color: Color(0xffd1d5db), fontSize: 12),
);
```

## Indicator Colors

Line indicators still use `indicatorColors` by default. SAR has a dedicated point color.

```dart
controller.indicatorColors = [
  Colors.orange,
  Colors.purple,
  Colors.blue,
];
controller.sarColor = Colors.orange;
```

## Number Formatting

Set optional formatter callbacks on `KLineController.shared` to customize
display text for prices, volume values, and indicator values. When a formatter
is not set, the chart keeps the built-in numeric formatting. The default volume
formatter uses `K`, `M`, and `B` suffixes for values of at least 1,000,
1,000,000, and 1,000,000,000.

| Property | Type | Description |
| --- | --- | --- |
| `priceFormatter` | `String Function(double value)?` | Formats price values such as open, high, low, close, price rulers, high/low labels, and the current price marker. |
| `volumeFormatter` | `String Function(double value)?` | Formats volume values such as candle volume, VOL rulers, and MAVOL values. |
| `indicatorFormatter` | `String Function(double value, IndicatorType type, int? period)?` | Formats indicator values such as MA, EMA, BOLL, SAR, MACD, KDJ, RSI, WR, and OBV. |

```dart
controller.priceFormatter = (value) => value.toStringAsFixed(4);

controller.volumeFormatter = (value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)}K';
  }
  return value.toStringAsFixed(2);
};

controller.indicatorFormatter = (value, type, period) {
  if (type == IndicatorType.macd) {
    return value.toStringAsFixed(6);
  }
  return value.toStringAsFixed(2);
};
```

## Partial Updates

Each style class supports `copyWith`.

```dart
controller.chartStyle = controller.chartStyle.copyWith(
  backgroundColor: const Color(0xff101820),
);

controller.candleStyle = controller.candleStyle.copyWith(
  riseColor: const Color(0xff22ab94),
  fallColor: const Color(0xfff23645),
);
```
