import 'package:flutter/material.dart';

/// Base type for display-only annotations drawn over the main K-line chart.
abstract class KLineOverlay {
  /// Creates a chart overlay annotation.
  const KLineOverlay();
}

/// Marker category used by [KLineMarker].
enum KLineMarkerType {
  /// Buy marker.
  buy,

  /// Sell marker.
  sell,

  /// Custom marker.
  custom,
}

/// Horizontal line annotation at a fixed price.
class KLinePriceLine extends KLineOverlay {
  /// Price value mapped to the main chart's price scale.
  final double price;

  /// Optional text shown near the right side of the line.
  final String? label;

  /// Optional line and label color override.
  final Color? color;

  /// Optional stroke width override.
  final double? strokeWidth;

  /// Creates a horizontal price line annotation.
  const KLinePriceLine({
    required this.price,
    this.label,
    this.color,
    this.strokeWidth,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLinePriceLine &&
            other.price == price &&
            other.label == label &&
            other.color == color &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(price, label, color, strokeWidth);
}

/// Filled price range annotation between two price values.
class KLinePriceZone extends KLineOverlay {
  /// First price boundary.
  final double fromPrice;

  /// Second price boundary.
  final double toPrice;

  /// Optional text shown inside the zone.
  final String? label;

  /// Optional fill and label color override.
  final Color? color;

  /// Optional fill opacity override.
  final double? opacity;

  /// Creates a price zone annotation.
  const KLinePriceZone({
    required this.fromPrice,
    required this.toPrice,
    this.label,
    this.color,
    this.opacity,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLinePriceZone &&
            other.fromPrice == fromPrice &&
            other.toPrice == toPrice &&
            other.label == label &&
            other.color == color &&
            other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(fromPrice, toPrice, label, color, opacity);
}

/// Point annotation anchored to a candle time and price.
class KLineMarker extends KLineOverlay {
  /// Candle timestamp used to align the marker to a data item.
  final int time;

  /// Price value mapped to the main chart's price scale.
  final double price;

  /// Marker category.
  final KLineMarkerType type;

  /// Optional text shown inside the marker.
  final String? label;

  /// Optional marker fill color override.
  final Color? color;

  /// Optional marker radius override.
  final double? radius;

  /// Creates a candle marker annotation.
  const KLineMarker({
    required this.time,
    required this.price,
    this.type = KLineMarkerType.custom,
    this.label,
    this.color,
    this.radius,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineMarker &&
            other.time == time &&
            other.price == price &&
            other.type == type &&
            other.label == label &&
            other.color == color &&
            other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(time, price, type, label, color, radius);
}

/// Vertical event line annotation anchored to a candle time.
class KLineVerticalLine extends KLineOverlay {
  /// Candle timestamp used to align the line to a data item.
  final int time;

  /// Optional text shown near the top of the line.
  final String? label;

  /// Optional line and label color override.
  final Color? color;

  /// Optional stroke width override.
  final double? strokeWidth;

  /// Creates a vertical event line annotation.
  const KLineVerticalLine({
    required this.time,
    this.label,
    this.color,
    this.strokeWidth,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineVerticalLine &&
            other.time == time &&
            other.label == label &&
            other.color == color &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(time, label, color, strokeWidth);
}
