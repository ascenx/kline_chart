import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kline_chart/kline_chart.dart';

Future<List<KLineData>> loadDemoKLineData() async {
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
