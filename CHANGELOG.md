## 0.0.1+4

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
