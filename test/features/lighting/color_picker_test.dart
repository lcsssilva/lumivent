import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/lighting/presentation/color_picker.dart';

import '../../support/app_harness.dart';

void main() {
  test('rgbToHsv covers every hue sector', () {
    expect(rgbToHsv(const Rgb(255, 0, 0)).$1, closeTo(0, 1e-9));
    expect(rgbToHsv(const Rgb(255, 128, 0)).$1, closeTo(30.12, 0.1));
    expect(rgbToHsv(const Rgb(0, 255, 128)).$1, closeTo(150.12, 0.1));
    expect(rgbToHsv(const Rgb(0, 128, 255)).$1, closeTo(209.88, 0.1));
    expect(rgbToHsv(const Rgb(255, 0, 255)).$1, closeTo(300, 1e-9));
    expect(rgbToHsv(Rgb.black), (0.0, 0.0, 0.0));
    expect(rgbToHsv(const Rgb(128, 128, 128)).$2, 0.0);
  });

  testWidgets('quick colors, SV square and hue bar emit changes', (
    tester,
  ) async {
    Rgb? last;
    await tester.pumpWidget(
      withPortuguese(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: ColorPicker(
              color: const Rgb(255, 0, 0),
              onChanged: (c) => last = c,
            ),
          ),
        ),
      ),
    );

    // The second quick color is orange.
    await tester.tap(find.byType(InkWell).at(1));
    await tester.pump();
    expect(last, quickColors[1]);

    last = null;
    final sv = find.byKey(const ValueKey('picker-sv'));
    final g1 = await tester.startGesture(tester.getCenter(sv));
    await g1.moveBy(const Offset(12, 8));
    await g1.up();
    await tester.pump();
    expect(last, isNotNull);

    last = null;
    final hue = find.byKey(const ValueKey('picker-hue'));
    final g2 = await tester.startGesture(tester.getCenter(hue));
    await g2.moveBy(const Offset(20, 0));
    await g2.up();
    await tester.pump();
    expect(last, isNotNull);
  });

  testWidgets('the dialog closes with Fechar', (tester) async {
    await tester.pumpWidget(
      withPortuguese(
        MaterialApp(
          theme: buildTheme(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    showColorPickerDialog(ctx, const Rgb(1, 2, 3), (_) {}),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher cor'), findsOneWidget);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher cor'), findsNothing);
  });
}
