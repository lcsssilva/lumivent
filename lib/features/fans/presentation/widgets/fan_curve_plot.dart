part of 'fan_curve_editor.dart';

/// Chart area geometry inside the widget.
class _FanCurvePlot {
  _FanCurvePlot(Size size)
    : rect = Rect.fromLTRB(
        44,
        26,
        math.max(45, size.width - 64),
        math.max(27, size.height - 28),
      );
  final Rect rect;

  double x(double temp) => rect.left + temp / 100 * rect.width;
  double y(double percent) => rect.bottom - percent / 100 * rect.height;
  Offset toOffset(FanPoint p) => Offset(x(p.temp), y(p.percent));
  double tempAt(double dx) =>
      ((dx - rect.left) / rect.width * 100).clamp(0, 100);
  double percentAt(double dy) =>
      ((rect.bottom - dy) / rect.height * 100).clamp(0, 100);
}
