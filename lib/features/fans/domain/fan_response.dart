// Fans module domain (pure Dart): fan response smoothing, the equivalent of the
// BIOS "Fan Speed Up/Down Time". Ryzen Tctl jumps 10–15 °C within seconds;
// without smoothing the fan would speed up and slow down on every spike.

/// How quickly the fan follows temperature.
enum FanResponse {
  /// No averaging or ramping: follows temperature every second.
  fast(
    window: Duration.zero,
    rampUp: double.infinity,
    rampDown: double.infinity,
  ),

  /// 4-second average; increases duty by 15 points per second and decreases by 3.
  normal(window: Duration(seconds: 4), rampUp: 15, rampDown: 3),

  /// 10-second average; increases by 5 points per second and decreases by 1.
  smooth(window: Duration(seconds: 10), rampUp: 5, rampDown: 1);

  const FanResponse({
    required this.window,
    required this.rampUp,
    required this.rampDown,
  });

  /// Temperature moving-average window.
  final Duration window;

  /// Maximum duty change, in percentage points per second.
  final double rampUp;
  final double rampDown;
}
