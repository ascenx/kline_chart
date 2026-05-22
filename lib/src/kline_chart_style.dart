import 'package:flutter/material.dart';

/// Visual styling for the main chart canvas and auxiliary chart labels.
class KLineChartStyle {
  /// Background color painted behind the entire chart.
  final Color backgroundColor;

  /// Grid line color for vertical and horizontal ruler lines.
  final Color gridLineColor;

  /// Grid line stroke width.
  final double gridLineWidth;

  /// Text style for price ruler labels.
  final TextStyle rulerTextStyle;

  /// Line color for highest and lowest price callouts.
  final Color highLowLineColor;

  /// Line stroke width for highest and lowest price callouts.
  final double highLowLineWidth;

  /// Text style for highest and lowest price labels.
  final TextStyle highLowTextStyle;

  /// Line and border color for the current price marker.
  final Color currentPriceLineColor;

  /// Stroke width for the current price line and marker border.
  final double currentPriceLineWidth;

  /// Background color for the current price marker.
  final Color currentPriceBackgroundColor;

  /// Text style for the current price marker.
  final TextStyle currentPriceTextStyle;

  /// Line color for time chart mode.
  final Color timeLineColor;

  /// Stroke width for time chart mode.
  final double timeLineWidth;

  /// Fill color for the time chart area gradient.
  final Color timeLineFillColor;

  /// Creates main chart visual styling.
  const KLineChartStyle({
    this.backgroundColor = Colors.transparent,
    this.gridLineColor = const Color(0x33607d8b),
    this.gridLineWidth = 0.0,
    this.rulerTextStyle = const TextStyle(
      color: Color(0xff999999),
      fontSize: 12.0,
      height: 1.0,
    ),
    this.highLowLineColor = const Color(0xff999999),
    this.highLowLineWidth = 1.0,
    this.highLowTextStyle = const TextStyle(
      color: Color(0xff666666),
      fontSize: 13.0,
      height: 1.0,
    ),
    this.currentPriceLineColor = Colors.black54,
    this.currentPriceLineWidth = 1.0,
    this.currentPriceBackgroundColor = Colors.white,
    this.currentPriceTextStyle = const TextStyle(
      color: Color(0xff999999),
      fontSize: 12.0,
      height: 1.0,
    ),
    this.timeLineColor = Colors.blue,
    this.timeLineWidth = 1.0,
    this.timeLineFillColor = const Color(0xff40c4ff),
  });

  /// Returns a copy with selected values replaced.
  KLineChartStyle copyWith({
    Color? backgroundColor,
    Color? gridLineColor,
    double? gridLineWidth,
    TextStyle? rulerTextStyle,
    Color? highLowLineColor,
    double? highLowLineWidth,
    TextStyle? highLowTextStyle,
    Color? currentPriceLineColor,
    double? currentPriceLineWidth,
    Color? currentPriceBackgroundColor,
    TextStyle? currentPriceTextStyle,
    Color? timeLineColor,
    double? timeLineWidth,
    Color? timeLineFillColor,
  }) {
    return KLineChartStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      rulerTextStyle: rulerTextStyle ?? this.rulerTextStyle,
      highLowLineColor: highLowLineColor ?? this.highLowLineColor,
      highLowLineWidth: highLowLineWidth ?? this.highLowLineWidth,
      highLowTextStyle: highLowTextStyle ?? this.highLowTextStyle,
      currentPriceLineColor:
          currentPriceLineColor ?? this.currentPriceLineColor,
      currentPriceLineWidth:
          currentPriceLineWidth ?? this.currentPriceLineWidth,
      currentPriceBackgroundColor:
          currentPriceBackgroundColor ?? this.currentPriceBackgroundColor,
      currentPriceTextStyle:
          currentPriceTextStyle ?? this.currentPriceTextStyle,
      timeLineColor: timeLineColor ?? this.timeLineColor,
      timeLineWidth: timeLineWidth ?? this.timeLineWidth,
      timeLineFillColor: timeLineFillColor ?? this.timeLineFillColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineChartStyle &&
            other.backgroundColor == backgroundColor &&
            other.gridLineColor == gridLineColor &&
            other.gridLineWidth == gridLineWidth &&
            other.rulerTextStyle == rulerTextStyle &&
            other.highLowLineColor == highLowLineColor &&
            other.highLowLineWidth == highLowLineWidth &&
            other.highLowTextStyle == highLowTextStyle &&
            other.currentPriceLineColor == currentPriceLineColor &&
            other.currentPriceLineWidth == currentPriceLineWidth &&
            other.currentPriceBackgroundColor == currentPriceBackgroundColor &&
            other.currentPriceTextStyle == currentPriceTextStyle &&
            other.timeLineColor == timeLineColor &&
            other.timeLineWidth == timeLineWidth &&
            other.timeLineFillColor == timeLineFillColor;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        gridLineColor,
        gridLineWidth,
        rulerTextStyle,
        highLowLineColor,
        highLowLineWidth,
        highLowTextStyle,
        currentPriceLineColor,
        currentPriceLineWidth,
        currentPriceBackgroundColor,
        currentPriceTextStyle,
        timeLineColor,
        timeLineWidth,
        timeLineFillColor,
      );
}

