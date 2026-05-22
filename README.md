# kline chart

[![pub package](https://img.shields.io/pub/v/kline_chart?style=flat)](https://pub.dev/packages/kline_chart) [![license](https://img.shields.io/github/license/AscenX/kline_chart?style=flat)](https://github.com/AscenX/kline_chart)

KLine Chart is a lightweight Flutter charting library for building interactive financial candlestick charts. It supports common technical indicators such as MA, EMA, BOLL, VOL, MACD, KDJ, RSI, WR, and OBV, along with smooth scrolling, zooming, long-press crosshair interaction, and detailed price/indicator overlays. The project is designed for crypto, stock, and trading-related applications that need a customizable and responsive K-line chart component.

#### Demo
![](https://github.com/AscenX/kline_chart/blob/main/example/demo.gif?raw=true)

#### Usage

```dart
import 'package:flutter/material.dart';
import 'package:kline_chart/kline_chart.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool _showTimeChart = false;

  @override
  initState() {
    super.initState();

    // setup kline data
    _loadJson().then((value) {
      KLineController.shared.data = value;
      setState(() {});
    });
  }

  Future<List<KLineData>> _loadJson() async {
    final jsonStr = await rootBundle.loadString('lib/binance_btc_month.json');
    List jsonList = json.decode(jsonStr);
    List<KLineData> dataList = [];
    for (var data in jsonList) {
      var klineData = KLineData()
        ..open = double.parse(data[1] ?? '0')
        ..high = double.parse(data[2] ?? '0')
        ..low = double.parse(data[3] ?? '0')
        ..close = double.parse(data[4] ?? '0')
        ..volume = double.parse(data[5] ?? '0')
        ..time = data[6] ?? 0;

      dataList.add(klineData);
    }
    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.black))),
                child: KLineView()
            )
        )
    );
  }
}

```

#### Todo:
- ~~MA indicator~~
- ~~EMA indicator~~
- ~~Boll indicator~~
- ~~VOL sub indicator~~
- ~~KDJ sub indicator~~
- ~~WR sub indicator~~
- ~~OBV indicator~~
- ~~Y-axis ruler text~~
- ~~Long press info display~~
- ~~Improve accuracy~~
- ~~current price~~
- ~~Time Chart~~
- ~~Publish to pub.dev~~
- ~~Improve scale gesture~~
- ~~MACD sub indicator~~
- ~~RSI sub indicator~~
- SAR  indicator

- Highly customized
- Fit all screens
- Performance optimization
- Finish usage document
