import 'dart:math';

/// Time label granularity selected from the currently visible time span.
enum KLineTimeLabelGranularity {
  /// Intraday labels, formatted as `HH:mm` by default.
  time,

  /// Day labels, formatted as `MM-dd` by default.
  day,

  /// Month labels, formatted as `yyyy-MM` by default.
  month,

  /// Year labels, formatted as `yyyy` by default.
  year,
}

/// Formats a time axis label for display.
typedef KLineTimeFormatter = String Function(
  DateTime time,
  KLineTimeLabelGranularity granularity,
);

/// A generated price axis tick.
class KLinePriceTick {
  /// Price value represented by this tick.
  final double value;

  /// Vertical pixel position of this tick.
  final double y;

  /// Creates a price axis tick.
  const KLinePriceTick({
    required this.value,
    required this.y,
  });
}

/// A generated time axis tick.
class KLineTimeTick {
  /// Data index represented by this tick.
  final int dataIndex;

  /// Candle timestamp in milliseconds.
  final int time;

  /// Horizontal pixel position of this tick.
  final double x;

  /// Label granularity selected for the current visible span.
  final KLineTimeLabelGranularity granularity;

  /// Creates a time axis tick.
  const KLineTimeTick({
    required this.dataIndex,
    required this.time,
    required this.x,
    required this.granularity,
  });
}

/// Pure helpers for adaptive chart axes.
class KLineAxis {
  static const int _dayMs = 24 * 60 * 60 * 1000;
  static const double _ln10 = 2.302585092994046;

  /// Generates readable price ticks inside the visible price range.
  static List<KLinePriceTick> priceTicks({
    required double minValue,
    required double maxValue,
    required double top,
    required double height,
    int maxTickCount = 5,
    double minTickSpacing = 28,
  }) {
    if (!minValue.isFinite ||
        !maxValue.isFinite ||
        !top.isFinite ||
        !height.isFinite ||
        height <= 0) {
      return const [];
    }

    if (minValue == maxValue) {
      return [
        KLinePriceTick(value: minValue, y: top + height * 0.5),
      ];
    }

    final low = min(minValue, maxValue);
    final high = max(minValue, maxValue);
    final range = high - low;
    final safeMaxTickCount = max(1, maxTickCount);
    final safeMinTickSpacing = minTickSpacing > 0 ? minTickSpacing : 1.0;
    final heightLimitedCount =
        max(2, (height / safeMinTickSpacing).floor() + 1);
    final targetTickCount = min(safeMaxTickCount, heightLimitedCount);
    final rawStep = range / max(1, targetTickCount - 1);
    var step = _niceStep(rawStep, roundDown: true);
    while (_tickCountInRange(low, high, step) > targetTickCount) {
      step = _nextNiceStep(step);
    }
    if (step <= 0 || !step.isFinite) {
      return const [];
    }

    final firstTick = (low / step).ceil() * step;
    final lastTick = (high / step).floor() * step;
    if (firstTick > lastTick) {
      return [
        KLinePriceTick(value: (low + high) * 0.5, y: top + height * 0.5),
      ];
    }

    final ticks = <KLinePriceTick>[];
    final maxIterations = targetTickCount + 2;
    var value = firstTick;
    var count = 0;
    while (value <= lastTick + step * 0.5 && count < maxIterations) {
      final normalizedValue = _roundToStepPrecision(value, step);
      final y = top + height * (1 - (normalizedValue - low) / range);
      if (y >= top - 0.000001 && y <= top + height + 0.000001) {
        ticks.add(KLinePriceTick(value: normalizedValue, y: y));
      }
      value += step;
      count += 1;
    }
    return ticks;
  }

  /// Selects label granularity from the visible time span.
  static KLineTimeLabelGranularity timeGranularityForSpan(
    int firstTime,
    int lastTime,
  ) {
    final span = (lastTime - firstTime).abs();
    if (span < 2 * _dayMs) {
      return KLineTimeLabelGranularity.time;
    }
    if (span < 180 * _dayMs) {
      return KLineTimeLabelGranularity.day;
    }
    if (span < 730 * _dayMs) {
      return KLineTimeLabelGranularity.month;
    }
    return KLineTimeLabelGranularity.year;
  }

  /// Generates sparse time ticks aligned to visible candle centers.
  static List<KLineTimeTick> timeTicks({
    required List<int> times,
    required double beginIndex,
    required double itemWidth,
    required double spacing,
    required double itemCount,
    required double viewportWidth,
    double minLabelSpacing = 64,
  }) {
    return timeTicksForIndexedData(
      dataLength: times.length,
      timeAt: (index) => times[index],
      beginIndex: beginIndex,
      itemWidth: itemWidth,
      spacing: spacing,
      itemCount: itemCount,
      viewportWidth: viewportWidth,
      minLabelSpacing: minLabelSpacing,
    );
  }

