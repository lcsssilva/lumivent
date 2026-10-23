import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/preferences/application/preferences_notifier.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/core/ui/we_colors.dart';
import 'package:lumivent/features/lighting/application/lighting_notifier.dart';
import 'package:lumivent/features/lighting/application/status/light_output_state.dart';
import 'package:lumivent/features/lighting/application/messages/set_argb_off.dart';
import 'package:lumivent/features/lighting/application/messages/set_lighting_config.dart';
import 'package:lumivent/features/lighting/application/messages/identify_fan_group.dart';
import 'package:lumivent/features/lighting/application/status/light_output_status.dart';
import 'package:lumivent/features/lighting/application/messages/lighting_status.dart';
import 'package:lumivent/features/lighting/domain/canvas/led_layout.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/config/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/lighting/infrastructure/alv2_fan_hardware_modes.dart';
import 'package:lumivent/features/lighting/presentation/widgets/argb_toggle.dart';
import 'package:lumivent/features/lighting/presentation/widgets/led_canvas.dart';
import 'package:lumivent/features/lighting/presentation/views/lighting_view.dart';

import '../../fake_engine.dart';

import '../../support/app_harness.dart';
import '../../support/memory_lighting_repository.dart';
import '../../support/memory_preferences_repository.dart';

/// testWidgets that lets the debounced save timer fire before teardown.
void page(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      await body(tester);
      await tester.pump(const Duration(seconds: 1));
    });

