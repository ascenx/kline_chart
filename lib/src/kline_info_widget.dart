import 'package:flutter/material.dart';
import './kline_chart_style.dart';
import './kline_controller.dart';
import './kline_data.dart';

class KlineInfoWidget extends StatelessWidget {
  final List<KLineData> klineData;
  final double beginIdx;
  final KLineController controller;

  KlineInfoWidget(
    this.klineData,
    this.beginIdx, {
    super.key,
    KLineController? controller,
  }) : controller = controller ?? KLineController.shared;

  @override
  Widget build(BuildContext context) {
    var ctr = controller;
    return ValueListenableBuilder<Offset>(
        valueListenable: controller.longPressOffset,
        builder: (ctx, offset, child) {
          double offsetX = offset.dx;
          int index = KLineController.dataIndexForLocalX(
            localX: offsetX,
            beginIndex: beginIdx,
            itemWidth: ctr.itemWidth,
            spacing: ctr.spacing,
            dataLength: klineData.length,
          );
          if (offsetX != 0.0 && index >= 0 && index < klineData.length) {
            KLineData data = klineData[index];
            return Container(
                width: ctr.infoWidgetMaxWidth,
                margin: ctr.infoWidgetMargin,
                padding: ctr.infoWidgetPadding,
                decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ctr.infoWidgetBorderRadius),
                    border: ctr.infoWidgetBorder,
                    color: ctr.infoStyle.backgroundColor),
                child: CustomPaint(
                  size: Size(ctr.infoWidgetMaxWidth ?? 120, 110),
                  painter: KLineLongPressInfoPainter(
                    data,
                    beginIdx,
                    offset,
                    controller: controller,
                    infoStyle: ctr.infoStyle,
                  ),
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

  var longPressOffset = Offset.zero;
  final KLineInfoStyle infoStyle;
  final KLineController controller;
  final KLineNumberFormatter? _priceFormatter;
  final KLineNumberFormatter? _volumeFormatter;
  final _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 2,
  );

  KLineLongPressInfoPainter(
    this.klineData,
    this.beginIdx,
    this.longPressOffset, {
    KLineController? controller,
    this.infoStyle = const KLineInfoStyle(),
  })  : controller = controller ?? KLineController.shared,
        _priceFormatter = (controller ?? KLineController.shared).priceFormatter,
        _volumeFormatter =
            (controller ?? KLineController.shared).volumeFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    double leftPadding = controller.infoWidgetPadding.left;
    double topPadding = controller.infoWidgetPadding.top;
    double fontHeight = 14;

    drawText(
        canvas,
        'time:${DateTime.fromMillisecondsSinceEpoch(klineData.time).toString()}',
        Offset(leftPadding, topPadding),
        size,
        width: size.width);
    drawText(canvas, 'high:${controller.formatPrice(klineData.high)}',
        Offset(leftPadding, topPadding + fontHeight * 2), size);
    drawText(canvas, 'open:${controller.formatPrice(klineData.open)}',
        Offset(leftPadding, topPadding + fontHeight * 3), size);
    drawText(canvas, 'low:${controller.formatPrice(klineData.low)}',
        Offset(leftPadding, topPadding + fontHeight * 4), size);
    drawText(canvas, 'close:${controller.formatPrice(klineData.close)}',
        Offset(leftPadding, topPadding + fontHeight * 5), size);
    drawText(canvas, 'volume:${controller.formatVolume(klineData.volume)}',
        Offset(leftPadding, topPadding + fontHeight * 6), size);
  }

  void drawText(Canvas canvas, String text, Offset offset, Size canvasSize,
      {double? width}) {
    _textPainter.text = TextSpan(text: text, style: infoStyle.textStyle);
    _textPainter.layout(maxWidth: width ?? canvasSize.width);

    // double textWidth = painter.width;
    _textPainter.paint(canvas, Offset(offset.dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant KLineLongPressInfoPainter oldDelegate) {
    return klineData != oldDelegate.klineData ||
        infoStyle != oldDelegate.infoStyle ||
        _priceFormatter != oldDelegate._priceFormatter ||
        _volumeFormatter != oldDelegate._volumeFormatter;
  }
}
