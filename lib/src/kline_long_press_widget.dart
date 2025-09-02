import 'dart:async';

import 'package:flutter/material.dart';
import './kline_controller.dart';
import './kline_data.dart';

class KlineLongPressWidget extends StatelessWidget {
  final List<KLineData> klineData;
  final double beginIdx;

  const KlineLongPressWidget(this.klineData, this.beginIdx, {super.key});

  Offset _convertToItemOffset(Offset offset) {
    double itemW = KLineController.shared.itemWidth;
    double spacing = KLineController.shared.spacing;
    double itemSpacingWidth = itemW + spacing;
    int index = (offset.dx / itemSpacingWidth).ceil() - 1;
    double indexOffset = beginIdx - beginIdx.ceil();
    double slideOffset = -indexOffset * itemSpacingWidth;
    double itemOffsetX = index * itemSpacingWidth - itemW * 0.5 + slideOffset;
    return Offset(itemOffsetX, offset.dy);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
        valueListenable: KLineController.shared.longPressOffset,
        builder: (ctx, offset, child) {
          if (offset == Offset.zero) return const SizedBox.shrink();
          Offset itemOffset = _convertToItemOffset(offset);
          return CustomPaint(
            foregroundPainter: KLineLongPressPainter(klineData, beginIdx, itemOffset),
          );
        });
  }
}

class KLineLongPressPainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;

  StreamSubscription? longPressSub;

  var longPressOffset = Offset.zero;

  KLineLongPressPainter(this.klineData, this.beginIdx, this.longPressOffset);

  final _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.blueGrey.withValues(alpha: 0.8);

  // draw kline

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    // draw vertical line
    canvas.drawLine(Offset(longPressOffset.dx, 0), Offset(longPressOffset.dx, size.height), _linePaint);
    // draw horizontal line
    canvas.drawLine(Offset(0, longPressOffset.dy), Offset(size.width, longPressOffset.dy), _linePaint);
  }

  @override
  bool shouldRepaint(covariant KLineLongPressPainter oldDelegate) {
    return longPressOffset.dx.ceil() != oldDelegate.longPressOffset.dx.ceil() || longPressOffset.dy != oldDelegate.longPressOffset.dy;
  }
}
