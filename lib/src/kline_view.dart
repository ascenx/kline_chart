import 'package:flutter/material.dart';
import './kline_controller.dart';
import './kline_info_widget.dart';
import './kline_long_press_widget.dart';
import './kline_painter.dart';

const double _scrollIndexTolerance = 0.000001;
const double _scrollOffsetTolerance = 0.01;

class KLineView extends StatefulWidget {
  KLineView({super.key});

  @override
  State<StatefulWidget> createState() => _KLineViewState();
}

class _KLineViewState extends State<KLineView> {
  ScrollController? _klineScrollCtr;

  bool _hasInitScrollController = false;
  double _beginIdx = -1.0;

  double _zoomStartBeginIdx = 0.0;
  double _zoomStartItemCount = 0.0;
  double _zoomStartFocalDx = 0.0;
  double _viewportWidth = 0.0;
  double _pendingScrollBeginIdx = 0.0;
  double _pendingScrollItemCount = 0.0;
  bool _hasPendingScrollSync = false;

  // int _dataLength = 0;

  void _initScrollController(double initOffset) {
    if (_hasInitScrollController) return;
    final controller = ScrollController(initialScrollOffset: initOffset);
    _klineScrollCtr = controller;

    controller.addListener(() {
      double offsetX = controller.offset;
      _klineDidScroll(offsetX);
    });
    _hasInitScrollController = true;
  }

  void _klineDidScroll(double offsetX) {
    KLineController.shared.longPressOffset.update(Offset.zero);
    double itemW = KLineController.shared.itemWidth;
    double spacing = KLineController.shared.spacing;
    double beginIdx = KLineController.beginIndexForScrollOffset(
      offset: offsetX,
      itemExtent: itemW + spacing,
      itemCount: KLineController.shared.itemCount,
      dataLength: KLineController.shared.data.length,
    );
    if ((_beginIdx - beginIdx).abs() < _scrollIndexTolerance) return;
    _beginIdx = beginIdx;
    setState(() {});
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
    if (details.pointerCount != 2 || _viewportWidth <= 0) return;

    final result = KLineController.zoomForScale(
      startBeginIndex: _zoomStartBeginIdx,
      startItemCount: _zoomStartItemCount,
      scale: details.scale,
      startFocalDx: _zoomStartFocalDx,
      currentFocalDx: details.localFocalPoint.dx,
      viewportWidth: _viewportWidth,
      dataLength: KLineController.shared.data.length,
      minItemCount: KLineController.shared.minCount,
      maxItemCount: KLineController.shared.maxCount,
    );

    if ((_beginIdx - result.beginIndex).abs() < _scrollIndexTolerance &&
        (KLineController.shared.itemCount - result.itemCount).abs() <
            _scrollIndexTolerance) {
      return;
    }

    setState(() {
      _beginIdx = result.beginIndex;
      KLineController.shared.itemCount = result.itemCount;
    });
    _syncScrollOffset(result.beginIndex, result.itemCount);
  }

  void _syncScrollOffset(double beginIdx, double itemCount) {
    final controller = _klineScrollCtr;
    if (controller == null || itemCount <= 0 || _viewportWidth <= 0) return;

    _pendingScrollBeginIdx = beginIdx;
    _pendingScrollItemCount = itemCount;
    if (_hasPendingScrollSync) return;
    _hasPendingScrollSync = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasPendingScrollSync = false;
      if (!mounted || !controller.hasClients) return;

      final targetOffset =
          _pendingScrollBeginIdx * _viewportWidth / _pendingScrollItemCount;
      final clampedOffset = targetOffset
          .clamp(controller.position.minScrollExtent,
              controller.position.maxScrollExtent)
          .toDouble();
      if ((controller.offset - clampedOffset).abs() < _scrollOffsetTolerance) {
        return;
      }
      controller.jumpTo(clampedOffset);
    });
  }

  void _klineLongPress(Offset offset) {
    KLineController.shared.longPressOffset.update(offset);
  }

  @override
  Widget build(BuildContext context) {
    int dataLength = KLineController.shared.data.length;
    if (dataLength == 0) {
      return const Center(
          child: CircularProgressIndicator(
        strokeWidth: 2.0,
        color: Colors.blueGrey,
      ));
    }
    return Container(
        margin: KLineController.shared.klineMargin,
        child: LayoutBuilder(builder: (ctx, constraints) {
          double containerW = constraints.maxWidth;
          double containerH = constraints.maxHeight;
          _viewportWidth = containerW;

          double itemCount = KLineController.shared.itemCount;
          double itemW = KLineController.getItemWidth(containerW);
          double spacing = KLineController.shared.spacing;
          // scroll size
          double contentSizeW = dataLength * (itemW + spacing);
          if (_beginIdx < 0) {
            // init
            // show begin index
            _beginIdx = (dataLength - itemCount).toDouble();
            if (_beginIdx < 0) _beginIdx = 0;
            // double beginOffset = _beginIdx / dataLength * contentSizeW;
            double beginOffset =
                dataLength < itemCount ? 0.0 : contentSizeW - containerW;
            _initScrollController(beginOffset);
          }
          return CustomPaint(
              painter: KLinePainter(KLineController.shared.data, _beginIdx),
              size: Size(containerW, containerH),
              child: GestureDetector(
                onScaleStart: (details) {
                  _zoomStartBeginIdx = _beginIdx < 0 ? 0.0 : _beginIdx;
                  _zoomStartItemCount = KLineController.shared.itemCount;
                  _zoomStartFocalDx = details.localFocalPoint.dx;
                },
                onScaleUpdate: (details) => _klineDidZoom(details),
                onLongPressStart: (details) =>
                    _klineLongPress(details.localPosition),
                onLongPressMoveUpdate: (details) =>
                    _klineLongPress(details.localPosition),
                onLongPressEnd: (details) =>
                    _klineLongPress(details.localPosition),
                onTap: () => _klineLongPress(Offset.zero),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: SingleChildScrollView(
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
                        child: KlineInfoWidget(
                            KLineController.shared.data, _beginIdx),
                      ),
                    ),
                    Positioned.fill(
                        child: RepaintBoundary(
                      child: KlineLongPressWidget(
                          KLineController.shared.data, _beginIdx),
                    ))
                  ],
                ),
              ));
        }));
  }

  @override
  void dispose() {
    _klineScrollCtr?.dispose();
    super.dispose();
  }
}
