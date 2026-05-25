# KLine Chart 使用 Wiki

这份文档面向接入方，覆盖 `kline_chart` 的完整使用方式：数据接入、图表渲染、指标配置、样式定制、数字格式化、右侧空白、交互行为和常见问题。

## 目录

- [安装和导入](#安装和导入)
- [最小接入流程](#最小接入流程)
- [数据模型](#数据模型)
- [渲染 KLineView](#渲染-klineview)
- [全局控制器](#全局控制器)
- [主图和副图指标](#主图和副图指标)
- [可视窗口、滚动和缩放](#可视窗口滚动和缩放)
- [右侧预留空白](#右侧预留空白)
- [数字格式化](#数字格式化)
- [样式定制](#样式定制)
- [长按十字线和信息浮层](#长按十字线和信息浮层)
- [分时图模式](#分时图模式)
- [动态更新数据和配置](#动态更新数据和配置)
- [短数据和边界行为](#短数据和边界行为)
- [常见配置示例](#常见配置示例)
- [API 速查](#api-速查)
- [常见问题](#常见问题)

## 安装和导入

在 Flutter 项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  kline_chart: ^1.0.0
```

导入主包：

```dart
import 'package:kline_chart/kline_chart.dart';
```

主包会导出以下公开 API：

- `KLineView`
- `KLineController`
- `KLineData`
- `KLineChartStyle`
- `KLineCandleStyle`
- `KLineVolumeStyle`
- `KLineCrosshairStyle`
- `KLineInfoStyle`

## 最小接入流程

最小接入只需要两步：

1. 把行情数据写入 `KLineController.shared.data`。
2. 在页面中渲染 `KLineView`。

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
    KLineController.shared.data = [
      KLineData(
        open: 100,
        high: 108,
        low: 96,
        close: 104,
        volume: 12000,
        time: 1710000000000,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 400,
      child: KLineView(),
    );
  }
}
```

如果数据是异步加载的，需要在数据写入后触发页面刷新：

```dart
Future<void> loadData() async {
  final data = await fetchKLineData();
  KLineController.shared.data = data;
  setState(() {});
}
```

## 数据模型

每一根 K 线使用 `KLineData` 表示：

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

字段说明：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `open` | `double` | 开盘价 |
| `high` | `double` | 最高价 |
| `low` | `double` | 最低价 |
| `close` | `double` | 收盘价 |
| `volume` | `double` | 成交量 |
| `time` | `int` | 毫秒级 Unix 时间戳 |

如果服务端返回的是 Binance 这类数组格式，可以手动转换：

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

如果服务端返回的是对象格式，也可以使用 `KLineData.fromJson`：

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

## 渲染 KLineView

`KLineView` 是图表入口 Widget。默认情况下，它会读取 `KLineController.shared` 中的数据和配置。

```dart
SizedBox(
  height: 400,
  child: KLineView(),
)
```

推荐给 `KLineView` 一个明确高度，例如 `SizedBox`、`Container`、`Expanded` 或外层布局约束。没有可用高度时，图表无法正确绘制。

当 `KLineController.shared.data` 为空时，`KLineView` 会显示一个加载状态。数据写入后，业务页面需要触发一次 rebuild。

如果需要渲染互不影响的独立图表，可以传入 controller 实例：

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

## 全局控制器

`KLineController.shared` 是默认共享配置入口。当 `KLineView()` 没有传入 controller 时，会使用它保存数据、指标、样式、格式化和交互相关参数。

```dart
final controller = KLineController.shared;

controller.data = dataList;
controller.itemCount = 30;
controller.showMainIndicators = [IndicatorType.ma];
controller.showSubIndicators = [IndicatorType.vol, IndicatorType.macd];
```

`KLineController()` 会创建独立 controller 实例：

```dart
final controller = KLineController();
```

注意事项：

- `KLineView()` 使用 `KLineController.shared`。
- `KLineView(controller: controller)` 使用传入的 controller。
- 当每个图表需要独立的数据、指标、样式、格式化、滚动状态和长按状态时，使用 `KLineController()`。
- 修改 `data` 或配置后，如果页面没有自动 rebuild，需要业务侧调用 `setState` 或触发状态管理刷新。
- 同一个页面如果渲染多个未传 controller 的 `KLineView()`，它们仍然会共享 `KLineController.shared`。

## 主图和副图指标

指标由 `IndicatorType` 表示：

| 指标 | 区域 | 说明 |
| --- | --- | --- |
| `IndicatorType.ma` | 主图 | MA 均线 |
| `IndicatorType.ema` | 主图 | EMA 均线 |
| `IndicatorType.boll` | 主图 | BOLL 布林线 |
| `IndicatorType.sar` | 主图 | SAR 点状指标 |
| `IndicatorType.vol` | 副图 | 成交量柱 |
| `IndicatorType.macd` | 副图 | MACD 柱和线 |
| `IndicatorType.kdj` | 副图 | KDJ |
| `IndicatorType.rsi` | 副图 | RSI |
| `IndicatorType.wr` | 副图 | WR |
| `IndicatorType.obv` | 副图 | OBV |
| `IndicatorType.maVol` | 副图内部值 | VOL 均量线使用，通常不需要直接配置 |

配置主图指标：

```dart
controller.showMainIndicators = [
  IndicatorType.ma,
];
```

配置副图指标：

```dart
controller.showSubIndicators = [
  IndicatorType.vol,
  IndicatorType.macd,
];
```

如果要实现点击切换指标，可以保存当前选择，再写回 controller：

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

从指标名称恢复枚举：

```dart
final type = IndicatorType.fromName('MACD');
```

## 指标参数

可配置的指标周期和参数如下：

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

参数说明：

| 属性 | 默认值 | 说明 |
| --- | --- | --- |
| `volMaPeriods` | `[7, 14]` | VOL 均量线周期 |
| `macdPeriods` | `[12, 26, 9]` | MACD 快线、慢线、信号线周期 |
| `kdjPeriods` | `[9, 3, 3]` | KDJ 周期 |
| `rsiPeriods` | `[6, 12, 24]` | RSI 周期 |
| `wrPeriods` | `[7, 14]` | WR 周期 |
| `bollPeriod` | `21` | BOLL 计算周期 |
| `bollBandwidth` | `2` | BOLL 带宽 |
| `sarStart` | `0.02` | SAR 加速因子起始值 |
| `sarIncrement` | `0.02` | SAR 加速因子步进值 |
| `sarMax` | `0.2` | SAR 最大加速因子 |
| `sarColor` | `Colors.orange` | SAR 点颜色 |

`indicatorColors` 用于线型指标的颜色：

```dart
controller.indicatorColors = [
  Colors.orange,
  Colors.purple,
  Colors.blue,
];
```

## 可视窗口、滚动和缩放

图表默认支持横向滚动和双指缩放。可见 K 线数量由 `itemCount` 控制，缩放范围由 `minCount` 和 `maxCount` 控制。

```dart
controller.itemCount = 30;
controller.minCount = 7;
controller.maxCount = 39;
controller.spacing = 2.0;
```

参数说明：

| 属性 | 默认值 | 说明 |
| --- | --- | --- |
| `itemCount` | `30` | 当前屏幕可见 K 线数量 |
| `minCount` | `7` | 双指放大后最少可见 K 线数量 |
| `maxCount` | `39` | 双指缩小后最多可见 K 线数量 |
| `spacing` | `2.0` | 每根 K 线之间的间距 |
| `itemWidth` | `0.0` | 当前 K 线宽度，由图表根据宽度计算，通常不需要手动设置 |
| `klineMargin` | `EdgeInsets.zero` | 图表外边距 |

`itemCount` 越小，蜡烛越宽；`itemCount` 越大，蜡烛越密。建议保证：

```dart
controller.minCount <= controller.itemCount;
controller.itemCount <= controller.maxCount;
```

## 右侧预留空白

交易类 App 通常不会让最新 K 线贴紧屏幕右边缘，而是在右侧保留一定空白。可以通过以下参数控制：

```dart
controller.trailingBlankItemCount = 5;
controller.maxTrailingBlankItemCount = 20;
controller.minTrailingVisibleItemCount = 4;
```

参数说明：

| 属性 | 默认值 | 说明 |
| --- | --- | --- |
| `trailingBlankItemCount` | `5` | 初始对齐到最新数据时，右侧预留的空白周期数 |
| `maxTrailingBlankItemCount` | `20` | 用户继续向左滑动时，最多可露出的右侧空白周期数 |
| `minTrailingVisibleItemCount` | `4` | 滑到最右边界时，屏幕内至少保留的真实 K 线数量 |

示例效果：

- 初始进入页面时，最新 K 线右侧保留 5 个周期的空白。
- 继续向左滑动时，右侧空白最多扩展到 20 个周期。
- 即使滑到最右边界，也至少保留 4 根真实 K 线可见。

当数据量比较少时，组件会自动限制有效空白数量，避免真实 K 线全部被滑出屏幕。

## 数字格式化

价格、成交量、指标值可以分别格式化。

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
```

格式化范围：

| 属性 | 类型 | 覆盖范围 |
| --- | --- | --- |
| `priceFormatter` | `String Function(double value)?` | 开高低收、价格刻度、最高最低价、现价标记 |
| `volumeFormatter` | `String Function(double value)?` | 成交量、VOL 刻度、MAVOL |
| `indicatorFormatter` | `String Function(double value, IndicatorType type, int? period)?` | MA、EMA、BOLL、SAR、MACD、KDJ、RSI、WR、OBV |

默认格式：

- 价格默认使用 `toStringAsFixed(2)`。
- 当前价标记默认使用 `toString()`，如果设置了 `priceFormatter`，也会走自定义格式。
- 成交量默认按 `K`、`M`、`B` 做紧凑格式化。
- 指标值默认使用 `toStringAsFixed(2)`。

## 样式定制

样式按模块拆分在几个 style 类中：

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
```

所有 style 类都是不可变对象，支持 `copyWith`：

```dart
controller.chartStyle = controller.chartStyle.copyWith(
  backgroundColor: const Color(0xff101820),
);

controller.candleStyle = controller.candleStyle.copyWith(
  riseColor: const Color(0xff22ab94),
  fallColor: const Color(0xfff23645),
);
```

完整样式字段请参考 [Style API](style-api.md)。

## 图表布局

主图和副图的布局可以通过以下参数控制：

```dart
controller.subIndicatorHeight = 50.0;
controller.indicatorSpacing = 10.0;
controller.indicatorInfoHeight = 15.0;
controller.mainIndicatorInfoMargin = 5.0;
controller.subIndicatorInfoMargin = 5.0;
```

参数说明：

| 属性 | 默认值 | 说明 |
| --- | --- | --- |
| `subIndicatorHeight` | `50.0` | 每个副图指标区域的高度 |
| `indicatorSpacing` | `10.0` | 主图和副图、副图和副图之间的间距 |
| `indicatorInfoHeight` | `15.0` | 指标信息文字区域高度 |
| `mainIndicatorInfoMargin` | `5.0` | 主图指标信息边距 |
| `subIndicatorInfoMargin` | `5.0` | 副图指标信息边距 |

主图高度会根据组件总高度、外边距、副图数量、副图高度和指标间距自动计算。

## 长按十字线和信息浮层

图表内置长按交互：

- 长按显示十字线。
- 移动手指更新选中的 K 线。
- 点击图表会清除长按位置。
- 滚动时也会自动清除长按位置。

十字线样式：

```dart
controller.crosshairStyle = const KLineCrosshairStyle(
  color: Color(0xff758696),
  strokeWidth: 1,
);
```

信息浮层样式：

```dart
controller.infoStyle = const KLineInfoStyle(
  backgroundColor: Color(0xee111827),
  textStyle: TextStyle(color: Color(0xffd1d5db), fontSize: 12),
);
```

信息浮层尺寸和边框：

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

如果需要手动清除长按状态，可以把偏移重置为 `Offset.zero`：

```dart
controller.longPressOffset.update(Offset.zero);
```

## 分时图模式

开启分时图模式后，主图会按分时线方式绘制：

```dart
controller.showTimeChart = true;
setState(() {});
```

分时图颜色由 `KLineChartStyle` 中的字段控制：

```dart
controller.chartStyle = controller.chartStyle.copyWith(
  timeLineColor: Colors.blue,
  timeLineWidth: 1,
  timeLineFillColor: const Color(0xff40c4ff),
);
```

切回蜡烛图：

```dart
controller.showTimeChart = false;
setState(() {});
```

## 动态更新数据和配置

追加最新 K 线：

```dart
final controller = KLineController.shared;

controller.data = [
  ...controller.data,
  newKLineData,
];
setState(() {});
```

更新最后一根 K 线：

```dart
final controller = KLineController.shared;
final data = [...controller.data];

if (data.isNotEmpty) {
  data[data.length - 1] = updatedKLineData;
  controller.data = data;
  setState(() {});
}
```

切换指标：

```dart
controller.showMainIndicators = [IndicatorType.boll];
controller.showSubIndicators = [IndicatorType.vol, IndicatorType.rsi];
setState(() {});
```

切换主题：

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

## 短数据和边界行为

组件对以下边界做了保护：

- 数据为空时显示加载状态。
- 数据少于 `itemCount` 时，图表会限制可滚动范围。
- 右侧空白不会把所有真实 K 线都滑出屏幕。
- 双指缩放时会把可见数量限制在 `minCount`、`maxCount` 和数据长度范围内。
- 价格相同、成交量为 0、指标前置空值等场景会尽量稳定绘制。

建议业务侧仍然保证：

- K 线数据按时间从旧到新排序。
- `high >= max(open, close)`。
- `low <= min(open, close)`。
- `time` 使用毫秒级时间戳。
- `itemCount`、`minCount`、`maxCount` 使用正数。

## 常见配置示例

### Binance 风格右侧留白

```dart
final controller = KLineController.shared;

controller.itemCount = 60;
controller.trailingBlankItemCount = 5;
controller.maxTrailingBlankItemCount = 20;
controller.minTrailingVisibleItemCount = 4;
```

### 暗色交易盘主题

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

### 自定义价格和指标精度

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

### 成交量 K/M/B 展示

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

## API 速查

### `KLineController`

| 属性或方法 | 类型 | 默认值 | 用途 |
| --- | --- | --- | --- |
| `data` | `List<KLineData>` | `[]` | 图表数据 |
| `chartStyle` | `KLineChartStyle` | `const KLineChartStyle()` | 图表画布、网格、价格标签、分时线样式 |
| `candleStyle` | `KLineCandleStyle` | `const KLineCandleStyle()` | 蜡烛图样式 |
| `volumeStyle` | `KLineVolumeStyle` | `const KLineVolumeStyle()` | 成交量柱样式 |
| `crosshairStyle` | `KLineCrosshairStyle` | `const KLineCrosshairStyle()` | 长按十字线样式 |
| `infoStyle` | `KLineInfoStyle` | `const KLineInfoStyle()` | 长按详情浮层样式 |
| `priceFormatter` | `KLineNumberFormatter?` | `null` | 价格格式化 |
| `volumeFormatter` | `KLineNumberFormatter?` | `null` | 成交量格式化 |
| `indicatorFormatter` | `KLineIndicatorFormatter?` | `null` | 指标值格式化 |
| `itemCount` | `double` | `30` | 当前可见 K 线数量 |
| `trailingBlankItemCount` | `double` | `5` | 初始右侧空白周期数 |
| `maxTrailingBlankItemCount` | `double` | `20` | 最大右侧空白周期数 |
| `minTrailingVisibleItemCount` | `double` | `4` | 右侧边界至少保留的真实 K 线数量 |
| `spacing` | `double` | `2.0` | K 线间距 |
| `itemWidth` | `double` | `0.0` | 当前 K 线宽度，内部计算 |
| `klineMargin` | `EdgeInsets` | `EdgeInsets.zero` | 图表外边距 |
| `minCount` | `double` | `7` | 缩放最少可见数量 |
| `maxCount` | `double` | `39` | 缩放最多可见数量 |
| `mainIndicatorInfoMargin` | `double` | `5.0` | 主图指标信息边距 |
| `subIndicatorInfoMargin` | `double` | `5.0` | 副图指标信息边距 |
| `showTimeChart` | `bool` | `false` | 是否显示分时图 |
| `infoWidgetMaxWidth` | `double?` | `130` | 长按详情浮层最大宽度 |
| `infoWidgetMargin` | `EdgeInsets` | `EdgeInsets.only(left: 8, top: 10)` | 长按详情浮层外边距 |
| `infoWidgetPadding` | `EdgeInsets` | `EdgeInsets.all(4)` | 长按详情浮层内边距 |
| `infoWidgetBorderRadius` | `double` | `4` | 长按详情浮层圆角 |
| `infoWidgetBorder` | `Border` | 蓝灰色半透明边框 | 长按详情浮层边框 |
| `longPressOffset` | `LongPressOffset` | `Offset.zero` | 当前长按位置 |
| `indicatorSpacing` | `double` | `10.0` | 指标区域间距 |
| `subIndicatorHeight` | `double` | `50.0` | 副图指标高度 |
| `indicatorInfoHeight` | `double` | `15.0` | 指标信息高度 |
| `showMainIndicators` | `List<IndicatorType>` | `[ma]` | 主图指标 |
| `showSubIndicators` | `List<IndicatorType>` | `[vol, kdj]` | 副图指标 |
| `bollPeriod` | `int` | `21` | BOLL 周期 |
| `bollBandwidth` | `int` | `2` | BOLL 带宽 |
| `sarStart` | `double` | `0.02` | SAR 加速因子起始值 |
| `sarIncrement` | `double` | `0.02` | SAR 加速因子步进值 |
| `sarMax` | `double` | `0.2` | SAR 最大加速因子 |
| `sarColor` | `Color` | `Colors.orange` | SAR 点颜色 |
| `volMaPeriods` | `List<int>` | `[7, 14]` | VOL 均线周期 |
| `macdPeriods` | `List<int>` | `[12, 26, 9]` | MACD 周期 |
| `kdjPeriods` | `List<int>` | `[9, 3, 3]` | KDJ 周期 |
| `rsiPeriods` | `List<int>` | `[6, 12, 24]` | RSI 周期 |
| `wrPeriods` | `List<int>` | `[7, 14]` | WR 周期 |
| `indicatorColors` | `List<Color>` | `[orange, purple, blue]` | 线型指标颜色 |
| `formatPrice(value)` | `String` | - | 执行价格格式化 |
| `formatCurrentPrice(value)` | `String` | - | 执行当前价格式化 |
| `formatVolume(value)` | `String` | - | 执行成交量格式化 |
| `formatIndicator(value, type, period)` | `String` | - | 执行指标格式化 |

### 格式化类型

| 类型 | 签名 | 说明 |
| --- | --- | --- |
| `KLineNumberFormatter` | `String Function(double value)` | 价格和成交量格式化函数 |
| `KLineIndicatorFormatter` | `String Function(double value, IndicatorType type, int? period)` | 指标值格式化函数，可根据指标类型和周期返回不同展示文本 |

### `IndicatorType`

| 成员或属性 | 说明 |
| --- | --- |
| `ma` | MA 主图指标 |
| `ema` | EMA 主图指标 |
| `boll` | BOLL 主图指标 |
| `sar` | SAR 主图指标 |
| `vol` | VOL 副图指标 |
| `maVol` | VOL 均量线内部指标 |
| `macd` | MACD 副图指标 |
| `kdj` | KDJ 副图指标 |
| `rsi` | RSI 副图指标 |
| `wr` | WR 副图指标 |
| `obv` | OBV 副图指标 |
| `name` | 指标显示名称，例如 `MACD` |
| `isMain` | 是否属于主图指标 |
| `isLine` | 是否为线型指标 |
| `IndicatorType.fromName(name)` | 按显示名称转换为枚举，找不到时返回 `IndicatorType.ma` |

### 低层计算方法

这些方法是公开的，但主要服务于图表内部绘制、滚动、缩放和测试。业务接入通常只需要配置 controller，不需要直接调用。

| 方法或类型 | 说明 |
| --- | --- |
| `KLineController.getItemWidth(totalWidth)` | 根据容器宽度和 `itemCount` 计算单根 K 线宽度 |
| `KLineController.dataIndexForLocalX(...)` | 根据局部 x 坐标计算对应的数据索引 |
| `KLineController.itemCenterXForDataIndex(...)` | 根据数据索引计算 K 线中心点 x 坐标 |
| `KLineController.beginIndexForScrollOffset(...)` | 根据滚动偏移计算当前起始数据索引 |
| `KLineController.maxBeginIndexFor(...)` | 计算允许滚动到的最大起始索引 |
| `KLineController.effectiveTrailingBlankItemCountFor(...)` | 根据可见数量和最少保留真实 K 线数计算有效右侧空白 |
| `KLineController.zoomForScale(...)` | 根据双指缩放参数计算新的起始索引和可见数量 |
| `KLineZoomResult` | `zoomForScale` 的返回值，包含 `beginIndex` 和 `itemCount` |
| `LongPressOffset` | 长按位置的 `ValueNotifier<Offset>`，可通过 `update(offset)` 更新 |

### 调试辅助

以下属性主要用于调试绘制区域，业务接入通常不需要使用：

| 属性或方法 | 类型 | 说明 |
| --- | --- | --- |
| `isDebug` | `bool` | 是否开启调试标记 |
| `randomColor` | `Color` | 调试颜色 |
| `drawDebugRect(canvas, rect, color)` | `void` | 绘制调试矩形 |

### `KLineChartStyle`

| 属性 | 说明 |
| --- | --- |
| `backgroundColor` | 图表背景色 |
| `gridLineColor` | 网格线颜色 |
| `gridLineWidth` | 网格线宽度 |
| `rulerTextStyle` | 价格刻度文字样式 |
| `highLowLineColor` | 最高价、最低价标注线颜色 |
| `highLowLineWidth` | 最高价、最低价标注线宽度 |
| `highLowTextStyle` | 最高价、最低价文字样式 |
| `currentPriceLineColor` | 当前价线和标记边框颜色 |
| `currentPriceLineWidth` | 当前价线和标记边框宽度 |
| `currentPriceBackgroundColor` | 当前价标记背景色 |
| `currentPriceTextStyle` | 当前价文字样式 |
| `timeLineColor` | 分时线颜色 |
| `timeLineWidth` | 分时线宽度 |
| `timeLineFillColor` | 分时区域填充色 |

### `KLineCandleStyle`

| 属性 | 说明 |
| --- | --- |
| `riseColor` | 上涨蜡烛实体颜色 |
| `fallColor` | 下跌或平盘蜡烛实体颜色 |
| `riseWickColor` | 上涨影线颜色 |
| `fallWickColor` | 下跌或平盘影线颜色 |
| `wickLineWidth` | 影线宽度 |

### `KLineVolumeStyle`

| 属性 | 说明 |
| --- | --- |
| `riseColor` | 上涨成交量柱颜色 |
| `fallColor` | 下跌或平盘成交量柱颜色 |

### `KLineCrosshairStyle`

| 属性 | 说明 |
| --- | --- |
| `color` | 十字线颜色 |
| `strokeWidth` | 十字线宽度 |

### `KLineInfoStyle`

| 属性 | 说明 |
| --- | --- |
| `backgroundColor` | 长按详情浮层背景色 |
| `textStyle` | 长按详情浮层文字样式 |

## 常见问题

### 为什么设置了数据但图表还在加载？

`KLineView` 从 `KLineController.shared.data` 读取数据。异步写入数据后，需要触发页面 rebuild：

```dart
KLineController.shared.data = dataList;
setState(() {});
```

### 为什么多个图表配置会互相影响？

未显式传入 controller 的多个 `KLineView()` 会使用 `KLineController.shared`。如果它们需要独立状态，请给每个图表传入单独的 controller：

```dart
KLineView(controller: KLineController()..data = dataList)
```

### 为什么最新 K 线右边有空白？

这是 `trailingBlankItemCount` 的效果，用来模拟交易所图表右侧留白。如果不需要，可以设为 `0`：

```dart
controller.trailingBlankItemCount = 0;
controller.maxTrailingBlankItemCount = 0;
```

### 如何关闭所有副图？

```dart
controller.showSubIndicators = [];
setState(() {});
```

### 如何只显示 MACD 副图？

```dart
controller.showSubIndicators = [IndicatorType.macd];
setState(() {});
```

### 如何设置 SAR 点颜色？

```dart
controller.sarColor = Colors.orange;
setState(() {});
```

### 如何自定义成交量单位？

设置 `volumeFormatter`：

```dart
controller.volumeFormatter = (value) {
  if (value >= 10000) {
    return '${(value / 10000).toStringAsFixed(2)}万';
  }
  return value.toStringAsFixed(2);
};
```

### 如何运行示例项目？

```bash
cd example
flutter run
```
