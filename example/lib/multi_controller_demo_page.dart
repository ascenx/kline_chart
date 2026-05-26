import 'package:flutter/material.dart';
import 'package:kline_chart/kline_chart.dart';

import 'demo_data.dart';

class MultiControllerDemoPage extends StatefulWidget {
  const MultiControllerDemoPage({super.key});

  @override
  State<MultiControllerDemoPage> createState() =>
      _MultiControllerDemoPageState();
}

class _MultiControllerDemoPageState extends State<MultiControllerDemoPage> {
  late final KLineController _trendController;
  late final KLineController _momentumController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _trendController = KLineController()
      ..itemCount = 45
      ..showMainIndicators = [IndicatorType.ma]
      ..showSubIndicators = [IndicatorType.vol, IndicatorType.macd]
      ..trailingBlankItemCount = 5
      ..maxTrailingBlankItemCount = 18
      ..minTrailingVisibleItemCount = 4
      ..chartStyle = const KLineChartStyle(
        backgroundColor: Color(0xff0b1016),
        gridLineColor: Color(0x223d4a5c),
        gridLineWidth: 1,
        rulerTextStyle: TextStyle(color: Color(0xff7f8ea3), fontSize: 12),
        highLowLineColor: Color(0xff7f8ea3),
        highLowTextStyle: TextStyle(color: Color(0xffc8d3e2), fontSize: 12),
        currentPriceLineColor: Color(0xffc8d3e2),
        currentPriceBackgroundColor: Color(0xff0b1016),
        currentPriceTextStyle: TextStyle(
          color: Color(0xffc8d3e2),
          fontSize: 12,
        ),
      )
      ..candleStyle = const KLineCandleStyle(
        riseColor: Color(0xff22ab94),
        fallColor: Color(0xfff23645),
        riseWickColor: Color(0xff22ab94),
        fallWickColor: Color(0xfff23645),
      )
      ..volumeStyle = const KLineVolumeStyle(
        riseColor: Color(0x6622ab94),
        fallColor: Color(0x66f23645),
      )
      ..overlayStyle = const KLineOverlayStyle(
        priceLineColor: Color(0xff60a5fa),
        priceLineStrokeWidth: 1,
        zoneOpacity: 0.16,
        markerRadius: 6,
        verticalLineColor: Color(0xfffbbf24),
      )
      ..indicatorColors = [
        Colors.orange,
        Colors.purple,
        Colors.blue,
      ];

    _momentumController = KLineController()
      ..itemCount = 28
      ..showMainIndicators = [IndicatorType.boll]
      ..showSubIndicators = [IndicatorType.rsi]
      ..bollPeriod = 21
      ..bollBandwidth = 2
      ..rsiPeriods = [6, 12, 24]
      ..trailingBlankItemCount = 2
      ..maxTrailingBlankItemCount = 8
      ..minTrailingVisibleItemCount = 4
      ..priceFormatter = ((value) => value.toStringAsFixed(2))
      ..indicatorFormatter = ((value, type, period) {
        if (type == IndicatorType.rsi) {
          return value.toStringAsFixed(1);
        }
        return value.toStringAsFixed(2);
      })
      ..chartStyle = const KLineChartStyle(
        backgroundColor: Color(0xfff8fafc),
        gridLineColor: Color(0xffe2e8f0),
        gridLineWidth: 1,
        rulerTextStyle: TextStyle(color: Color(0xff64748b), fontSize: 12),
        highLowLineColor: Color(0xff64748b),
        highLowTextStyle: TextStyle(color: Color(0xff334155), fontSize: 12),
        currentPriceLineColor: Color(0xff334155),
        currentPriceBackgroundColor: Color(0xffffffff),
        currentPriceTextStyle: TextStyle(
          color: Color(0xff334155),
          fontSize: 12,
        ),
      )
      ..candleStyle = const KLineCandleStyle(
        riseColor: Color(0xff16a34a),
        fallColor: Color(0xffdc2626),
        riseWickColor: Color(0xff16a34a),
        fallWickColor: Color(0xffdc2626),
      )
      ..volumeStyle = const KLineVolumeStyle(
        riseColor: Color(0x5516a34a),
        fallColor: Color(0x55dc2626),
      )
      ..overlayStyle = const KLineOverlayStyle(
        priceLineColor: Color(0xff2563eb),
        priceLineStrokeWidth: 1,
        zoneOpacity: 0.12,
        markerRadius: 6,
        verticalLineColor: Color(0xffea580c),
      )
      ..indicatorColors = [
        const Color(0xff2563eb),
        const Color(0xff9333ea),
        const Color(0xffea580c),
      ];

    loadDemoKLineData().then((data) {
      final overlays = buildDemoOverlays(data);
      _trendController.setData(data);
      _trendController.setOverlays(overlays);
      _momentumController.setData(List<KLineData>.of(data));
      _momentumController.setOverlays(overlays);
      setState(() {
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi Controller Demo'),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MultiControllerChartSection(
                  title: 'Trend view',
                  subtitle: 'Independent controller: MA + VOL + MACD',
                  controller: _trendController,
                  borderColor: const Color(0xff111827),
                ),
                const SizedBox(height: 24),
                _MultiControllerChartSection(
                  title: 'Momentum view',
                  subtitle: 'Independent controller: BOLL + RSI',
                  controller: _momentumController,
                  borderColor: const Color(0xffcbd5e1),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MultiControllerChartSection extends StatelessWidget {
  const _MultiControllerChartSection({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.borderColor,
  });

  final String title;
  final String subtitle;
  final KLineController controller;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.blueGrey),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
          ),
          child: KLineView(controller: controller),
        ),
      ],
    );
  }
}
