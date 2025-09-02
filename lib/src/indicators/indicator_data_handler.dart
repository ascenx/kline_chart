import 'dart:math';

import 'package:flutter/cupertino.dart';
import '../indicators/indicator_result.dart';
import '../kline_controller.dart';
import '../kline_data.dart';

class IndicatorDataHandler {

  static IndicatorResult ma(
      List<KLineData> klineData, List<int> periods, double beginIdx,
      {bool isVol = false}) {
    if (klineData.isEmpty || periods.isEmpty) return IndicatorResult.empty;

    List<List<double>> maData = [];
    double max = 0.0;
    double min = 0.0;
    double itemCount = KLineController.shared.itemCount;

    for (int i = 0; i < periods.length; ++i) {
      List<double> maList = [];
      int period = periods[i];

      for (var j = beginIdx - 1; j < beginIdx + itemCount + 1; ++j) {
        if (j.ceil() < period - 1) {
          maList.add(-1);
          continue;
        }
        if (j.ceil() >= klineData.length) {
          debugPrint('debug:range error');
          continue;
        }

        // start from the index equals period
        double startIdx = j >= period - 1 ? j - period + 1 : 0;

        List<KLineData> sublist =
            klineData.sublist(startIdx.ceil(), (startIdx + period).ceil());
        if (sublist.isEmpty) {
          debugPrint('debug:sublist.isEmpty');
          continue;
        }
        double sum = 0.0;
        if (isVol) {
          sum = sublist.fold(0.0, (pre, e) => pre + e.volume);
        } else {
          sum = sublist.fold(0.0, (pre, e) => pre + e.close);
        }
        double maValue = sum / sublist.length;

        if (max == 0 || maValue > max) max = maValue;
        if (min == 0 || maValue < min) min = maValue;
        maList.add(maValue);
      }

      maData.add(maList);
    }
    return IndicatorResult(maData, max, min);
  }

  static IndicatorResult ema(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty) return IndicatorResult.empty;

    List<List<double>> emaData = [];
    double max = 0.0;
    double min = 0.0;
    double itemCount = KLineController.shared.itemCount;

