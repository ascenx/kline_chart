import 'dart:convert';

// Flutter 3.0's services library does not re-export Color.
// ignore: unnecessary_import
import 'package:flutter/material.dart' show Color;
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

List<KLineOverlay> buildDemoOverlays(List<KLineData> dataList) {
  if (dataList.length < 8) {
    return const [];
  }

  final visibleWindow = dataList.length > 30
      ? dataList.sublist(dataList.length - 30)
      : List<KLineData>.of(dataList);
  var highest = visibleWindow.first.high;
  var lowest = visibleWindow.first.low;
  for (final item in visibleWindow) {
    if (item.high > highest) highest = item.high;
    if (item.low < lowest) lowest = item.low;
  }

  final range = (highest - lowest).abs();
  final zoneHeight = range == 0 ? lowest * 0.01 : range * 0.08;
  final supportFrom = lowest;
  final supportTo = lowest + zoneHeight;
  final entryIndex = _safeIndex(dataList, dataList.length - 18);
  final buyIndex = _safeIndex(dataList, dataList.length - 24);
  final sellIndex = _safeIndex(dataList, dataList.length - 8);
  final eventIndex = _safeIndex(dataList, dataList.length - 13);

  return [
    KLinePriceLine(
      price: dataList[entryIndex].close,
      label: 'Entry',
      color: const Color(0xff2563eb),
    ),
    KLinePriceZone(
      fromPrice: supportFrom,
      toPrice: supportTo,
      label: 'Support',
      color: const Color(0xff16a34a),
      opacity: 0.14,
    ),
    KLineMarker(
      time: dataList[buyIndex].time,
      price: dataList[buyIndex].low,
      type: KLineMarkerType.buy,
      color: const Color(0xff16a34a),
    ),
    KLineMarker(
      time: dataList[sellIndex].time,
      price: dataList[sellIndex].high,
      type: KLineMarkerType.sell,
      color: const Color(0xffdc2626),
    ),
    KLineVerticalLine(
      time: dataList[eventIndex].time,
      label: 'Event',
      color: const Color(0xfff59e0b),
    ),
  ];
}

int _safeIndex(List<KLineData> dataList, int index) {
  if (index < 0) return 0;
  if (index >= dataList.length) return dataList.length - 1;
  return index;
}
