import 'package:flutter/material.dart';
import './kline_controller.dart';
import './kline_info_widget.dart';
import './kline_long_press_widget.dart';
import './kline_painter.dart';

class KLineView extends StatefulWidget {

  KLineView({super.key});

  @override
  State<StatefulWidget> createState() => _KLineViewState();
}

class _KLineViewState extends State<KLineView> {

  late final ScrollController _klineScrollCtr;

  bool _hasInitScrollController = false;
  double _beginIdx = -1.0;

  double _zoomFactor = 1.0;
  double _currentScale = 1.0;

  // int _dataLength = 0;

  void _initScrollController(double initOffset) {
    if (_hasInitScrollController) return;
    _klineScrollCtr = ScrollController(initialScrollOffset: initOffset);

    _klineScrollCtr.addListener(() {
      double offsetX = _klineScrollCtr.offset;
      _klineDidScroll(offsetX);
    });
    _hasInitScrollController = true;
  }

  void _klineDidScroll(double offsetX) {
    KLineController.shared.longPressOffset.update(Offset.zero);
    double itemW = KLineController.shared.itemWidth;
    double spacing = KLineController.shared.spacing;
    double nowIdx = offsetX / (itemW + spacing);
    debugPrint('nowIdx: $nowIdx');
    if (nowIdx < 0) {
      _beginIdx = 0.0;
    } else {
        if (nowIdx + KLineController.shared.itemCount > KLineController.shared.data.length) {
          // print("00000000 return:$nowIdx, count:${KLineConfig.shared.itemCount}, _dataLength: $_dataLength");
          return;
        }
        _beginIdx = nowIdx;
    }
    debugPrint('beginIdx:$_beginIdx');
    // if (_lastBeginIdx == _beginIdx) return;
    setState(() {
      // _lastBeginIdx = _beginIdx;
    });
  }

  // void _klineDidZoom(ScaleUpdateDetails details) {
  //   double scale = details.scale;
  //   if (details.pointerCount != 2) {
  //     return;
  //   }
  //
  //   if (scale > 1.5) {
  //     _currentScale = 1.5;
  //   } else if (scale < 0.5) {
  //     _currentScale = 0.5;
  //   } else {
  //     _currentScale = _previousScale * scale;
  //   }
  //
  //   int count = KLineController.shared.itemCount + ((1 - _currentScale) * 4).ceil();
  //
  //   int maxCount = _dataLength > KLineController.shared.maxCount ? KLineController.shared.maxCount : _dataLength;
  //   count = count > maxCount ? maxCount : count;
  //   count = count < KLineController.shared.minCount ? KLineController.shared.minCount : count;
  //   if (count + _beginIdx >= _dataLength) {
  //     _beginIdx = (_dataLength - count).toDouble();
  //   }
  //   KLineController.shared.itemCount = count;
  //   setState(() {
  //   });
  // }

  void _klineDidZoom(ScaleUpdateDetails details) {
    if (details.pointerCount != 2) return;


    double scaleDelta = details.scale / _zoomFactor;
    _zoomFactor = details.scale;

    double newScale = _currentScale * scaleDelta;

    debugPrint('details.scale: ${details.scale}, newScale: $newScale');

    if (newScale > 1.5) {
      _currentScale = 1.5;
    } else if (newScale < 0.5) {
      _currentScale = 0.5;
    } else {
      _currentScale = newScale;
    }

    double dataLength = KLineController.shared.data.length.toDouble();
    double count = KLineController.shared.itemCount + ((1 - _currentScale) * 4).ceil();
    double maxCount = dataLength > KLineController.shared.maxCount
        ? KLineController.shared.maxCount
        : dataLength;

    count = count > maxCount ? maxCount : count;
    count = count < KLineController.shared.minCount ? KLineController.shared.minCount : count;


    setState(() {
      _beginIdx = _beginIdx + (KLineController.shared.itemCount - count) / 2;
      if (count + _beginIdx >= dataLength) {
        _beginIdx = (dataLength - count).toDouble();
      }
      KLineController.shared.itemCount = count;
    });
  }

  void _klineLongPress(Offset offset) {
    KLineController.shared.longPressOffset.update(offset);
  }

  @override
  Widget build(BuildContext context) {

    int dataLength = KLineController.shared.data.length;
    if (dataLength == 0) {
      return const Center(child: CircularProgressIndicator(
        strokeWidth: 2.0,
        color: Colors.blueGrey,
      ));
    }
    return Container(
      margin: KLineController.shared.klineMargin,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          double containerW = constraints.maxWidth;
          double containerH = constraints.maxHeight;

          double itemCount = KLineController.shared.itemCount;
          double itemW = KLineController.getItemWidth(containerW);
          double spacing = KLineController.shared.spacing;
          // scroll size
          double contentSizeW = dataLength * (itemW + spacing);
          if (_beginIdx < 0) { // init
            // show begin index
            _beginIdx = (dataLength - itemCount).toDouble();
            if (_beginIdx < 0) _beginIdx = 0;
            // double beginOffset = _beginIdx / dataLength * contentSizeW;
            double beginOffset = dataLength < itemCount ? 0.0 : contentSizeW - containerW;
            _initScrollController(beginOffset);
          }
          return CustomPaint(
              painter: KLinePainter(KLineController.shared.data, _beginIdx),
              size: Size(containerW, containerH),
              child: GestureDetector(
                onScaleStart: (details) => debugPrint('onScaleStart details.focalPoint: ${details.focalPoint}, details.localFocalPoint: ${details.localFocalPoint}'),
                onScaleEnd: (details) => debugPrint('onScaleEnd details.velocity: ${details.velocity}, details.scaleVelocity: ${details.scaleVelocity}'),
                onScaleUpdate: (details) => _klineDidZoom(details),
                onLongPressStart: (details) => _klineLongPress(details.localPosition),
                onLongPressMoveUpdate: (details) => _klineLongPress(details.localPosition),
                onLongPressEnd: (details) => _klineLongPress(details.localPosition),
                onTap: () => _klineLongPress(Offset.zero),
                child: Stack(
                  children: [
                    Positioned.fill(child: SingleChildScrollView(
                      controller: _klineScrollCtr,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentSizeW,
                        height: containerH,
                      ),
                    )),
                    Align(
                      alignment: Alignment.topLeft,
                      child: RepaintBoundary(
                        child: KlineInfoWidget(KLineController.shared.data, _beginIdx),
                      ),
                    ),
                    Positioned.fill(child: RepaintBoundary(
                      child: KlineLongPressWidget(KLineController.shared.data, _beginIdx),
                    ))
                  ],
                ),
              )
          );
        })
    );
  }

  @override
  void dispose() {
    _klineScrollCtr.dispose();
    super.dispose();
  }
}
