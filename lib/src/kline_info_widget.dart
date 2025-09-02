import 'dart:async';

import 'package:flutter/material.dart';
import './kline_controller.dart';
import './kline_data.dart';

class KlineInfoWidget extends StatelessWidget {
  final List<KLineData> klineData;
  final double beginIdx;

  const KlineInfoWidget(this.klineData, this.beginIdx, {super.key});

  @override
  Widget build(BuildContext context) {
    var ctr = KLineController.shared;
    return ValueListenableBuilder<Offset>(
        valueListenable: KLineController.shared.longPressOffset,
        builder: (ctx, offset, child) {
          double offsetX = offset.dx;
          int index = (offsetX / (ctr.itemWidth + ctr.spacing) + beginIdx).ceil();
          if (offsetX != 0.0 && index >= 0 && index < klineData.length) {
            KLineData data = klineData[index];
            return Container(
                width: ctr.infoWidgetMaxWidth,
                margin: ctr.infoWidgetMargin,
                padding: ctr.infoWidgetPadding,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ctr.infoWidgetBorderRadius),
                    border: ctr.infoWidgetBorder,
                    color: Colors.white.withValues(alpha: 0.8)),
                child: CustomPaint(
                  size: Size(ctr.infoWidgetMaxWidth ?? 120, 110),
                  painter: KLineLongPressInfoPainter(data, beginIdx, offset),
                ));
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}

class KLineLongPressInfoPainter extends CustomPainter {
  final KLineData klineData;
  final double beginIdx;

  StreamSubscription? longPressSub;

  var longPressOffset = Offset.zero;

  KLineLongPressInfoPainter(this.klineData, this.beginIdx, this.longPressOffset);

  @override
  void paint(Canvas canvas, Size size) {
    double leftPadding = KLineController.shared.infoWidgetPadding.left;
    double topPadding = KLineController.shared.infoWidgetPadding.top;
    double fontHeight = 14;

    drawText(canvas, 'time:${DateTime.fromMillisecondsSinceEpoch(klineData.time).toString()}', Offset(leftPadding, topPadding), size,
        width: size.width);
    drawText(canvas, 'high:${klineData.high.toStringAsFixed(2)}', Offset(leftPadding, topPadding + fontHeight * 2), size);
    drawText(canvas, 'open:${klineData.open.toStringAsFixed(2)}', Offset(leftPadding, topPadding + fontHeight * 3), size);
    drawText(canvas, 'low:${klineData.low.toStringAsFixed(2)}', Offset(leftPadding, topPadding + fontHeight * 4), size);
    drawText(canvas, 'close:${klineData.close.toStringAsFixed(2)}', Offset(leftPadding, topPadding + fontHeight * 5), size);
    drawText(canvas, 'volume:${klineData.volume.toStringAsFixed(2)}', Offset(leftPadding, topPadding + fontHeight * 6), size);
  }

  void drawText(Canvas canvas, String text, Offset offset, Size canvasSize, {double? width}) {
    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 2,
        text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 12.0,
              height: 1.0,
            )))
      ..layout(maxWidth: width ?? canvasSize.width);

    // double textWidth = painter.width;
    painter.paint(canvas, Offset(offset.dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant KLineLongPressInfoPainter oldDelegate) {
    return klineData != oldDelegate.klineData;
  }
}
