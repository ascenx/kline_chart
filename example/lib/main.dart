import 'package:flutter/material.dart';
import 'package:kline_chart/kline_chart.dart';
import 'demo_data.dart';
import 'multi_controller_demo_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Column(
          children: [
            Container(
              alignment: Alignment.centerRight,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                key: const Key('multi_controller_demo_button'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MultiControllerDemoPage(),
                  ));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Multi Controller Demo',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Text("Main Indicator"),
                  ...IndicatorType.values
                      .where((element) => element.isMain)
                      .map((e) {
                    return buildIndicator(e.name, e.isMain, clickIndicator);
                  })
                ])),
            Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Text("Sub Indicator"),
                  ...IndicatorType.values
                      .where((element) =>
                          !element.isMain && element != IndicatorType.maVol)
                      .map((e) {
                    return buildIndicator(e.name, e.isMain, clickIndicator);
                  })
                ])),
            Container(
                alignment: Alignment.centerLeft,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
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
                )),
            Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                decoration: const BoxDecoration(
                    border: Border.symmetric(
                        horizontal: BorderSide(color: Colors.black))),
                child: KLineView())
          ],
        )) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
