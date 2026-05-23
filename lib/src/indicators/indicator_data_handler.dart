import 'dart:math';

import '../indicators/indicator_result.dart';
import '../kline_controller.dart';
import '../kline_data.dart';

class IndicatorDataHandler {
  static int _visibleStart(double beginIdx) => max(0, beginIdx.ceil());

  static int _visibleEnd(List<KLineData> klineData, double beginIdx) {
    double itemCount = KLineController.shared.itemCount;
    return min(klineData.length, (beginIdx + itemCount).ceil());
  }

  static IndicatorResult ma(
      List<KLineData> klineData, List<int> periods, double beginIdx,
      {bool isVol = false}) {
    if (klineData.isEmpty || periods.isEmpty) {
      return IndicatorResult.empty;
    }

    List<List<double>> maData = [];
    double max = 0.0;
    double min = 0.0;
    double itemCount = KLineController.shared.itemCount;

    for (int i = 0; i < periods.length; ++i) {
      List<double> maList = [];
      int period = periods[i];

      for (var j = beginIdx - 1; j < beginIdx + itemCount + 1; ++j) {
        final dataIndex = j.ceil();
        if (dataIndex < period - 1) {
          maList.add(-1);
          continue;
        }
        if (dataIndex >= klineData.length) break;

        // start from the index equals period
        double startIdx = j >= period - 1 ? j - period + 1 : 0;

        final start = startIdx.ceil();
        final end = (startIdx + period).ceil();
        if (start == end) continue;

        double sum = 0.0;
        for (int k = start; k < end; ++k) {
          sum += isVol ? klineData[k].volume : klineData[k].close;
        }
        double maValue = sum / (end - start);

        if (max == 0 || maValue > max) {
          max = maValue;
        }
        if (min == 0 || maValue < min) {
          min = maValue;
        }
        maList.add(maValue);
      }

      maData.add(maList);
    }
    return IndicatorResult(maData, max, min);
  }

  static IndicatorResult ema(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty) {
      return IndicatorResult.empty;
    }

    List<List<double>> emaData = [];
    double max = 0.0;
    double min = 0.0;
    double itemCount = KLineController.shared.itemCount;
    int visibleStart = _visibleStart(beginIdx);
    int visibleEnd = _visibleEnd(klineData, beginIdx);

