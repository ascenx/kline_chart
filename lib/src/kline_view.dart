import 'dart:math';

import 'package:flutter/material.dart';
import './kline_controller.dart';
import 'indicators/indicator_data_cache.dart';
import 'indicators/indicator_info_painter.dart';
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
      trailingBlankItemCount: max(
        KLineController.shared.trailingBlankItemCount,
        KLineController.shared.maxTrailingBlankItemCount,
      ),
      minTrailingVisibleItemCount:
          KLineController.shared.minTrailingVisibleItemCount,
    );
    if ((_beginIdx - beginIdx).abs() < _scrollIndexTolerance) return;
    _beginIdx = beginIdx;
    setState(() {});
  }

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
      trailingBlankItemCount: max(
        KLineController.shared.trailingBlankItemCount,
        KLineController.shared.maxTrailingBlankItemCount,
      ),
      minTrailingVisibleItemCount:
          KLineController.shared.minTrailingVisibleItemCount,
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
          double itemExtent = itemW + spacing;
          final scrollTrailingBlankItemCount =
              KLineController.effectiveTrailingBlankItemCountFor(
            itemCount: itemCount,
            trailingBlankItemCount: max(
              KLineController.shared.trailingBlankItemCount,
              KLineController.shared.maxTrailingBlankItemCount,
            ),
            minTrailingVisibleItemCount:
                KLineController.shared.minTrailingVisibleItemCount,
          );
          // scroll size
          double contentSizeW =
              (dataLength + scrollTrailingBlankItemCount) * itemExtent;
          if (_beginIdx < 0) {
            // init
            // show begin index
            _beginIdx = KLineController.maxBeginIndexFor(
              dataLength: dataLength,
              itemCount: itemCount,
              trailingBlankItemCount:
                  KLineController.shared.trailingBlankItemCount,
              minTrailingVisibleItemCount:
                  KLineController.shared.minTrailingVisibleItemCount,
            );
            // double beginOffset = _beginIdx / dataLength * contentSizeW;
            double beginOffset = _beginIdx * itemExtent;
            _initScrollController(beginOffset);
          }
          final indicatorDataCache =
              KLineIndicatorDataCache(KLineController.shared.data, _beginIdx);
          return CustomPaint(
              painter: KLinePainter(KLineController.shared.data, _beginIdx,
                  indicatorDataCache: indicatorDataCache),
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
                    Positioned.fill(
                      child: IgnorePointer(
                          child: RepaintBoundary(
                        child: CustomPaint(
                          painter: KLineIndicatorInfoPainter(
                              KLineController.shared.data, _beginIdx,
                              indicatorDataCache: indicatorDataCache),
                        ),
                      )),
                    ),
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
