import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/led_layout.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/presentation/led_canvas.dart';

import '../../support/app_harness.dart';

void main() {
  test('GPU area stays on the canvas even without addressable LEDs', () {
    final c = LightingConfig();
    expect(onCanvas(c, LightDeviceId.gpu), isTrue);
    final hardware = c.withDevice(
      LightDeviceId.gpu,
      c.device(LightDeviceId.gpu).copyWith(mode: LightMode.hardware),
    );
    expect(onCanvas(hardware, LightDeviceId.gpu), isFalse);
  });

  Future<void> pump(
    WidgetTester tester, {
    LightDeviceId? selected,
    required void Function(LightDeviceId?, CanvasRect) onPlace,
    ValueChanged<LightDeviceId?>? onSelect,
  }) async {
    await tester.pumpWidget(
      withPortuguese(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 640,
              child: LedCanvas(
                config: LightingConfig(),
                time: ValueNotifier<double>(0),
                selected: selected,
                onSelect: onSelect ?? (_) {},
                onPlace: (id, r) => onPlace(id, r),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('dragging the corner handle resizes the selected device', (
    tester,
  ) async {
    final placements = <LightDeviceId, CanvasRect>{};
    await pump(
      tester,
      selected: LightDeviceId.chassis,
      onPlace: (id, r) => placements[id!] = r,
    );

    const before = CanvasRect(10, 165, 300, 25);
    final canvas = find.byKey(const ValueKey('led-canvas'));
    final scale = tester.getSize(canvas).width / canvasWidth;
    final origin = tester.getTopLeft(canvas);
    final corner = origin + Offset(before.right * scale, before.bottom * scale);
    await tester.dragFrom(corner, const Offset(-30, -20));
    await tester.pump();

    final after = placements[LightDeviceId.chassis]!;
    expect(after.w, lessThan(before.w));
    expect(after.h, lessThan(before.h));
    expect(after.x, before.x); // the top-left corner stays put
    expect(after.y, before.y);
  });

  testWidgets('a resize never shrinks below the minimum size', (tester) async {
    final placements = <LightDeviceId, CanvasRect>{};
    await pump(
      tester,
      selected: LightDeviceId.chassis,
      onPlace: (id, r) => placements[id!] = r,
    );
    final canvas = find.byKey(const ValueKey('led-canvas'));
    final scale = tester.getSize(canvas).width / canvasWidth;
    final origin = tester.getTopLeft(canvas);
    const before = CanvasRect(10, 165, 300, 25);
    final corner = origin + Offset(before.right * scale, before.bottom * scale);
    await tester.dragFrom(corner, const Offset(-500, -500));
    await tester.pump();
    final after = placements[LightDeviceId.chassis]!;
    expect(after.w, greaterThanOrEqualTo(10));
    expect(after.h, greaterThanOrEqualTo(6));
  });

  testWidgets('dragging a device body moves it, clamped to the canvas', (
    tester,
  ) async {
    final placements = <LightDeviceId, CanvasRect>{};
    LightDeviceId? selected;
    await pump(
      tester,
      onPlace: (id, r) => placements[id!] = r,
      onSelect: (id) => selected = id,
    );
    final canvas = find.byKey(const ValueKey('led-canvas'));
    final scale = tester.getSize(canvas).width / canvasWidth;
    final origin = tester.getTopLeft(canvas);
    // The chassis strip sits at y 165..190; grab it and push it down.
    await tester.dragFrom(
      origin + Offset(160 * scale, 180 * scale),
      const Offset(0, 40),
    );
    await tester.pump();
    expect(selected, LightDeviceId.chassis);
    final after = placements[LightDeviceId.chassis]!;
    expect(after.y, 175); // canvasHeight - h = 200 - 25
    expect(after.w, 300);
  });

  testWidgets('tapping empty space clears the selection', (tester) async {
    LightDeviceId? selected = LightDeviceId.chassis;
    await pump(
      tester,
      selected: selected,
      onPlace: (id, r) {},
      onSelect: (id) => selected = id,
    );
    final canvas = find.byKey(const ValueKey('led-canvas'));
    final scale = tester.getSize(canvas).width / canvasWidth;
    final origin = tester.getTopLeft(canvas);
    // (2, 100) is to the left of the motherboard block and below the fans.
    await tester.tapAt(origin + Offset(2 * scale, 100 * scale));
    await tester.pump();
    expect(selected, isNull);
  });
}