/// Visual styling for candlestick bodies and wicks.
class KLineCandleStyle {
  /// Candle body color when close is greater than open.
  final Color riseColor;

  /// Candle body color when close is less than or equal to open.
  final Color fallColor;

  /// Candle wick color when close is greater than open.
  final Color riseWickColor;

  /// Candle wick color when close is less than or equal to open.
  final Color fallWickColor;

  /// Candle wick stroke width.
  final double wickLineWidth;

  /// Creates candlestick visual styling.
  const KLineCandleStyle({
    this.riseColor = Colors.green,
    this.fallColor = Colors.red,
    this.riseWickColor = Colors.green,
    this.fallWickColor = Colors.red,
    this.wickLineWidth = 2.0,
  });

  /// Returns a copy with selected values replaced.
  KLineCandleStyle copyWith({
    Color? riseColor,
    Color? fallColor,
    Color? riseWickColor,
    Color? fallWickColor,
    double? wickLineWidth,
  }) {
    return KLineCandleStyle(
      riseColor: riseColor ?? this.riseColor,
      fallColor: fallColor ?? this.fallColor,
      riseWickColor: riseWickColor ?? this.riseWickColor,
      fallWickColor: fallWickColor ?? this.fallWickColor,
      wickLineWidth: wickLineWidth ?? this.wickLineWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineCandleStyle &&
            other.riseColor == riseColor &&
            other.fallColor == fallColor &&
            other.riseWickColor == riseWickColor &&
            other.fallWickColor == fallWickColor &&
            other.wickLineWidth == wickLineWidth;
  }

  @override
  int get hashCode => Object.hash(
        riseColor,
        fallColor,
        riseWickColor,
        fallWickColor,
        wickLineWidth,
      );
}

/// Visual styling for volume bars.
class KLineVolumeStyle {
  /// Volume bar color when close is greater than open.
  final Color riseColor;

  /// Volume bar color when close is less than or equal to open.
  final Color fallColor;

  /// Creates volume bar visual styling.
  const KLineVolumeStyle({
    this.riseColor = Colors.green,
    this.fallColor = Colors.red,
  });

  /// Returns a copy with selected values replaced.
  KLineVolumeStyle copyWith({
    Color? riseColor,
    Color? fallColor,
  }) {
    return KLineVolumeStyle(
      riseColor: riseColor ?? this.riseColor,
      fallColor: fallColor ?? this.fallColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineVolumeStyle &&
            other.riseColor == riseColor &&
            other.fallColor == fallColor;
  }

  @override
  int get hashCode => Object.hash(riseColor, fallColor);
}

/// Visual styling for the long-press crosshair.
class KLineCrosshairStyle {
  /// Crosshair line color.
  final Color color;

  /// Crosshair line stroke width.
  final double strokeWidth;

  /// Creates long-press crosshair visual styling.
  const KLineCrosshairStyle({
    this.color = const Color(0xcc607d8b),
    this.strokeWidth = 0.0,
  });

  /// Returns a copy with selected values replaced.
  KLineCrosshairStyle copyWith({
    Color? color,
    double? strokeWidth,
  }) {
    return KLineCrosshairStyle(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineCrosshairStyle &&
            other.color == color &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(color, strokeWidth);
}

/// Visual styling for the long-press candle detail overlay.
class KLineInfoStyle {
  /// Background color for the candle detail overlay.
  final Color backgroundColor;

  /// Text style for candle detail overlay rows.
  final TextStyle textStyle;

  /// Creates long-press candle detail overlay styling.
  const KLineInfoStyle({
    this.backgroundColor = const Color(0xccffffff),
    this.textStyle = const TextStyle(
      color: Colors.blueGrey,
      fontSize: 12.0,
      height: 1.0,
    ),
  });

  /// Returns a copy with selected values replaced.
  KLineInfoStyle copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
  }) {
    return KLineInfoStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineInfoStyle &&
            other.backgroundColor == backgroundColor &&
            other.textStyle == textStyle;
  }

  @override
  int get hashCode => Object.hash(backgroundColor, textStyle);
}