  /// Generates sparse time ticks from indexed data without copying timestamps.
  static List<KLineTimeTick> timeTicksForIndexedData({
    required int dataLength,
    required int Function(int index) timeAt,
    required double beginIndex,
    required double itemWidth,
    required double spacing,
    required double itemCount,
    required double viewportWidth,
    double minLabelSpacing = 64,
  }) {
    if (dataLength <= 0 ||
        !beginIndex.isFinite ||
        !itemWidth.isFinite ||
        !spacing.isFinite ||
        !itemCount.isFinite ||
        !viewportWidth.isFinite ||
        itemCount <= 0 ||
        viewportWidth <= 0) {
      return const [];
    }

    final visibleStart = beginIndex.ceil().clamp(0, dataLength).toInt();
    final visibleEnd =
        (beginIndex + itemCount).ceil().clamp(0, dataLength).toInt();
    if (visibleStart >= visibleEnd) {
      return const [];
    }

    final granularity =
        timeGranularityForSpan(timeAt(visibleStart), timeAt(visibleEnd - 1));
    final safeMinLabelSpacing = minLabelSpacing > 0 ? minLabelSpacing : 1.0;
    final maxLabelCount =
        max(1, (viewportWidth / safeMinLabelSpacing).floor() + 1);
    final visibleCount = visibleEnd - visibleStart;
    final step = max(1, (visibleCount / maxLabelCount).ceil());
    final firstIndex = ((visibleStart + step - 1) ~/ step) * step;
    final itemExtent = itemWidth + spacing;
    if (itemExtent <= 0) {
      return const [];
    }

    final ticks = <KLineTimeTick>[];
    for (var index = firstIndex; index < visibleEnd; index += step) {
      final x = (index - beginIndex) * itemExtent + itemWidth * 0.5;
      if (x < 0 || x > viewportWidth) {
        continue;
      }
      ticks.add(KLineTimeTick(
        dataIndex: index,
        time: timeAt(index),
        x: _roundToStepPrecision(x, 0.000001),
        granularity: granularity,
      ));
    }
    return ticks;
  }

  /// Formats a time label using the built-in granularity-aware pattern.
  static String defaultTimeLabel(
    DateTime time,
    KLineTimeLabelGranularity granularity,
  ) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    switch (granularity) {
      case KLineTimeLabelGranularity.time:
        return '$hour:$minute';
      case KLineTimeLabelGranularity.day:
        return '$month-$day';
      case KLineTimeLabelGranularity.month:
        return '$year-$month';
      case KLineTimeLabelGranularity.year:
        return year;
    }
  }

  static int _tickCountInRange(double low, double high, double step) {
    if (step <= 0 || !step.isFinite) {
      return 0;
    }

    final firstTick = (low / step).ceil() * step;
    final lastTick = (high / step).floor() * step;
    if (firstTick > lastTick) {
      return 0;
    }
    return ((lastTick - firstTick) / step).floor() + 1;
  }

  static double _niceStep(double rawStep, {required bool roundDown}) {
    if (rawStep <= 0 || !rawStep.isFinite) {
      return 0;
    }

    final exponent = pow(10, (log(rawStep) / _ln10).floor()).toDouble();
    final fraction = rawStep / exponent;
    final niceFraction = roundDown
        ? fraction < 2
            ? 1.0
            : fraction < 2.5
                ? 2.0
                : fraction < 5
                    ? 2.5
                    : fraction < 10
                        ? 5.0
                        : 10.0
        : fraction <= 1
            ? 1.0
            : fraction <= 2
                ? 2.0
                : fraction <= 2.5
                    ? 2.5
                    : fraction <= 5
                        ? 5.0
                        : 10.0;
    return niceFraction * exponent;
  }

  static double _nextNiceStep(double step) {
    final exponent = pow(10, (log(step) / _ln10).floor()).toDouble();
    final fraction = step / exponent;
    final nextFraction = fraction < 2
        ? 2.0
        : fraction < 2.5
            ? 2.5
            : fraction < 5
                ? 5.0
                : fraction < 10
                    ? 10.0
                    : 1.0;
    return nextFraction == 1.0 ? exponent * 10 : nextFraction * exponent;
  }

  static double _roundToStepPrecision(double value, double step) {
    final absStep = step.abs();
    final decimals =
        absStep >= 1 ? 6 : min(12, max(0, (-log(absStep) / _ln10).ceil() + 2));
    return double.parse(value.toStringAsFixed(decimals));
  }
}
