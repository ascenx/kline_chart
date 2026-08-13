import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kline_chart/kline_chart.dart';

import 'demo_data.dart';

class OrientationDemoPage extends StatefulWidget {
  const OrientationDemoPage({
    super.key,
    this.initialData,
  });

  final List<KLineData>? initialData;

  @override
  State<OrientationDemoPage> createState() => _OrientationDemoPageState();
}

class _OrientationDemoPageState extends State<OrientationDemoPage> {
  late final KLineController _controller;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = KLineController()
      ..itemCount = 36
      ..showMainIndicators = [IndicatorType.ma]
      ..showSubIndicators = [IndicatorType.vol, IndicatorType.macd]
      ..showTimeAxis = true;

    final initialData = widget.initialData;
    if (initialData != null) {
      _setData(initialData);
      return;
    }

    loadDemoKLineData().then((data) {
      if (!mounted) return;
      setState(() => _setData(data));
    });
  }

  void _setData(List<KLineData> data) {
    _controller.setData(data);
    _controller.setOverlays(buildDemoOverlays(data));
    _loaded = true;
  }

  Future<void> _switchToLandscape() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _switchToPortrait() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _returnToHome() async {
    await _switchToPortrait();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildSwitchButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      key: key,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildChart() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey),
      ),
      child: _loaded
          ? KLineView(controller: _controller)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLimitationsNotice() {
    return const Text(
      key: Key('orientation_limitations_notice'),
      'System orientation requests may be ignored on iPad with multitasking enabled and on Android 16 devices with displays at least 600dp wide.',
      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
    );
  }

  Widget _buildControls(BuildContext context, Orientation orientation) {
    if (orientation == Orientation.landscape) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Landscape',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'The chart automatically redraws for the available width and height.',
          ),
          const SizedBox(height: 12),
          _buildLimitationsNotice(),
          const SizedBox(height: 16),
          _buildSwitchButton(
            key: const Key('switch_to_portrait_button'),
            icon: Icons.stay_current_portrait,
            label: 'Switch to portrait',
            onPressed: _switchToPortrait,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Portrait',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _buildSwitchButton(
              key: const Key('switch_to_landscape_button'),
              icon: Icons.stay_current_landscape,
              label: 'Switch to landscape',
              onPressed: _switchToLandscape,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLimitationsNotice(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _switchToPortrait();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('orientation_demo_back_button'),
            onPressed: _returnToHome,
            icon: const BackButtonIcon(),
          ),
          title: const Text('Portrait / Landscape Demo'),
        ),
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Flex(
                  direction: orientation == Orientation.landscape
                      ? Axis.horizontal
                      : Axis.vertical,
                  children: [
                    SizedBox(
                      key: Key('${orientation.name}_orientation_layout'),
                      width: orientation == Orientation.landscape ? 210 : null,
                      child: SingleChildScrollView(
                        key: const Key('orientation_controls_scroll_view'),
                        child: _buildControls(context, orientation),
                      ),
                    ),
                    SizedBox(
                      width: orientation == Orientation.landscape ? 12 : 0,
                      height: orientation == Orientation.portrait ? 12 : 0,
                    ),
                    Expanded(child: _buildChart()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