    for (var i = 0; i < periods.length; ++i) {
      List<double> emaList = [];
      int period = periods[i];

      double lastEma = klineData.first.close;
      double sum = 0.0;

      for (int j = 0; j < visibleEnd; ++j) {
        double close = klineData[j].close;

        if (j < period - 1) {
          if (j >= visibleStart && j < visibleEnd) {
            emaList.add(-1);
          }
          sum += close;
          continue;
        } else if (j == period - 1) {
          sum += close;
          lastEma = sum / period;
          if (j >= visibleStart && j < visibleEnd) {
            emaList.add(lastEma);
          }
          continue;
        }

        double deno = period * (period + 1) * 0.5;
        double emaValue =
            close * period / deno + (deno - period) * lastEma / deno;

        if (j >= beginIdx - 1 && j < beginIdx + itemCount) {
          if (max == 0 || emaValue > max) {
            max = emaValue;
          }
          if (min == 0 || emaValue < min) {
            min = emaValue;
          }
        }

        lastEma = emaValue;
        if (j >= visibleStart && j < visibleEnd) {
          emaList.add(emaValue);
        }
      }

      emaData.add(emaList);
    }
    return IndicatorResult(emaData, max, min);
  }

  static IndicatorResult boll(
      List<KLineData> klineData, int period, int bandwidth, double beginIdx) {
    if (klineData.isEmpty || period < 0 || bandwidth < 0) {
      return IndicatorResult.empty;
    }
    if (period == 0) {
      throw StateError('No element');
    }

    List<double> upList = [];
    List<double> mbList = [];
    List<double> dnList = [];

    final visibleStart = _visibleStart(beginIdx);
    final visibleEnd = _visibleEnd(klineData, beginIdx);

    for (int i = visibleStart; i < visibleEnd; i++) {
      if (i < period - 1) {
        upList.add(-1);
        mbList.add(-1);
        dnList.add(-1);
        continue;
      }
      final start = i - period + 1;
      double sum = 0.0;
      for (int j = start; j <= i; ++j) {
        sum += klineData[j].close;
      }
      double mb = sum / period;

      double variance = 0.0;
      for (int j = start; j <= i; ++j) {
        final diff = klineData[j].close - mb;
        variance += diff * diff;
      }
      double std = sqrt(variance / period);

      double up = mb + bandwidth * std;
      double dn = mb - bandwidth * std;

      upList.add(up);
      mbList.add(mb);
      dnList.add(dn);
    }

    if (dnList.isEmpty) {
      return IndicatorResult.empty;
    }

    double maxValue = 0.0, minValue = dnList.first;
    for (int i = 0; i < upList.length; ++i) {
      maxValue = max(upList[i], maxValue);
      minValue = min(dnList[i], minValue);
    }

    return IndicatorResult([mbList, upList, dnList], maxValue, minValue);
  }

  static IndicatorResult sar(List<KLineData> klineData, double beginIdx) {
    if (klineData.length < 2) {
      return IndicatorResult.empty;
    }

    final controller = KLineController.shared;
    final startAf = controller.sarStart;
    final incrementAf = controller.sarIncrement;
    final maxAf = controller.sarMax;
    if (startAf <= 0 || incrementAf <= 0 || maxAf <= 0) {
      return IndicatorResult.empty;
    }

    final visibleStart = _visibleStart(beginIdx);
    final visibleEnd = _visibleEnd(klineData, beginIdx);
    final visibleValues = <double>[];
    bool isRising = klineData[1].close >= klineData[0].close;
    double sar = isRising
        ? min(klineData[0].low, klineData[1].low)
        : max(klineData[0].high, klineData[1].high);
    double extremePoint = isRising
        ? max(klineData[0].high, klineData[1].high)
        : min(klineData[0].low, klineData[1].low);
    double accelerationFactor = startAf;
    if (visibleStart == 0 && visibleStart < visibleEnd) {
      visibleValues.add(-1.0);
    }
    if (visibleStart <= 1 && 1 < visibleEnd) {
      visibleValues.add(sar);
    }

    for (int i = 2; i < visibleEnd; ++i) {
      sar = sar + accelerationFactor * (extremePoint - sar);

      if (isRising) {
        sar = min(sar, min(klineData[i - 1].low, klineData[i - 2].low));
        if (klineData[i].low < sar) {
          isRising = false;
          sar = extremePoint;
          extremePoint = klineData[i].low;
          accelerationFactor = startAf;
        } else if (klineData[i].high > extremePoint) {
          extremePoint = klineData[i].high;
          accelerationFactor = min(accelerationFactor + incrementAf, maxAf);
        }
      } else {
        sar = max(sar, max(klineData[i - 1].high, klineData[i - 2].high));
        if (klineData[i].high > sar) {
          isRising = true;
          sar = extremePoint;
          extremePoint = klineData[i].high;
          accelerationFactor = startAf;
        } else if (klineData[i].low < extremePoint) {
          extremePoint = klineData[i].low;
          accelerationFactor = min(accelerationFactor + incrementAf, maxAf);
        }
      }

      if (i >= visibleStart && i < visibleEnd) {
        visibleValues.add(sar);
      }
    }

    if (visibleValues.isEmpty) {
      return IndicatorResult.empty;
    }

    double maxValue = 0.0;
    double minValue = 0.0;
    bool hasVisibleValue = false;
    for (final value in visibleValues) {
      if (value < 0) {
        continue;
      }
      if (!hasVisibleValue) {
        maxValue = value;
        minValue = value;
        hasVisibleValue = true;
      } else {
        maxValue = max(maxValue, value);
        minValue = min(minValue, value);
      }
    }

    return IndicatorResult(
      [visibleValues],
      hasVisibleValue ? maxValue : 0.0,
      hasVisibleValue ? minValue : 0.0,
    );
  }

  static IndicatorResult macd(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty ||
        periods.length != 3 ||
        periods.any((period) => period <= 0)) {
      return IndicatorResult.empty;
    }

    int fastPeriod = periods[0];
    int slowPeriod = periods[1];
    int signalPeriod = periods[2];
    double fastAlpha = 2.0 / (fastPeriod + 1);
    double slowAlpha = 2.0 / (slowPeriod + 1);
    double signalAlpha = 2.0 / (signalPeriod + 1);

    List<double> visibleMacd = [];
    List<double> visibleSignal = [];
    List<double> visibleHistogram = [];
    int visibleStart = _visibleStart(beginIdx);
    int visibleEnd = _visibleEnd(klineData, beginIdx);

    double? fastEma;
    double? slowEma;
    double? signalEma;

    for (int i = 0; i < visibleEnd; ++i) {
      double close = klineData[i].close;
      if (i < fastPeriod - 1) {
        fastEma = null;
      } else if (i == fastPeriod - 1) {
        fastEma = _closeAverage(klineData, i - fastPeriod + 1, i + 1);
      } else {
        fastEma = close * fastAlpha + fastEma! * (1 - fastAlpha);
      }

      if (i < slowPeriod - 1) {
        if (i >= visibleStart && i < visibleEnd) {
          visibleMacd.add(-1);
          visibleSignal.add(-1);
          visibleHistogram.add(-1);
        }
        continue;
      } else if (i == slowPeriod - 1) {
        slowEma = _closeAverage(klineData, i - slowPeriod + 1, i + 1);
      } else {
        slowEma = close * slowAlpha + slowEma! * (1 - slowAlpha);
      }

      double macd = fastEma! - slowEma;
      signalEma = signalEma == null
          ? macd
          : macd * signalAlpha + signalEma * (1 - signalAlpha);
      double hist = macd - signalEma;

      if (i >= visibleStart && i < visibleEnd) {
        visibleMacd.add(macd);
        visibleSignal.add(signalEma);
        visibleHistogram.add(hist);
      }
    }

    double maxValue = 0.0;
    double minValue = 0.0;
    for (List<double> values in [
      visibleMacd,
      visibleSignal,
      visibleHistogram
    ]) {
      for (double value in values) {
        if (value < 0 && value == -1) continue;
        if (value > maxValue) {
          maxValue = value;
        }
        if (value < minValue) {
          minValue = value;
        }
      }
    }

    return IndicatorResult(
        [visibleMacd, visibleSignal, visibleHistogram], maxValue, minValue);
  }

  static double _closeAverage(List<KLineData> klineData, int start, int end) {
    double sum = 0.0;
    for (int i = start; i < end; ++i) {
      sum += klineData[i].close;
    }
    return sum / (end - start);
  }

  static IndicatorResult kdj(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty || periods.length != 3) {
      return IndicatorResult.empty;
    }
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
    final visibleEnd = _visibleEnd(klineData, beginIdx);
    for (int i = 0; i < visibleEnd; i++) {
      KLineData data = klineData[i];
      if (i == 0) {
        double rsv = (data.close - data.low) / (data.high - data.low) * 100;
        lastK = lastD = rsv;
        continue;
      }

      int startIdx = i >= period1 ? i - period1 + 1 : 0;
      int length = i >= period1 ? period1 : i;

      int endIdx = startIdx + length;
      if (startIdx == endIdx) {
        throw StateError('No element');
      }
      double hn = klineData[startIdx].high;
      double ln = klineData[startIdx].low;
      for (int j = startIdx + 1; j < endIdx; j++) {
        KLineData subData = klineData[j];
        hn = hn > subData.high ? hn : subData.high;
        ln = ln < subData.low ? ln : subData.low;
      }
      if (ln == hn) {
        return IndicatorResult.empty;
      }

      double rsv = (data.close - ln) / (hn - ln) * 100;
      double kValue = (lastK * (period2 - 1) + rsv) / period2;
      double dValue = (lastD * (period3 - 1) + kValue) / period3;
      double jValue = 3 * kValue - 2 * dValue;

      if (i >= beginIdx.ceil() && i < (beginIdx + itemCount).ceil()) {
        if (kValue > maxValue || maxValue == 0.0) {
          maxValue = kValue;
        }
        if (dValue > maxValue) {
          maxValue = dValue;
        }
        if (jValue > maxValue) {
          maxValue = jValue;
        }
        if (kValue < minValue || minValue == 0.0) {
          minValue = kValue;
        }
        if (dValue < minValue) {
          minValue = dValue;
        }
        if (jValue < minValue) {
          minValue = jValue;
        }

        kValues.add(kValue);
        dValues.add(dValue);
        jValues.add(jValue);
      }

      lastK = kValue;
      lastD = dValue;
    }

    return IndicatorResult([kValues, dValues, jValues], maxValue, minValue);
  }

  static IndicatorResult rsi(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty || periods.isEmpty) {
      return IndicatorResult.empty;
    }

    List<List<double>> dataList = [];
    double max = 0.0;
    double min = 0.0;
    bool hasVisibleValue = false;
    bool hasValidPeriod = false;
    int visibleStart = _visibleStart(beginIdx);
    int visibleEnd = _visibleEnd(klineData, beginIdx);

    for (var idx = 0; idx < periods.length; ++idx) {
      int period = periods[idx];
      if (period <= 0) {
        dataList.add([]);
        continue;
      }
      hasValidPeriod = true;

      List<double> subList = [];
      double avgGain = 0.0;
      double avgLoss = 0.0;

      for (int i = 0; i < visibleEnd; ++i) {
        if (i < period) {
          if (i > 0) {
            double diff = klineData[i].close - klineData[i - 1].close;
            if (diff > 0) {
              avgGain += diff;
            } else {
              avgLoss -= diff;
            }
          }
          if (i >= visibleStart && i < visibleEnd) {
            subList.add(-1);
          }
          continue;
        }

        double diff = klineData[i].close - klineData[i - 1].close;
        double gain = 0.0;
        double loss = 0.0;
        if (diff > 0) {
          gain = diff;
        } else {
          loss = -diff;
        }

        if (i == period) {
          if (diff > 0) {
            avgGain += diff;
          } else {
            avgLoss -= diff;
          }
          avgGain /= period;
          avgLoss /= period;
        } else {
          avgGain = (avgGain * (period - 1) + gain) / period;
          avgLoss = (avgLoss * (period - 1) + loss) / period;
        }

        double rsi = _rsiFromAverageGainLoss(avgGain, avgLoss);
        if (i >= visibleStart && i < visibleEnd) {
          subList.add(rsi);
        }
      }

      for (double rsi in subList) {
        if (rsi < 0) continue;
        if (!hasVisibleValue) {
          max = rsi;
          min = rsi;
          hasVisibleValue = true;
        } else {
          if (rsi > max) {
            max = rsi;
          }
          if (rsi < min) {
            min = rsi;
          }
        }
      }
      dataList.add(subList);
    }

    if (!hasVisibleValue) {
      return IndicatorResult(dataList, hasValidPeriod ? 100.0 : 0.0, 0.0);
    }
    return IndicatorResult(dataList, max.ceilToDouble(), min.floorToDouble());
  }

  static double _rsiFromAverageGainLoss(double avgGain, double avgLoss) {
    if (avgGain == 0.0 && avgLoss == 0.0) {
      return 50.0;
    }
    if (avgLoss == 0.0) {
      return 100.0;
    }
    if (avgGain == 0.0) {
      return 0.0;
    }
    return avgGain / (avgGain + avgLoss) * 100;
  }

  static IndicatorResult wr(
      List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty || periods.isEmpty) {
      return IndicatorResult.empty;
    }
    List<List<double>> dataList = [];
    double max = 0.0, min = 0.0;
    for (var idx = 0; idx < periods.length; ++idx) {
      int period = periods[idx];
      List<double> wrList = [];

      int endIndex = _visibleEnd(klineData, beginIdx);
      for (var i = beginIdx; i < endIndex; ++i) {
        final dataIndex = i.ceil();
        if (dataIndex >= klineData.length) break;
        double end = i + 1;
        double start = i < period ? 0 : i - period;
        final startIndex = start.ceil();
        final endIndex = end.ceil();
        if (startIndex == endIndex) {
          throw StateError('No element');
        }
        double highest = klineData[startIndex].high;
        double lowest = klineData[startIndex].low;
        for (var j = startIndex + 1; j < endIndex; ++j) {
          KLineData subData = klineData[j];
          if (subData.low < lowest) {
            lowest = subData.low;
          }
          if (subData.high > highest) {
            highest = subData.high;
          }
        }
        double wr = highest == lowest
            ? 0.0
            : (highest - klineData[dataIndex < 0 ? 0 : dataIndex].close) /
                (highest - lowest) *
                100;
        if (wr < min || min == 0.0) {
          min = wr;
        }
        if (wr > max || max == 0.0) {
          max = wr;
        }
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
    endIndex = endIndex < klineData.length
        ? endIndex
        : klineData.length.roundToDouble();

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
        if (obv > maxValue || maxValue == 0.0) {
          maxValue = obv;
        }
        if (obv < minValue || minValue == 0.0) {
          minValue = obv;
        }
      }

      prevClose = data.close;

      if (i >= beginIdx.ceil() && i < (beginIdx + itemCount).ceil()) {
        obvValues.add(obv);
      }
    }

    return IndicatorResult([obvValues], maxValue, minValue);
  }
}
