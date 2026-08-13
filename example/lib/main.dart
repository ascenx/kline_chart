import 'package:flutter/material.dart';
import 'package:kline_chart/kline_chart.dart';
import 'demo_data.dart';
import 'multi_controller_demo_page.dart';
import 'orientation_demo_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: "flutter kline demo app",
        home: MyHomePage(title: 'flutter kline demo'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> mainIndicators =
      KLineController.shared.showMainIndicators.map((e) => e.name).toList();
  List<String> subIndicators =
      KLineController.shared.showSubIndicators.map((e) => e.name).toList();

  bool _showTimeChart = false;
  bool _showTimeAxis = false;
  bool _showOverlays = true;
  List<KLineData> _demoData = const [];

  @override
  initState() {
    super.initState();

    loadDemoKLineData().then((jsonData) {
      _demoData = jsonData;
      KLineController.shared.overlayStyle = const KLineOverlayStyle(
        priceLineColor: Color(0xff2563eb),
        priceLineStrokeWidth: 1,
        zoneOpacity: 0.14,
        markerRadius: 6,
        verticalLineColor: Color(0xfff59e0b),
      );
      KLineController.shared.setData(jsonData);
      _applyDemoOverlays();
      setState(() {});
    });
  }

  Widget buildIndicator(
      String name, bool isMain, void Function(String, bool) click) {
    Color c =
        (isMain ? mainIndicators.contains(name) : subIndicators.contains(name))
            ? Colors.blue
            : Colors.grey;
    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(name, style: TextStyle(fontSize: 14, color: c)),
      ),
      onTap: () => click(name, isMain),
    );
  }

  void clickIndicator(name, isMain) {
    if (isMain) {
      if (mainIndicators.contains(name)) {
        mainIndicators.remove(name);
      } else {
        if (mainIndicators.isNotEmpty) {
          mainIndicators.removeAt(0);
        }
        mainIndicators.add(name);
      }

      KLineController.shared.showMainIndicators =
          mainIndicators.map((e) => IndicatorType.fromName(e)).toList();
    } else {
      if (subIndicators.contains(name)) {
        subIndicators.remove(name);
      } else if (subIndicators.length == 2) {
        if (subIndicators.isNotEmpty) {
          subIndicators.removeAt(0);
        }
        subIndicators.add(name);
      } else {
        subIndicators.add(name);
      }
      KLineController.shared.showSubIndicators =
          subIndicators.map((e) => IndicatorType.fromName(e)).toList();
    }
    setState(() {});
  }

  void _applyDemoOverlays() {
    if (_showOverlays) {
      KLineController.shared.setOverlays(buildDemoOverlays(_demoData));
    } else {
      KLineController.shared.clearOverlays();
    }
  }

  Widget _buildToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.blue : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDemoNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        key: const Key('demo_navigation_wrap'),
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 8,
        children: [
          _buildDemoLink(
            key: const Key('orientation_demo_button'),
            label: 'Orientation Demo',
            icon: Icons.screen_rotation,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const OrientationDemoPage(),
              ));
            },
          ),
          _buildDemoLink(
            key: const Key('multi_controller_demo_button'),
            label: 'Multi Controller Demo',
            icon: Icons.chevron_right,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const MultiControllerDemoPage(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDemoLink({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 18, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildIndicatorSection(String title, bool isMain) {
    final indicators = IndicatorType.values.where((element) {
      return isMain
          ? element.isMain
          : !element.isMain && element != IndicatorType.maVol;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 8,
        children: [
          Text(title),
          ...indicators.map((e) {
            return buildIndicator(e.name, e.isMain, clickIndicator);
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          key: const Key('home_scroll_view'),
          child: Column(
            children: [
              _buildDemoNavigation(context),
              _buildIndicatorSection('Main Indicator', true),
              _buildIndicatorSection('Sub Indicator', false),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildToggle(
                      label: 'Time',
                      selected: _showTimeChart,
                      onTap: () => setState(() {
                        _showTimeChart = !_showTimeChart;
                        KLineController.shared.showTimeChart = _showTimeChart;
                      }),
                    ),
                    _buildToggle(
                      label: 'Time Axis',
                      selected: _showTimeAxis,
                      onTap: () => setState(() {
                        _showTimeAxis = !_showTimeAxis;
                        KLineController.shared.showTimeAxis = _showTimeAxis;
                      }),
                    ),
                    _buildToggle(
                      label: 'Overlay / Marker',
                      selected: _showOverlays,
                      onTap: () => setState(() {
                        _showOverlays = !_showOverlays;
                        _applyDemoOverlays();
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 400,
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Colors.black),
                  ),
                ),
                child: KLineView(),
              ),
            ],
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
