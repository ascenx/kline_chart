## 1.0.2

- Add adaptive price axis ticks with configurable maximum tick count and minimum label spacing.
- Add an optional bottom time axis with automatic label granularity and custom time formatting.
- Export `KLineTimeFormatter` and `KLineTimeLabelGranularity` from the public package API.
- Add example controls and documentation for the optional time axis and axis configuration.

## 1.0.1

- Add instance-based controllers with `KLineView(controller: ...)` while keeping `KLineController.shared` as the default legacy entry point.
- Add an example page demonstrating multiple independent chart controllers.
- Add controller data lifecycle APIs for full data replacement, real-time last-candle updates, appends, prepended history, clearing data, automatic chart refresh, and `KLineView.onLoadMore`.
- Keep legacy `controller.data = dataList` assignment compatible while recommending named data update methods for production usage.

## 1.0.0

- Promote the package to the first stable `1.0.0` release.
- Add comprehensive usage wiki documentation in English and Simplified Chinese.
- Add Simplified Chinese README documentation.
- Add customizable number formatting for prices, volumes, and indicator values.
- Add compact default volume formatting with `K`, `M`, and `B` suffixes.
- Add configurable trailing blank space after the latest candle, including maximum trailing blank range and minimum visible real candle count.
- Add grouped chart style APIs for chart canvas, candles, volume bars, crosshair, and info overlay customization.
- Add SAR color customization and extended indicator style options.
- Improve line indicator alignment so latest indicator points align with the latest candle.
- Improve fractional scroll rendering for line indicators, VOL, and MACD so candles and indicators leave the viewport smoothly.
- Fix MACD leading histogram rendering so the first visible bar keeps the correct hollow or filled style.
- Improve chart drawing performance by reusing indicator info painters, batching paths, reducing repaint overhead, and adding benchmark coverage.
- Add API and style documentation for advanced controller-based customization.
- Add display-only main chart overlays for price lines, price zones, candle markers, and event lines.

## 0.0.1+4

- Add grouped chart, candle, volume, crosshair, and info style customization.
- Add configurable SAR point color.
- Add SAR main chart indicator with configurable acceleration factors.
- Add RSI and MACD sub indicators.
- Add MACD histogram rendering with signal lines.
- Improve long-press candle selection and crosshair alignment.
- Move indicator info text into a separate repaint layer to reduce full chart repaints during long-press interactions.
- Show selected indicator values during long press, including MA, VOL MA, MACD, KDJ, RSI, WR, and OBV values.
- Update package description for pub.dev.
- Add tests for indicator calculations, rendering stability, zoom behavior, and long-press indicator info.

## 0.0.1+3

- Improve scroll and zoom boundary handling.
- Harden K-line rendering for short data sets, flat price data, zero volume data, and fractional trailing zoom windows.
- Fix empty indicator result typing.
- Improve example configuration and scroll handling.

## 0.0.1+2

- add example
- adapt to dart 2.17.0

## 0.0.1+1

- Initial version
