import '../kline_controller.dart';
import '../kline_data.dart';
import 'indicator_data_handler.dart';
import 'indicator_result.dart';

class KLineIndicatorDataCache {
  final List<KLineData> klineData;
  final double beginIdx;
  final KLineController _controller;
  final _IndicatorDataConfig _config;
  final List<IndicatorResult?> _results =
      List<IndicatorResult?>.filled(IndicatorType.values.length, null);

  KLineIndicatorDataCache(
    this.klineData,
    this.beginIdx, {
    KLineController? controller,
  })  : _controller = controller ?? KLineController.shared,
        _config = _IndicatorDataConfig.fromController(
            controller ?? KLineController.shared);

  IndicatorResult result(IndicatorType type) {
    final cached = _results[type.index];
    if (cached != null) {
      return cached;
    }

    final result = _calculate(type);
    _results[type.index] = result;
    return result;
  }

  List<int> periodsFor(IndicatorType type) {
    return _config.periodsFor(type);
  }

  IndicatorResult _calculate(IndicatorType type) {
    switch (type) {
      case IndicatorType.ma:
        return IndicatorDataHandler.ma(klineData, const [7, 30], beginIdx,
            controller: _controller);
      case IndicatorType.ema:
        return IndicatorDataHandler.ema(klineData, const [7, 25], beginIdx,
            controller: _controller);
      case IndicatorType.boll:
        return IndicatorDataHandler.boll(
            klineData, _config.bollPeriod, _config.bollBandwidth, beginIdx,
            controller: _controller);
      case IndicatorType.sar:
        return IndicatorDataHandler.sar(klineData, beginIdx,
            controller: _controller);
      case IndicatorType.maVol:
        return IndicatorDataHandler.ma(
            klineData, _config.volMaPeriods, beginIdx,
            isVol: true, controller: _controller);
      case IndicatorType.macd:
        return IndicatorDataHandler.macd(
            klineData, _config.macdPeriods, beginIdx,
            controller: _controller);
      case IndicatorType.kdj:
        return IndicatorDataHandler.kdj(klineData, _config.kdjPeriods, beginIdx,
            controller: _controller);
      case IndicatorType.rsi:
        return IndicatorDataHandler.rsi(klineData, _config.rsiPeriods, beginIdx,
            controller: _controller);
      case IndicatorType.wr:
        return IndicatorDataHandler.wr(klineData, _config.wrPeriods, beginIdx,
            controller: _controller);
      case IndicatorType.obv:
        return IndicatorDataHandler.obv(klineData, beginIdx,
            controller: _controller);
      case IndicatorType.vol:
        return IndicatorResult.empty;
    }
  }
}

class _IndicatorDataConfig {
  final List<int> volMaPeriods;
  final List<int> macdPeriods;
  final List<int> kdjPeriods;
  final List<int> rsiPeriods;
  final List<int> wrPeriods;
  final List<int> bollPeriods;
  final int bollPeriod;
  final int bollBandwidth;

  const _IndicatorDataConfig({
    required this.volMaPeriods,
    required this.macdPeriods,
    required this.kdjPeriods,
    required this.rsiPeriods,
    required this.wrPeriods,
    required this.bollPeriods,
    required this.bollPeriod,
    required this.bollBandwidth,
  });

  factory _IndicatorDataConfig.fromController(KLineController controller) {
    final bollPeriod = controller.bollPeriod;
    return _IndicatorDataConfig(
      volMaPeriods: List<int>.of(controller.volMaPeriods),
      macdPeriods: List<int>.of(controller.macdPeriods),
      kdjPeriods: List<int>.of(controller.kdjPeriods),
      rsiPeriods: List<int>.of(controller.rsiPeriods),
      wrPeriods: List<int>.of(controller.wrPeriods),
      bollPeriods: [bollPeriod, bollPeriod, bollPeriod],
      bollPeriod: bollPeriod,
      bollBandwidth: controller.bollBandwidth,
    );
  }

  List<int> periodsFor(IndicatorType type) {
    if (type == IndicatorType.ma) {
      return const [7, 30];
    } else if (type == IndicatorType.ema) {
      return const [7, 25];
    } else if (type == IndicatorType.boll) {
      return bollPeriods;
    } else if (type == IndicatorType.sar || type == IndicatorType.obv) {
      return const [0];
    } else if (type == IndicatorType.maVol) {
      return volMaPeriods;
    } else if (type == IndicatorType.macd) {
      return macdPeriods;
    } else if (type == IndicatorType.kdj) {
      return kdjPeriods;
    } else if (type == IndicatorType.rsi) {
      return rsiPeriods;
    } else if (type == IndicatorType.wr) {
      return wrPeriods;
    }
    return const [];
  }
}
