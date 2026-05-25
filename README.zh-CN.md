# KLine Chart

[English](README.md) | 简体中文 | [Usage Wiki](docs/wiki.md) | [使用 Wiki](docs/wiki.zh-CN.md) | [Style API](docs/style-api.md)

[![pub package](https://img.shields.io/pub/v/kline_chart?style=flat)](https://pub.dev/packages/kline_chart)
[![license](https://img.shields.io/github/license/AscenX/kline_chart?style=flat)](https://github.com/AscenX/kline_chart)

KLine Chart 是一个轻量级 Flutter K 线图组件，用于构建交易、行情、加密货币、股票等场景中的交互式蜡烛图。它支持 MA、EMA、BOLL、SAR、VOL、MACD、KDJ、RSI、WR、OBV 等常用技术指标，并提供平滑滚动、双指缩放、长按十字线、价格和指标信息展示等能力。

该组件不依赖第三方图表库，适合需要高度自定义和响应式绘制的 Flutter 应用。

## 演示

![KLine Chart demo](https://github.com/AscenX/kline_chart/blob/main/example/demo.gif?raw=true)

## 功能特性

- 支持蜡烛图和分时图模式。
- 支持横向平滑滚动和双指缩放。
- 支持长按十字线和 K 线详情浮层。
- 主图指标：MA、EMA、BOLL、SAR。
- 副图指标：VOL、MACD、KDJ、RSI、WR、OBV。
- 支持自定义指标周期、颜色、间距、可见 K 线数量。
- 支持最新 K 线右侧预留空白，并限制最右侧最少保留真实 K 线数量。
- 支持价格、成交量、指标值的格式化自定义。
- 支持初始数据、实时更新最后一根 K 线、追加新周期、前置历史数据和自动刷新。
- 支持滚动到左侧边缘附近时通过 `onLoadMore` 加载更多历史 K 线。
- 对短数据、平盘数据、零成交量数据做了稳定性处理。

## 安装

在 Flutter 项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  kline_chart: ^1.0.0
```

然后导入：

```dart
import 'package:kline_chart/kline_chart.dart';
```

## 快速开始

通过 `KLineController.shared.setData` 设置 K 线数据，然后渲染 `KLineView`。

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

## 独立控制器

`KLineView()` 默认使用 `KLineController.shared`，保持旧用法兼容。如果同一个页面需要渲染多个互不影响的图表，可以创建独立 controller 并传给 `KLineView`。

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

只需要一个全局图表时可以继续用 `KLineController.shared`。需要不同数据、指标、样式、格式化、滚动状态和长按状态互相隔离时，使用 `KLineController()`。

## 数据更新和加载历史

`KLineView` 会监听 controller，下面这些数据 API 会自动刷新图表，不需要外层再手动 `setState`。

```dart
final controller = KLineController.shared;

controller.setData(initialData);
controller.updateLast(realtimeCandle);
controller.append(nextPeriodCandle);
controller.prependHistory(olderCandles);
controller.clearData();
```

当用户滚动到左侧边缘附近时，可以通过 `onLoadMore` 加载更早的历史 K 线。加载完成后调用 `prependHistory`，图表会保持当前可见 K 线不跳动。

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

## 数据模型

每一根 K 线由 `KLineData` 表示：

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

`time` 需要传入毫秒级 Unix 时间戳。

## 指标配置

`KLineController.shared` 是默认共享配置入口。如果使用独立图表，请配置传给 `KLineView` 的 controller 实例。

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

可用指标：

| 区域 | 指标 |
| --- | --- |
| 主图 | `ma`, `ema`, `boll`, `sar` |
| 副图 | `vol`, `macd`, `kdj`, `rsi`, `wr`, `obv` |

## 图表配置

```dart
final controller = KLineController.shared;

controller.itemCount = 30;
controller.minCount = 7;
controller.maxCount = 39;
controller.spacing = 2.0;
controller.showTimeChart = false;

controller.klineMargin = const EdgeInsets.all(0);
controller.subIndicatorHeight = 50.0;
controller.indicatorSpacing = 10.0;
controller.indicatorColors = [
  Colors.orange,
  Colors.purple,
  Colors.blue,
];
```

## 右侧预留空白

如果希望最新 K 线右侧保留一定空间，或者继续向左滑动直到屏幕只剩少量最新数据，可以配置右侧空白数量：

```dart
final controller = KLineController.shared;

controller.trailingBlankItemCount = 5;
controller.maxTrailingBlankItemCount = 20;
controller.minTrailingVisibleItemCount = 4;
```

- `trailingBlankItemCount`：初始显示时最新 K 线右侧预留的空白周期数。
- `maxTrailingBlankItemCount`：最多可以向右侧滑出的空白周期数。
- `minTrailingVisibleItemCount`：滑到最右侧时至少保留的真实 K 线数量。

当数据量较少时，组件会自动限制空白区域，避免把真实 K 线全部滑出屏幕。

## 数字格式化

可以分别自定义价格、成交量、指标值的展示格式：

```dart
final controller = KLineController.shared;

controller.priceFormatter = (value) {
  return value.toStringAsFixed(4);
};

controller.volumeFormatter = (value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2)}B';
  }
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

默认情况下，成交量会在达到阈值时显示 `K`、`M`、`B` 单位。

## 样式配置

样式相关配置集中在 `KLineChartStyle`、`KLineCandleStyle`、`KLineVolumeStyle`、`KLineCrosshairStyle`、`KLineInfoStyle` 中。

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

完整样式 API 请参考 [Style API](docs/style-api.md)。

## 示例项目

仓库内包含可运行示例：

```bash
cd example
flutter run
```

## Roadmap

- 持续优化不同屏幕尺寸下的响应式表现。
- 持续优化绘制性能。