void main() {
  late FakeEngine engine;
  late MemoryLightingRepository repo;
  late ProviderContainer container;

  setUp(() {
    engine = FakeEngine();
    repo = MemoryLightingRepository();
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(repo),
        fanHardwareModesProvider.overrideWithValue(alv2FanHardwareModes),
        preferencesRepositoryProvider.overrideWithValue(
          MemoryPreferencesRepository(),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: withPortuguese(
          MaterialApp(
            theme: buildTheme(),
            home: const Scaffold(body: LightingView()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  LightingConfig cfg() => container.read(lightingProvider);

  /// Switches [id] to hardware mode and opens its panel.
  Future<void> openHardware(WidgetTester tester, LightDeviceId id) async {
    container
        .read(lightingProvider.notifier)
        .update(
          (c) =>
              c.withDevice(id, c.device(id).copyWith(mode: LightMode.hardware)),
        );
    final item = find.byKey(ValueKey('device-${id.name}'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 100));
  }

  page('lists the devices, including the supported GPU', (tester) async {
    await pump(tester);
    for (final id in LightDeviceId.values) {
      expect(find.byKey(ValueKey('device-${id.name}')), findsOneWidget);
    }
    expect(find.text('Gabinete'), findsOneWidget);
    expect(find.text('Placa de vídeo'), findsOneWidget);
    expect(find.text('Não suportado'), findsNothing);
    expect(find.byKey(const ValueKey('device-switch-gpu')), findsOneWidget);
    expect(find.byKey(const ValueKey('device-mode-gpu')), findsOneWidget);
  });

  page('the device carousel scrolls sideways with the arrows', (tester) async {
    await pump(tester);
    IconButton arrow(String key) =>
        tester.widget<IconButton>(find.byKey(ValueKey(key)));

    // Content is wider than the window, so only "next" starts enabled.
    expect(arrow('devices-prev').onPressed, isNull);
    expect(arrow('devices-next').onPressed, isNotNull);

    final gpu = find.byKey(const ValueKey('device-gpu'));
    final before = tester.getTopLeft(gpu).dx;
    await tester.tap(find.byKey(const ValueKey('devices-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(gpu).dx, lessThan(before));
    expect(arrow('devices-prev').onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('devices-prev')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(gpu).dx, before);
    expect(arrow('devices-prev').onPressed, isNull);
  });

  page('changing a device mode sends SetLightingConfig', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('device-mode-chassis')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cor fixa').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().device(LightDeviceId.chassis).mode, LightMode.fixed);
    expect(
      engine.sent
          .whereType<SetLightingConfig>()
          .last
          .config
          .device(LightDeviceId.chassis)
          .mode,
      LightMode.fixed,
    );
    // Selecting a fixed-color device shows the color picker.
    expect(find.byKey(const ValueKey('picker-hex')), findsOneWidget);
  });

  page('choosing an effect in the library changes effectId', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('effect-spectrum')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().effectId, 'spectrum');
    // Effect controls follow the new effect.
    expect(find.byKey(const ValueKey('param-speed')), findsOneWidget);
  });

  page('scanner shows the fixed fan speed notice and disables speed', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('effect-scanner')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().effectId, 'scanner');
    expect(find.byKey(const Key('fixed-speed-notice')), findsOneWidget);
    expect(
      find.text('Velocidade fixa nas fans (modo do firmware).'),
      findsOneWidget,
    );
    final slider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(const ValueKey('param-speed')),
        matching: find.byType(Slider),
      ),
    );
    expect(slider.onChanged, isNull);

    // Rainbow wave keeps the speed control.
    await tester.tap(find.byKey(const ValueKey('effect-rainbowWave')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('fixed-speed-notice')), findsNothing);
  });

  page('global brightness and sleep switch update the config', (tester) async {
    await pump(tester);
    final slider = find.byKey(const ValueKey('global-brightness'));
    await tester.tapAt(
      tester.getTopLeft(slider) +
          Offset(tester.getSize(slider).width * .25, 20),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().brightness, closeTo(.25, .1));
    expect(cfg().brightness, lessThan(1));

    await tester.tap(find.byKey(const ValueKey('off-on-sleep')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().offOnSleep, isFalse);
  });

  page('auto hardware switch toggles the config and badges the devices', (
    tester,
  ) async {
    await pump(tester);
    expect(
      find.text('Usar os efeitos do próprio hardware quando possível'),
      findsOneWidget,
    );
    expect(cfg().autoHardware, isTrue);
    // Default effect (rainbow wave) has an equivalent: 3 fan groups + board + GPU.
    expect(find.text('Hardware (auto)'), findsNWidgets(5));

    await tester.tap(find.byKey(const ValueKey('auto-hardware')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().autoHardware, isFalse);
    expect(find.text('Hardware (auto)'), findsNothing);
  });

  page('fan hardware panel shows modes and Identificar pings', (tester) async {
    await pump(tester);
    container
        .read(lightingProvider.notifier)
        .update(
          (c) => c.withDevice(
            LightDeviceId.alv2Group2,
            c
                .device(LightDeviceId.alv2Group2)
                .copyWith(mode: LightMode.hardware),
          ),
        );
    await tester.tap(find.byKey(const ValueKey('device-alv2Group2')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ventoinha inteira'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hw-mode')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Rainbow Morph'), findsWidgets);
    await tester.tap(find.text('Rainbow').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[2].mode, 'Rainbow');

    await tester.tap(find.byKey(const ValueKey('identify')));
    await tester.pump();
    expect(engine.sent.whereType<IdentifyFanGroup>().single.group, 2);
  });

  page('merge panel shows the default mode and edits slot 0', (tester) async {
    await pump(tester);
    container.read(lightingProvider.notifier).update((c) {
      final d = c.device(LightDeviceId.alv2Group2);
      return c
          .withDevice(
            LightDeviceId.alv2Group2,
            d.copyWith(mode: LightMode.hardware),
          )
          .copyWith(alv2Merge: true);
    });
    await tester.tap(find.byKey(const ValueKey('device-alv2Group2')));
    await tester.pump(const Duration(milliseconds: 100));

    // Default `Runway` is a valid dropdown value (shown selected).
    expect(cfg().alv2MergeMode, 'Runway');
    final dd = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const ValueKey('hw-merge-mode')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(dd.value, 'Runway');
    expect(dd.items!.map((i) => i.value), contains('Runway'));
    expect(find.textContaining('todos os grupos'), findsOneWidget);

    final swatch = find.byKey(const ValueKey('merge-color-0'));
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('picker-hex')), '#112233');
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[0].colors.first, const Rgb(0x11, 0x22, 0x33));
    // The group's own slot is untouched.
    expect(
      cfg().alv2Hardware[2].colors,
      isNot(contains(const Rgb(0x11, 0x22, 0x33))),
    );
  });

  page('fan quantity stepper updates fanQuantity', (tester) async {
    await pump(tester);
    container
        .read(lightingProvider.notifier)
        .update(
          (c) => c.withDevice(
            LightDeviceId.alv2Group1,
            c
                .device(LightDeviceId.alv2Group1)
                .copyWith(mode: LightMode.hardware),
          ),
        );
    await tester.tap(find.byKey(const ValueKey('device-alv2Group1')));
    await tester.pump(const Duration(milliseconds: 100));
    final before = cfg().fanQuantity[1];
    final plus = find.byKey(const ValueKey('fan-qty-plus'));
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().fanQuantity[1], before + 1);
  });

  page('motherboard hardware panel lists the three zones', (tester) async {
    await pump(tester);
    container
        .read(lightingProvider.notifier)
        .update(
          (c) => c.withDevice(
            LightDeviceId.motherboard,
            c
                .device(LightDeviceId.motherboard)
                .copyWith(mode: LightMode.hardware),
          ),
        );
    await tester.tap(find.byKey(const ValueKey('device-motherboard')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('IO Shield 1'), findsOneWidget);
    expect(find.text('LED da CPU'), findsOneWidget);
    expect(find.text('IO Shield 2'), findsOneWidget);
  });

  page('GPU hardware panel edits the effect and its palette', (tester) async {
    await pump(tester);
    await openHardware(tester, LightDeviceId.gpu);
    expect(find.text('Hardware · Placa de vídeo'), findsOneWidget);
    expect(find.byKey(const ValueKey('gpu-mode')), findsOneWidget);
    expect(find.text('Velocidade'), findsOneWidget);
    expect(find.text('Brilho'), findsWidgets);
    expect(find.byKey(const ValueKey('gpu-color')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gpu-mode')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Troca de cores').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().gpuHardware.effect, GpuEffect.colorShift);
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(ValueKey('gpu-color-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('gpu-color')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gpu-mode')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Desligado').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().gpuHardware.effect, GpuEffect.off);
    expect(find.byKey(const ValueKey('gpu-color')), findsNothing);
  });

  page('unavailable status shows up with its reason', (tester) async {
    await pump(tester);
    engine.emit(
      const LightingStatus({
        LightDeviceId.chassis: LightOutputStatus(
          LightOutputState.unavailable,
          issue: LightOutputIssue.blocked,
          args: ['Sem permissão para acessar o dispositivo'],
        ),
        LightDeviceId.ram1: LightOutputStatus(LightOutputState.ok),
      }, fps: 30),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Indisponível'), findsOneWidget);
    final dot = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('status-chassis')),
        matching: find.byType(Container),
      ),
    );
    expect((dot.decoration as BoxDecoration).color, WeColors.danger);
    expect(
      find.byTooltip(
        'Bloqueado por segurança: Sem permissão para acessar o dispositivo',
      ),
      findsOneWidget,
    );
  });

  page('argbOff shows the notice and Ligar turns it back on', (tester) async {
    repo.config = LightingConfig(argbOff: true);
    await pump(tester);
    expect(find.text('Todos os ARGB estão desligados'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('argb-on')));
    await tester.pump();
    expect(cfg().argbOff, isFalse);
    expect(engine.sent.whereType<SetArgbOff>().single.off, isFalse);
    expect(find.text('Todos os ARGB estão desligados'), findsNothing);
  });

  page('dragging a device on the canvas moves its placement', (tester) async {
    await pump(tester);
    final before = cfg().device(LightDeviceId.chassis).placement;
    final canvas = find.byKey(const ValueKey('led-canvas'));
    final scale = tester.getSize(canvas).width / canvasWidth;
    final origin = tester.getTopLeft(canvas);
    final start =
        origin +
        Offset(
          (before.x + before.w / 2) * scale,
          (before.y + before.h / 2) * scale,
        );
    await tester.dragFrom(start, const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 100));
    final after = cfg().device(LightDeviceId.chassis).placement;
    expect(after.y, lessThan(before.y));
    expect(after.w, before.w);
  });

  test('resize clamps to min and to the canvas edge without throwing', () {
    expect(resizeExtent(20, 5, 10, 100), 25);
    expect(resizeExtent(20, -50, 10, 100), 10);
    expect(resizeExtent(20, 500, 10, 100), 100);
    // Device flush against the right edge: room is below min.
    expect(resizeExtent(20, 50, 10, 4), 4);
    expect(resizeExtent(20, -50, 10, 4), 4);
  });

  page('fan hardware scope switch converts the mode and back', (tester) async {
    await pump(tester);
    await openHardware(tester, LightDeviceId.alv2Group1);
    expect(cfg().alv2Hardware[1].mode, 'StaticColor');

    await tester.tap(find.text('Interno + externo'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[1].scope, Alv2Scope.innerOuter);
    expect(cfg().alv2Hardware[1].mode, 'StaticColor_Inner');

    await tester.tap(find.text('Ventoinha inteira'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[1].scope, Alv2Scope.whole);
    expect(cfg().alv2Hardware[1].mode, 'StaticColor');
  });

  page('fan hardware edits direction and color', (tester) async {
    await pump(tester);
    await openHardware(tester, LightDeviceId.alv2Group1);
    // Meteor has direction and colors (StaticColor has colors only).
    await tester.tap(find.byKey(const ValueKey('hw-mode')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Meteor').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[1].mode, 'Meteor');
    expect(cfg().alv2Hardware[1].directionLeft, isFalse);

    final left = find.text('Esquerda');
    await tester.ensureVisible(left);
    await tester.tap(left);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[1].directionLeft, isTrue);

    final swatch = find.byKey(const ValueKey('hw-color-0'));
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('picker-hex')), '#0A0B0C');
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Hardware[1].colors.first, const Rgb(0x0A, 0x0B, 0x0C));
  });

  page('merge order moves groups and shows the fan group names', (
    tester,
  ) async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        lightingRepositoryProvider.overrideWithValue(repo),
        fanHardwareModesProvider.overrideWithValue(alv2FanHardwareModes),
        preferencesRepositoryProvider.overrideWithValue(
          MemoryPreferencesRepository(),
        ),
        fanGroupNamesProvider.overrideWithValue(const [
          '',
          'Base',
          'Topo',
          ' ',
        ]),
      ],
    );
    await pump(tester);
    container.read(lightingProvider.notifier).update((c) {
      final d = c.device(LightDeviceId.alv2Group2);
      return c
          .withDevice(
            LightDeviceId.alv2Group2,
            d.copyWith(mode: LightMode.hardware),
          )
          .copyWith(alv2Merge: true);
    });
    await tester.pump(const Duration(milliseconds: 50));
    // Names from the fans page; a blank one falls back to "Grupo N".
    expect(find.text('Fans · Topo'), findsOneWidget);
    expect(find.text('Fans · Grupo 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('device-alv2Group2')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hardware · Fans · Topo'), findsOneWidget);

    String at(int i) =>
        tester.widget<Text>(find.byKey(ValueKey('merge-order-$i'))).data!;
    expect([at(1), at(2), at(3)], ['1. Base', '2. Topo', '3. Grupo 3']);
    final up1 = tester.widget<IconButton>(
      find.byKey(const ValueKey('merge-up-1')),
    );
    expect(up1.onPressed, isNull);

    final down2 = find.byKey(const ValueKey('merge-down-2'));
    await tester.ensureVisible(down2);
    await tester.tap(down2);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2MergeOrder, [0, 1, 3, 2]);
    expect([at(2), at(3)], ['2. Grupo 3', '3. Topo']);
  });

  page('merge switch reveals the merge mode controls', (tester) async {
    await pump(tester);
    await openHardware(tester, LightDeviceId.alv2Group2);
    expect(find.byKey(const ValueKey('hw-merge-mode')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hw-merge')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().alv2Merge, isTrue);
    expect(find.byKey(const ValueKey('hw-merge-mode')), findsOneWidget);
    expect(find.textContaining('substituído pelo modo merge'), findsOneWidget);
  });

  page('board zone controls edit mode and color', (tester) async {
    await pump(tester);
    await openHardware(tester, LightDeviceId.motherboard);
    expect(cfg().boardZones[0x20]!.mode, BoardEffectMode.static);

    await tester.tap(find.byKey(const ValueKey('board-mode-32')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Piscar duplo').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().boardZones[0x20]!.mode, BoardEffectMode.doubleFlash);

    final swatch = find.byKey(const ValueKey('board-color-32'));
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('picker-hex')), '#102030');
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().boardZones[0x20]!.color, const Rgb(0x10, 0x20, 0x30));
  });

  page('an unknown effect shows the empty effect notice', (tester) async {
    repo.config = LightingConfig(effectId: 'does-not-exist');
    await pump(tester);
    expect(
      find.text('Este efeito não tem controles disponíveis.'),
      findsOneWidget,
    );
  });

  page('an effect color parameter opens the picker and updates the value', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('effect-solid')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().effectId, 'solid');
    expect(find.byKey(const ValueKey('param-color')), findsOneWidget);

    final control = find.descendant(
      of: find.byKey(const ValueKey('param-color')),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('picker-hex')), '#123456');
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      cfg().effectValuesFor()!.color('color'),
      const Rgb(0x12, 0x34, 0x56),
    );
  });

  page('the fixed color panel edits the device color', (tester) async {
    await pump(tester);
    container
        .read(lightingProvider.notifier)
        .update(
          (c) => c.withDevice(
            LightDeviceId.chassis,
            c.device(LightDeviceId.chassis).copyWith(mode: LightMode.fixed),
          ),
        );
    await tester.tap(find.byKey(const ValueKey('device-chassis')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byKey(const ValueKey('picker-hex')), '#0F0E0D');
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      cfg().device(LightDeviceId.chassis).fixedColor,
      const Rgb(0x0F, 0x0E, 0x0D),
    );
  });

  page('the device switch enables and disables a device', (tester) async {
    await pump(tester);
    final toggle = find.byKey(const ValueKey('device-switch-chassis'));
    expect(cfg().device(LightDeviceId.chassis).enabled, isTrue);
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().device(LightDeviceId.chassis).enabled, isFalse);
  });

  page('the ARGB toggle flips the global state', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: withPortuguese(
          MaterialApp(
            theme: buildTheme(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ArgbToggle(
                  off: ref.watch(lightingProvider.select((c) => c.argbOff)),
                  onChanged: ref.read(lightingProvider.notifier).setArgbOff,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(cfg().argbOff, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cfg().argbOff, isTrue);
    expect(engine.sent.whereType<SetArgbOff>().last.off, isTrue);
    expect(find.text('ARGB desligado'), findsOneWidget);
  });
}
