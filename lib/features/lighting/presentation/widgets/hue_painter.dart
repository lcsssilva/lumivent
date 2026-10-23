part of 'color_picker.dart';

class _HuePainter extends CustomPainter {
  _HuePainter(this.h);
  final double h;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var i = 0; i <= 6; i++) _c(Rgb.fromHsv(i * 60.0, 1, 1)),
          ],
        ).createShader(rect),
    );
    final x = h / 360 * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: 6,
          height: size.height + 4,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_HuePainter o) => o.h != h;
}