    for (var i = 0; i < periods.length; ++i) {
      List<double> emaList = [];
      int period = periods[i];

      double lastEma = klineData.first.close;
      double sum = 0.0;

      for (int j = 0; j < klineData.length; ++j) {
        double close = klineData[j].close;

        if (j < period - 1) {
          emaList.add(-1);
          sum += close;
          continue;
        } else if (j == period - 1) {
          sum += close;
          lastEma = sum / period;
          emaList.add(lastEma);
          continue;
        }

        double deno = period * (period + 1) * 0.5;
        double emaValue =
            close * period / deno + (deno - period) * lastEma / deno;

        if (j >= beginIdx - 1 && j < beginIdx + itemCount) {
          if (max == 0 || emaValue > max) max = emaValue;
          if (min == 0 || emaValue < min) min = emaValue;
        }

        lastEma = emaValue;
        emaList.add(emaValue);
      }

      double start = beginIdx > 0 ? beginIdx : 0;
      List<double> subList =
          emaList.sublist(start.ceil(), (start + itemCount).ceil());
      emaData.add(subList);
    }
    return IndicatorResult(emaData, max, min);
  }

  static double _calculateStandardDeviation(List<double> values) {
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance =
        values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return sqrt(variance);
  }

  static IndicatorResult boll(
      List<KLineData> klineData, int period, int bandwidth, double beginIdx) {
    if (klineData.isEmpty || period < 0 || bandwidth < 0)
      return IndicatorResult.empty;

    List<double> upList = [];
    List<double> mbList = [];
    List<double> dnList = [];

    for (int i = 0; i < klineData.length; i++) {
      if (i < period - 1) {
        upList.add(-1);
        mbList.add(-1);
        dnList.add(-1);
        continue;
      }
      List<double> subList =
          klineData.sublist(i - period + 1, i + 1).map((e) => e.close).toList();
      double mb = subList.reduce((a, b) => a + b) / period;
      double std = _calculateStandardDeviation(subList);

      double up = mb + bandwidth * std;
      double dn = mb - bandwidth * std;

      upList.add(up);
      mbList.add(mb);
      dnList.add(dn);
    }

    double itemCount = KLineController.shared.itemCount;
    double start = beginIdx > 0 ? beginIdx : 0;
    upList = upList.sublist(start.ceil(), (start + itemCount).ceil());
    mbList = mbList.sublist(start.ceil(), (start + itemCount).ceil());
    dnList = dnList.sublist(start.ceil(), (start + itemCount).ceil());

    double maxValue = 0.0, minValue = dnList.first;
    for (int i = 0; i < upList.length; ++i) {
      maxValue = max(upList[i], maxValue);
      minValue = min(dnList[i], minValue);
    }

    return IndicatorResult([mbList, upList, dnList], maxValue, minValue);
  }

  static IndicatorResult macd(
      List<KLineData> klineData, List periods, double beginIdx) {
    return IndicatorResult.empty;
  }

  static double _emaCalculate(List<double> values, int period) {
    if (values.length < period) {
      return 0.0;
    }

    double sum = 0;
    for (int i = values.length - period; i < values.length; i++) {
      sum += values[i];
    }

    return sum / period;
  }

  static void calculateMACD(
      List<double> values, int shortPeriod, int longPeriod, int signalPeriod) {

    List<double> shortEMA = [];
    for (int i = longPeriod - shortPeriod; i < values.length; i++) {
      List<double> subset = values.sublist(i - shortPeriod + 1, i + 1);
      double ema = _emaCalculate(subset, shortPeriod);
      shortEMA.add(ema);
    }

    List<double> longEMA = [];
    for (int i = longPeriod - 1; i < values.length; i++) {
      List<double> subset = values.sublist(i - longPeriod + 1, i + 1);
      double ema = _emaCalculate(subset, longPeriod);
      longEMA.add(ema);
    }

    List<double> dif = [];
    for (int i = 0; i < longEMA.length; i++) {
      dif.add(shortEMA[i] - longEMA[i]);
    }

    List<double> dea = [];
    for (int i = signalPeriod - 1; i < dif.length; i++) {
      List<double> subset = dif.sublist(i - signalPeriod + 1, i + 1);
      double ema = _emaCalculate(subset, signalPeriod);
      dea.add(ema);
    }

    List<double> macd = [];
    for (int i = 0; i < dif.length; i++) {
      macd.add(2 * (dif[i] - dea[i]));
    }

  }

  static IndicatorResult kdj(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty || periods.length != 3) return IndicatorResult.empty;
    int period1 = periods[0];
    int period2 = periods[1];
    int period3 = periods[2];

    List<double> kValues = [];
    List<double> dValues = [];
    List<double> jValues = [];
    double maxValue = 0.0;
    double minValue = 0.0;

    double itemCount = KLineController.shared.itemCount;

    double lastK = 0.0, lastD = 0.0;
    for (int i = 0; i < klineData.length; i++) {
      KLineData data = klineData[i];
      if (i == 0) {
        double rsv = (data.close - data.low) / (data.high - data.low) * 100;
        lastK = lastD = rsv;
        continue;
      }

      int startIdx = i >= period1 ? i - period1 + 1 : 0;
      int length = i >= period1 ? period1 : i;

      List<KLineData> sublist = klineData.sublist(startIdx, startIdx + length);

      double hn = sublist.first.high;
      double ln = sublist.first.low;
      for (int j = 1; j < sublist.length; j++) {
        KLineData subData = sublist[j];
        hn = hn > subData.high ? hn : subData.high;
        ln = ln < subData.low ? ln : subData.low;
      }
      if (ln == hn) return IndicatorResult.empty;

      double rsv = (data.close - ln) / (hn - ln) * 100;
      double kValue = (lastK * (period2 - 1) + rsv) / period2;
      double dValue = (lastD * (period3 - 1) + kValue) / period3;
      double jValue = 3 * kValue - 2 * dValue;

      if (i >= beginIdx.ceil() && i < (beginIdx + itemCount).ceil()) {
        if (kValue > maxValue || maxValue == 0.0) maxValue = kValue;
        if (dValue > maxValue) maxValue = dValue;
        if (jValue > maxValue) maxValue = jValue;
        if (kValue < minValue || minValue == 0.0) minValue = kValue;
        if (dValue < minValue) minValue = dValue;
        if (jValue < minValue) minValue = jValue;

        kValues.add(kValue);
        dValues.add(dValue);
        jValues.add(jValue);
      }

      lastK = kValue;
      lastD = dValue;
    }

    return IndicatorResult([kValues, dValues, jValues], maxValue, minValue);
  }

  static IndicatorResult wr(List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty || periods.isEmpty) return IndicatorResult.empty;
    List<List<double>> dataList = [];
    double max = 0.0, min = 0.0;
    double itemCount = KLineController.shared.itemCount;
    for (var idx = 0; idx < periods.length; ++idx) {
      int period = periods[idx];
      List<double> wrList = [];

      for (var i = beginIdx; i < beginIdx + itemCount; ++i) {
        double end = i + 1;
        double start = i < period ? 0 : i - period;
        List<KLineData> sublist = klineData.sublist(start.ceil(), end.ceil());
        double highest = sublist.first.high;
        double lowest = sublist.first.low;
        for (var j = 1; j < sublist.length; ++j) {
          KLineData subData = sublist[j];
          if (subData.low < lowest) lowest = subData.low;
          if (subData.high > highest) highest = subData.high;
        }
        double wr =
            (highest - klineData[i.ceil()].close) / (highest - lowest) * 100;
        if (wr < min || min == 0.0) min = wr;
        if (wr > max || max == 0.0) max = wr;
        wrList.add(wr);
      }
      dataList.add(wrList);
    }
    return IndicatorResult(dataList, max, min);
  }

  static IndicatorResult obv(List<KLineData> klineData, double beginIdx) {
    List<double> obvValues = [];
    double obv = 0.0;
    double prevClose = 0.0;

    double itemCount = KLineController.shared.itemCount;
    double endIndex = beginIdx + itemCount;
    endIndex = endIndex < klineData.length ? endIndex : klineData.length.roundToDouble();

    double maxValue = 0.0;
    double minValue = 0.0;
    for (var i = 0; i < endIndex; i++) {
      KLineData data = klineData[i];

      if (i > beginIdx) {
        if (data.close > prevClose) {
          obv += data.volume;
        } else if (data.close < prevClose) {
          obv -= data.volume;
        }
        if (obv > maxValue || maxValue == 0.0) maxValue = obv;
        if (obv < minValue || minValue == 0.0) minValue = obv;
      }

      prevClose = data.close;

      if (i >= beginIdx.ceil() && i < (beginIdx + itemCount).ceil()) {
        obvValues.add(obv);
      }
    }

    return IndicatorResult([obvValues], maxValue, minValue);
  }
}
